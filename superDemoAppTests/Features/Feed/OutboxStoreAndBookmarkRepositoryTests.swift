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
            clock: FixedOutboxClock(now)
        ) { keys.next() }
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

@MainActor
private final class ClockBox: @unchecked Sendable {
    var date = Date()
}
