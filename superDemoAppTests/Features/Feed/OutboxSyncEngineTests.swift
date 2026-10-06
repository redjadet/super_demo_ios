//
//  OutboxSyncEngineTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@MainActor
private final class RecordingBookmarkRemote: BookmarkRemoteClient, @unchecked Sendable {
    struct Call: Equatable, Sendable {
        let kind: String
        let postID: Int
        let idempotencyKey: String
    }

    private(set) var calls: [Call] = []
    var errorForCallIndex: [Int: Error] = [:]
    var hangUntilCancelled = false

    func setBookmark(postID: Int, idempotencyKey: String) async throws -> Int? {
        self.calls.append(Call(kind: "set", postID: postID, idempotencyKey: idempotencyKey))
        if self.hangUntilCancelled {
            try await Task.sleep(nanoseconds: 60_000_000_000)
        } else {
            await Task.yield()
        }
        if let error = self.errorForCallIndex[self.calls.count - 1] {
            throw error
        }
        return postID + 100
    }

    func clearBookmark(postID: Int, remoteBookmarkID _: Int?, idempotencyKey: String) async throws {
        self.calls.append(Call(kind: "clear", postID: postID, idempotencyKey: idempotencyKey))
        if let error = self.errorForCallIndex[self.calls.count - 1] {
            throw error
        }
        await Task.yield()
    }
}

@MainActor
private final class ClockBox: @unchecked Sendable {
    var date = Date()
}

@MainActor
private final class SyncEngineHarness {
    let repository: SwiftDataBookmarkRepository
    let outbox: SwiftDataOutboxStore
    let remote: RecordingBookmarkRemote
    let connectivity: ManualConnectivityMonitor
    let engine: OutboxSyncEngine
    private let clockBox: ClockBox

    var clockDate: Date {
        get { self.clockBox.date }
        set { self.clockBox.date = newValue }
    }

    init(maxAttempts: Int = 5) throws {
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let store = SwiftDataOutboxStore(context: context)
        let remoteClient = RecordingBookmarkRemote()
        let pathMonitor = ManualConnectivityMonitor(isConnected: true)
        let box = ClockBox()
        box.date = Date(timeIntervalSince1970: 2_000_000_000)
        let clock = FixedOutboxClock { box.date }
        let bookmarkRepo = SwiftDataBookmarkRepository(
            context: context,
            outbox: store,
            clock: clock
        ) { "stable-key" }
        let syncEngine = OutboxSyncEngine(
            outbox: OutboxStoreBox(store),
            remote: remoteClient,
            bookmarkMutator: BookmarkLocalMutatorBox(bookmarkRepo),
            connectivity: pathMonitor,
            backoff: OutboxBackoffPolicy(
                maxAttempts: maxAttempts,
                baseDelay: 1,
                maxDelay: 60,
                jitterRatio: 0
            ) { 0 },
            clock: clock
        )
        self.repository = bookmarkRepo
        self.outbox = store
        self.remote = remoteClient
        self.connectivity = pathMonitor
        self.engine = syncEngine
        self.clockBox = box
    }
}

@Suite("Outbox sync engine")
struct OutboxSyncEngineTests {
    @Test
    @MainActor
    func flushOnReconnectSendsPending() async throws {
        let harness = try SyncEngineHarness()
        harness.connectivity.setConnected(false)
        _ = try harness.repository.setBookmarked(true, postID: 11)
        #expect(harness.remote.calls.isEmpty)

        harness.connectivity.setConnected(true)
        await harness.engine.requestFlush()

        #expect(harness.remote.calls.count == 1)
        #expect(harness.remote.calls.first?.kind == "set")
        let bookmark = try harness.repository.bookmark(forPostID: 11)
        #expect(bookmark.syncStatus == .synced)
        #expect(try harness.outbox.snapshots(forEntityKey: nil).isEmpty)
    }

    @Test
    @MainActor
    func fifoOrderingAcrossEntities() async throws {
        let harness = try SyncEngineHarness()
        harness.clockDate = Date(timeIntervalSince1970: 2_000_000_000)
        _ = try harness.repository.setBookmarked(true, postID: 1)
        harness.clockDate = harness.clockDate.addingTimeInterval(1)
        _ = try harness.repository.setBookmarked(true, postID: 2)
        await harness.engine.requestFlush()
        #expect(harness.remote.calls.map(\.postID) == [1, 2])
    }

    @Test
    @MainActor
    func idempotencyKeyReusedOnRetry() async throws {
        let harness = try SyncEngineHarness()
        harness.remote.errorForCallIndex[0] = BookmarkRemoteError.transport
        _ = try harness.repository.setBookmarked(true, postID: 5)
        let key = try harness.outbox.snapshots(forEntityKey: "feedPost:5").first?.idempotencyKey
        await harness.engine.requestFlush()

        let pending = try harness.outbox.snapshots(forEntityKey: "feedPost:5")
        #expect(pending.count == 1)
        #expect(pending.first?.idempotencyKey == key)
        #expect(pending.first?.attemptCount == 1)

        harness.remote.errorForCallIndex.removeAll()
        harness.clockDate = harness.clockDate.addingTimeInterval(100)
        await harness.engine.requestFlush()
        #expect(harness.remote.calls.count == 2)
        #expect(harness.remote.calls[0].idempotencyKey == harness.remote.calls[1].idempotencyKey)
    }

    @Test
    @MainActor
    func cancellationDoesNotCountAsAttempt() async throws {
        let harness = try SyncEngineHarness()
        harness.remote.hangUntilCancelled = true
        _ = try harness.repository.setBookmarked(true, postID: 8)
        let flushTask = Task { await harness.engine.requestFlush() }
        try await Task.sleep(nanoseconds: 50_000_000)
        flushTask.cancel()
        _ = await flushTask.result

        try harness.outbox.recoverInFlightAsPending()
        let after = try harness.outbox.snapshots(forEntityKey: "feedPost:8")
        #expect(after.count == 1)
        #expect(after.first?.attemptCount == 0)
        #expect(after.first?.status == .pending)
    }

    @Test
    @MainActor
    func http4xxMarksFailedWithoutEndlessRetry() async throws {
        let harness = try SyncEngineHarness()
        harness.remote.errorForCallIndex[0] = BookmarkRemoteError.httpStatus(400)
        _ = try harness.repository.setBookmarked(true, postID: 15)
        await harness.engine.requestFlush()
        let entries = try harness.outbox.snapshots(forEntityKey: "feedPost:15")
        #expect(entries.first?.status == .failed)
        #expect(try harness.repository.bookmark(forPostID: 15).syncStatus == .failed)
    }

    @Test
    @MainActor
    func http5xxRetriesUntilMaxAttemptsThenFails() async throws {
        let harness = try SyncEngineHarness(maxAttempts: 2)
        harness.remote.errorForCallIndex[0] = BookmarkRemoteError.httpStatus(503)
        harness.remote.errorForCallIndex[1] = BookmarkRemoteError.httpStatus(503)
        _ = try harness.repository.setBookmarked(true, postID: 16)
        await harness.engine.requestFlush()
        #expect(try harness.outbox.snapshots(forEntityKey: "feedPost:16").first?.attemptCount == 1)

        harness.clockDate = harness.clockDate.addingTimeInterval(100)
        await harness.engine.requestFlush()
        let entries = try harness.outbox.snapshots(forEntityKey: "feedPost:16")
        #expect(entries.first?.status == .failed)
        #expect(entries.first?.attemptCount == 2)
    }

    @Test
    @MainActor
    func conflictAppliesServerWins() async throws {
        let harness = try SyncEngineHarness()
        harness.remote.errorForCallIndex[0] = BookmarkRemoteError.conflict
        _ = try harness.repository.setBookmarked(true, postID: 20)
        await harness.engine.requestFlush()
        let bookmark = try harness.repository.bookmark(forPostID: 20)
        #expect(!bookmark.isBookmarked)
        #expect(bookmark.syncStatus == .failed)
        #expect(try harness.outbox.snapshots(forEntityKey: "feedPost:20").first?.status == .failed)
    }

    @Test
    @MainActor
    func inFlightRecoveredAsPendingOnStart() async throws {
        let harness = try SyncEngineHarness()
        _ = try harness.repository.setBookmarked(true, postID: 30)
        let snapshots = try harness.outbox.snapshots(forEntityKey: "feedPost:30")
        let id = try #require(snapshots.first?.id)
        try harness.outbox.markInFlight(id: id)
        await harness.engine.start()
        let entries = try harness.outbox.snapshots(forEntityKey: "feedPost:30")
        #expect(entries.isEmpty)
        #expect(try harness.repository.bookmark(forPostID: 30).syncStatus == .synced)
    }
}
