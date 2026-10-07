//
//  FeedBookmarkFeatureModelTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@MainActor
private final class BookmarkFeedRepositorySpy: FeedRepository {
    var posts: [FeedPost] = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]

    func fetchPosts() async throws -> FeedLoadResult {
        await Task.yield()
        return FeedLoadResult(posts: self.posts, isStale: false)
    }
}

@Suite("Feed bookmark feature model")
struct FeedBookmarkFeatureModelTests {
    @Test
    @MainActor
    func toggleShowsPendingThenSyncedAfterFlush() async throws {
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let outbox = SwiftDataOutboxStore(context: context)
        let connectivity = ManualConnectivityMonitor(isConnected: true)
        let repository = SwiftDataBookmarkRepository(context: context, outbox: outbox)
        let engine = OutboxSyncEngine(
            outbox: OutboxStoreBox(outbox),
            remote: ImmediateSuccessBookmarkRemoteClient(),
            bookmarkMutator: BookmarkLocalMutatorBox(repository),
            connectivity: connectivity
        )
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: BookmarkFeedRepositorySpy()),
            toggleBookmark: ToggleBookmarkUseCase(repository: repository),
            retryBookmarkSync: RetryBookmarkSyncUseCase(repository: repository),
            bookmarkRepository: repository,
            syncEngine: engine
        )

        await model.refreshAndWait()
        model.toggleBookmark(for: 1)
        #expect(model.bookmark(for: 1).isBookmarked)
        #expect(model.bookmark(for: 1).syncStatus == .pending)

        await engine.requestFlush()
        #expect(model.bookmark(for: 1).syncStatus == .synced)
    }

    @Test
    @MainActor
    func discardedFeedModelReleasesItsPersistenceStack() async throws {
        weak var releasedContainer: ModelContainer?
        do {
            let schema = Schema([CachedFeedPost.self, BookmarkedPost.self, OutboxEntry.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            releasedContainer = container
            let model = FeedComposition.makeFeatureModel(context: ModelContext(container))
            // Give composition's engine-holder setup Task time to finish before
            // dropping the model, then verify the entire context graph releases.
            await Task.yield()
            _ = model.bookmark(for: 1)
        }
        for _ in 0 ..< 100 {
            if releasedContainer == nil {
                break
            }
            try await Task.sleep(for: .milliseconds(1))
        }
        #expect(releasedContainer == nil)
    }

    @Test
    @MainActor
    func failedLocalWriteShowsErrorWithoutOptimisticUIChange() throws {
        enum SaveError: Error { case rejected }
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let outbox = SwiftDataOutboxStore(context: context) { _ in throw SaveError.rejected }
        let repository = SwiftDataBookmarkRepository(context: context, outbox: outbox)
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: BookmarkFeedRepositorySpy()),
            toggleBookmark: ToggleBookmarkUseCase(repository: repository),
            bookmarkRepository: repository
        )

        model.toggleBookmark(for: 1)

        #expect(model.bookmarkErrorMessage != nil)
        #expect(!model.bookmark(for: 1).isBookmarked)
        #expect(try outbox.snapshots(forEntityKey: nil).isEmpty)
        model.dismissBookmarkError()
        #expect(model.bookmarkErrorMessage == nil)
    }

    @Test
    @MainActor
    func failedStateSurfacesAndRetryClearsBannerCount() async throws {
        let schema = Schema([BookmarkedPost.self, OutboxEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let outbox = SwiftDataOutboxStore(context: context)
        let remote = FailingOnceBookmarkRemote()
        let connectivity = ManualConnectivityMonitor(isConnected: true)
        let repository = SwiftDataBookmarkRepository(context: context, outbox: outbox)
        let engine = OutboxSyncEngine(
            outbox: OutboxStoreBox(outbox),
            remote: remote,
            bookmarkMutator: BookmarkLocalMutatorBox(repository),
            connectivity: connectivity
        )
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: BookmarkFeedRepositorySpy()),
            toggleBookmark: ToggleBookmarkUseCase(repository: repository),
            retryBookmarkSync: RetryBookmarkSyncUseCase(repository: repository),
            bookmarkRepository: repository,
            syncEngine: engine
        )

        model.toggleBookmark(for: 1)
        // Drain coalesced flushes from toggle's fire-and-forget Task.
        await engine.requestFlush()
        #expect(model.bookmark(for: 1).syncStatus == .failed)
        #expect(model.failedOutboxCount == 1)

        remote.shouldFail = false
        model.retryFailedBookmarks()
        await engine.requestFlush()
        #expect(model.bookmark(for: 1).syncStatus == .synced)
        #expect(model.failedOutboxCount == 0)
        #expect(try outbox.snapshots(forEntityKey: "feedPost:1").isEmpty)
    }
}

private final class FailingOnceBookmarkRemote: BookmarkRemoteClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _shouldFail = true

    var shouldFail: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self._shouldFail
        }
        set {
            self.lock.lock()
            self._shouldFail = newValue
            self.lock.unlock()
        }
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func consumeShouldFail() -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._shouldFail
    }

    func setBookmark(postID: Int, idempotencyKey _: String) async throws -> Int? {
        let fail = self.consumeShouldFail()
        await Task.yield()
        if fail {
            throw BookmarkRemoteError.httpStatus(400)
        }
        return postID
    }

    func clearBookmark(postID _: Int, remoteBookmarkID _: Int?, idempotencyKey _: String) async throws {
        await Task.yield()
    }
}
