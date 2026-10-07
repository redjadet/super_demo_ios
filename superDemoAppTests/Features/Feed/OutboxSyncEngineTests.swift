//
//  OutboxSyncEngineTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

private final class RecordingBookmarkRemote: BookmarkRemoteClient, @unchecked Sendable {
    struct Call: Equatable, Sendable {
        let kind: String
        let postID: Int
        let idempotencyKey: String
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _errorForCallIndex: [Int: Error] = [:]
    private var _hangUntilCancelled = false
    private var _onSet: (@Sendable () async throws -> Void)?

    var onSet: (@Sendable () async throws -> Void)? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self._onSet
        }
        set {
            self.lock.lock()
            self._onSet = newValue
            self.lock.unlock()
        }
    }

    var calls: [Call] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._calls
    }

    var errorForCallIndex: [Int: Error] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self._errorForCallIndex
        }
        set {
            self.lock.lock()
            self._errorForCallIndex = newValue
            self.lock.unlock()
        }
    }

    var hangUntilCancelled: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self._hangUntilCancelled
        }
        set {
            self.lock.lock()
            self._hangUntilCancelled = newValue
            self.lock.unlock()
        }
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func recordSet(postID: Int, idempotencyKey: String) -> (shouldHang: Bool, error: Error?) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self._calls.append(Call(kind: "set", postID: postID, idempotencyKey: idempotencyKey))
        let callIndex = self._calls.count - 1
        return (self._hangUntilCancelled, self._errorForCallIndex[callIndex])
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func recordClear(postID: Int, idempotencyKey: String) -> Error? {
        self.lock.lock()
        defer { self.lock.unlock() }
        self._calls.append(Call(kind: "clear", postID: postID, idempotencyKey: idempotencyKey))
        let callIndex = self._calls.count - 1
        return self._errorForCallIndex[callIndex]
    }

    func setBookmark(postID: Int, idempotencyKey: String) async throws -> Int? {
        let recorded = self.recordSet(postID: postID, idempotencyKey: idempotencyKey)
        try await self.onSet?()
        if recorded.shouldHang {
            try await Task.sleep(nanoseconds: 60_000_000_000)
        } else {
            await Task.yield()
        }
        if let error = recorded.error {
            throw error
        }
        return postID + 100
    }

    func clearBookmark(postID: Int, remoteBookmarkID _: Int?, idempotencyKey: String) async throws {
        if let error = self.recordClear(postID: postID, idempotencyKey: idempotencyKey) {
            throw error
        }
        await Task.yield()
    }
}

/// Mutable clock for sync tests. Not MainActor — `FixedOutboxClock` needs a Sendable `now`.
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
            clock: clock,
            makeIdempotencyKey: { "stable-key" },
            onEnqueued: nil
        )
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
    func singleFlushDrainsSuccessorsForSameEntity() async throws {
        let harness = try SyncEngineHarness()
        let now = harness.clockDate
        _ = try harness.outbox.insert(
            kind: .bookmarkSet,
            payload: BookmarkOutboxPayload(postID: 9, desiredBookmarked: true),
            idempotencyKey: "first",
            createdAt: now
        )
        _ = try harness.outbox.insert(
            kind: .bookmarkClear,
            payload: BookmarkOutboxPayload(postID: 9, desiredBookmarked: false),
            idempotencyKey: "second",
            createdAt: now.addingTimeInterval(1)
        )
        harness.clockDate = now.addingTimeInterval(2)

        await harness.engine.requestFlush()

        #expect(harness.remote.calls.map(\.kind) == ["set", "clear"])
        #expect(try harness.outbox.snapshots(forEntityKey: nil).isEmpty)
        #expect(try !harness.repository.bookmark(forPostID: 9).isBookmarked)
    }

    @Test
    @MainActor
    func conflictKeepsAcknowledgedStateInsteadOfGuessingServerValue() async throws {
        let harness = try SyncEngineHarness()
        harness.remote.errorForCallIndex[0] = BookmarkRemoteError.conflict
        _ = try harness.outbox.insert(
            kind: .bookmarkClear,
            payload: BookmarkOutboxPayload(postID: 9, desiredBookmarked: false),
            idempotencyKey: "clear",
            createdAt: harness.clockDate
        )

        await harness.engine.requestFlush()

        #expect(try !harness.repository.bookmark(forPostID: 9).isBookmarked)
        #expect(try harness.repository.bookmark(forPostID: 9).syncStatus == .failed)
    }

    @Test
    @MainActor
    func toggleDuringRemoteRequestDrainsLatestIntent() async throws {
        let harness = try SyncEngineHarness()
        _ = try harness.repository.setBookmarked(true, postID: 9)
        harness.remote.onSet = {
            try await MainActor.run {
                _ = try harness.repository.setBookmarked(false, postID: 9)
            }
        }

        await harness.engine.requestFlush()

        #expect(harness.remote.calls.map(\.kind) == ["set", "clear"])
        #expect(try !harness.repository.bookmark(forPostID: 9).isBookmarked)
        #expect(try harness.repository.bookmark(forPostID: 9).syncStatus == .synced)
        #expect(try harness.outbox.snapshots(forEntityKey: nil).isEmpty)
    }

    @Test
    @MainActor
    func coalescedSnapshotIsNotSentAfterEarlierRequestFinishes() async throws {
        let harness = try SyncEngineHarness()
        _ = try harness.repository.setBookmarked(true, postID: 1)
        harness.clockDate = harness.clockDate.addingTimeInterval(1)
        _ = try harness.repository.setBookmarked(true, postID: 2)
        harness.remote.onSet = {
            try await MainActor.run {
                _ = try harness.repository.setBookmarked(false, postID: 2)
            }
        }

        await harness.engine.requestFlush()

        #expect(harness.remote.calls.map(\.postID) == [1])
        #expect(try !harness.repository.bookmark(forPostID: 2).isBookmarked)
        #expect(try harness.outbox.snapshots(forEntityKey: nil).isEmpty)
    }

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
    func conflictRestoresAcknowledgedState() async throws {
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
