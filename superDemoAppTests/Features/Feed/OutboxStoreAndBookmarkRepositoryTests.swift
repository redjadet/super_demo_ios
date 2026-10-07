//
//  OutboxStoreAndBookmarkRepositoryTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@Suite("Outbox store and bookmark repository")
struct OutboxStoreAndBookmarkRepositoryTests {
    @Test
    @MainActor
    func outboxPersistsAcrossRelaunch() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OutboxPersist-\(UUID().uuidString).store")
        defer {
            AppModelContainer.removePersistentStoreFiles(at: storeURL)
        }

        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container1 = try ModelContainer(for: schema, configurations: [configuration])
        let context1 = ModelContext(container1)
        let outbox1 = SwiftDataOutboxStore(context: context1)
        let payload = BookmarkOutboxPayload(postID: 42, desiredBookmarked: true)
        let inserted = try outbox1.insert(
            kind: .bookmarkSet,
            payload: payload,
            idempotencyKey: "persist-key",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        #expect(inserted.idempotencyKey == "persist-key")

        // Drop container1; reopen from disk.
        let container2 = try ModelContainer(for: schema, configurations: [configuration])
        let context2 = ModelContext(container2)
        let outbox2 = SwiftDataOutboxStore(context: context2)
        let loaded = try outbox2.snapshots(forEntityKey: payload.entityKey)
        #expect(loaded.count == 1)
        #expect(loaded.first?.idempotencyKey == "persist-key")
        #expect(loaded.first?.operationKind == .bookmarkSet)
    }

    @Test
    @MainActor
    func enqueueWhileOfflineLeavesPendingOptimisticBookmark() throws {
        let env = try Self.makeEnv()
        let bookmark = try env.repository.setBookmarked(true, postID: 7)
        #expect(bookmark.isBookmarked)
        #expect(bookmark.syncStatus == .pending)

        let pending = try env.outbox.readyPending(now: Date(timeIntervalSince1970: 9_999_999_999))
        #expect(pending.count == 1)
        #expect(pending.first?.idempotencyKey == "key-1")
    }

    @Test
    @MainActor
    func coalescingCollapsesTogglesBeforeFlush() throws {
        let env = try Self.makeEnv()
        _ = try env.repository.setBookmarked(true, postID: 9)
        _ = try env.repository.setBookmarked(false, postID: 9)
        let pending = try env.outbox.snapshots(forEntityKey: "feedPost:9")
        #expect(pending.isEmpty)
        let bookmark = try env.repository.bookmark(forPostID: 9)
        #expect(!bookmark.isBookmarked)
        #expect(bookmark.syncStatus == .synced)
    }

    @Test
    @MainActor
    func fifoOrderingPreservedForDistinctEntities() throws {
        let clockBox = ClockBox()
        clockBox.date = Date(timeIntervalSince1970: 1_900_000_000)
        let env = try Self.makeEnv { clockBox.date }
        _ = try env.repository.setBookmarked(true, postID: 1)
        clockBox.date = clockBox.date.addingTimeInterval(1)
        _ = try env.repository.setBookmarked(true, postID: 2)
        let ready = try env.outbox.readyPending(now: clockBox.date.addingTimeInterval(10))
        #expect(ready.map(\.entityKey) == ["feedPost:1", "feedPost:2"])
    }

    @MainActor
    @Test
    func completionPreservesNewerOptimisticToggle() throws {
        let env = try Self.makeEnv()
        _ = try env.repository.setBookmarked(true, postID: 9)
        let entry = try #require(env.outbox.snapshots(forEntityKey: "feedPost:9").first)
        try env.outbox.markInFlight(id: entry.id)
        _ = try env.repository.setBookmarked(false, postID: 9)

        try env.repository.markSynced(postID: 9, isBookmarked: true, remoteBookmarkID: 109)

        let bookmark = try env.repository.bookmark(forPostID: 9)
        #expect(!bookmark.isBookmarked)
        #expect(bookmark.syncStatus == .pending)
        #expect(env.repository.remoteBookmarkID(for: 9) == 109)
    }

    @Test
    @MainActor
    func newerReadyEntryCannotBypassBackingOffPredecessor() throws {
        let env = try Self.makeEnv()
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let first = try env.outbox.insert(
            kind: .bookmarkSet,
            payload: BookmarkOutboxPayload(postID: 9, desiredBookmarked: true),
            idempotencyKey: "first",
            createdAt: now
        )
        try env.outbox.markPendingForRetry(
            id: first.id,
            attemptCount: 1,
            nextAttemptAt: now.addingTimeInterval(60),
            lastError: "offline"
        )
        _ = try env.outbox.insert(
            kind: .bookmarkClear,
            payload: BookmarkOutboxPayload(postID: 9, desiredBookmarked: false),
            idempotencyKey: "second",
            createdAt: now.addingTimeInterval(1)
        )
        #expect(try env.outbox.readyPending(now: now.addingTimeInterval(2)).isEmpty)
    }

    @Test
    @MainActor
    func failedCoalescingCommitRestoresBookmarkAndOriginalQueue() throws {
        enum SaveError: Error { case rejected }
        var rejectSave = false
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let outbox = SwiftDataOutboxStore(context: context) { context in
            if rejectSave {
                throw SaveError.rejected
            }
            try context.save()
        }
        let repository = SwiftDataBookmarkRepository(context: context, outbox: outbox)
        _ = try repository.setBookmarked(true, postID: 9)
        let original = try outbox.snapshots(forEntityKey: "feedPost:9")
        rejectSave = true

        #expect(throws: SaveError.self) { try repository.setBookmarked(false, postID: 9) }

        #expect(try repository.bookmark(forPostID: 9).isBookmarked)
        #expect(try outbox.snapshots(forEntityKey: "feedPost:9").map(\.id) == original.map(\.id))
    }

    @Test
    @MainActor
    func removedSnapshotCannotBeClaimed() throws {
        let env = try Self.makeEnv()
        _ = try env.repository.setBookmarked(true, postID: 9)
        let entry = try #require(env.outbox.snapshots(forEntityKey: "feedPost:9").first)
        _ = try env.repository.setBookmarked(false, postID: 9)
        #expect(try env.outbox.claimPending(id: entry.id, now: entry.createdAt) == nil)
    }

    @Test
    @MainActor
    func explicitRetryResetsExhaustedAttemptBudget() throws {
        let env = try Self.makeEnv()
        _ = try env.repository.setBookmarked(true, postID: 9)
        let entry = try #require(env.outbox.snapshots(forEntityKey: "feedPost:9").first)
        try env.outbox.markFailed(id: entry.id, attemptCount: 5, lastError: "offline")
        try env.repository.retryFailedMutations(forPostID: 9)
        let retried = try #require(env.outbox.snapshots(forEntityKey: "feedPost:9").first)
        #expect(retried.attemptCount == 0)
        #expect(retried.idempotencyKey == entry.idempotencyKey)
    }

    @Test
    @MainActor
    func repeatedClockValuesStillPreservePerPostEnqueueOrder() throws {
        let env = try Self.makeEnv()
        _ = try env.repository.setBookmarked(true, postID: 9)
        let first = try #require(env.outbox.snapshots(forEntityKey: "feedPost:9").first)
        try env.outbox.markInFlight(id: first.id)
        _ = try env.repository.setBookmarked(false, postID: 9)
        let entries = try env.outbox.snapshots(forEntityKey: "feedPost:9")
        #expect(entries.count == 2)
        #expect(entries[0].createdAt < entries[1].createdAt)
        #expect(try env.outbox.readyPending(now: first.createdAt.addingTimeInterval(1)).isEmpty)
    }

    @MainActor
    private static func makeEnv(
        now: @escaping @Sendable () -> Date = { Date(timeIntervalSince1970: 1_900_000_000) }
    ) throws -> (
        repository: SwiftDataBookmarkRepository,
        outbox: SwiftDataOutboxStore
    ) {
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let outbox = SwiftDataOutboxStore(context: context)
        let keys = KeyFactory()
        let repository = SwiftDataBookmarkRepository(
            context: context,
            outbox: outbox,
            clock: FixedOutboxClock(now),
            makeIdempotencyKey: { keys.next() },
            onEnqueued: nil
        )
        return (repository, outbox)
    }
}

@MainActor
private final class KeyFactory: @unchecked Sendable {
    private let lock = NSLock()
    private var index = 0

    func next() -> String {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.index += 1
        return "key-\(self.index)"
    }
}

/// Mutable clock for FIFO tests. Not MainActor — `FixedOutboxClock` needs a Sendable `now`.
private final class ClockBox: @unchecked Sendable {
    var date = Date()
}
