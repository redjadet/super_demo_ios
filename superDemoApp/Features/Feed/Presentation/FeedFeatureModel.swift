//
//  FeedFeatureModel.swift
//  superDemoApp
//

import Foundation
import Observation

enum FeedState: Equatable {
    case loading
    case content(posts: [FeedPost], isStale: Bool)
    case empty
    case failed(FeedDisplayError)
}

@MainActor
@Observable
final class FeedFeatureModel {
    private let refreshFeed: RefreshFeedUseCase
    private let toggleBookmark: ToggleBookmarkUseCase?
    private let retryBookmarkSync: RetryBookmarkSyncUseCase?
    private let bookmarkRepository: BookmarkRepository?
    private let syncEngine: (any OutboxSyncing)?
    private let diagnostics: ReleaseDiagnosticsReporting
    private let liveActivity: FeedRefreshLiveActivityControlling

    private(set) var state: FeedState = .loading
    private(set) var bookmarksByPostID: [Int: PostBookmark] = [:]
    private(set) var failedOutboxCount = 0
    /// Completed refresh cycles (success or failure). UITests use this to prove
    /// Retry drove a new attempt — not a no-op tap that leaves prior chrome.
    private(set) var completedRefreshCount = 0
    private let loadController = AsyncLoadController()
    private var stateBeforeRefresh: FeedState?
    /// Bumps on each `refresh` / `refreshAndWait` so a superseded in-flight
    /// task cannot restore UI or end a newer Live Activity.
    private var refreshGeneration = 0

    init(
        refreshFeed: RefreshFeedUseCase,
        toggleBookmark: ToggleBookmarkUseCase? = nil,
        retryBookmarkSync: RetryBookmarkSyncUseCase? = nil,
        bookmarkRepository: BookmarkRepository? = nil,
        syncEngine: (any OutboxSyncing)? = nil,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared,
        liveActivity: FeedRefreshLiveActivityControlling? = nil
    ) {
        self.refreshFeed = refreshFeed
        self.toggleBookmark = toggleBookmark
        self.retryBookmarkSync = retryBookmarkSync
        self.bookmarkRepository = bookmarkRepository
        self.syncEngine = syncEngine
        self.diagnostics = diagnostics
        // Resolve NoOp inside MainActor init — default args are nonisolated under
        // SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor.
        self.liveActivity = liveActivity ?? NoOpFeedRefreshLiveActivityController()
    }

    func startOutboxSync() {
        guard let syncEngine else { return }
        Task { await syncEngine.start() }
        self.reloadBookmarks()
    }

    func flushOutbox() {
        guard let syncEngine else { return }
        Task { await syncEngine.requestFlush() }
    }

    func refresh() {
        let generation = self.beginRefresh()
        self.loadController.run { [weak self] in
            guard let self else { return }
            await self.performRefresh(generation: generation)
        }
    }

    func refreshAndWait() async {
        let generation = self.beginRefresh()
        await self.loadController.runAndWait { [weak self] in
            guard let self else { return }
            await self.performRefresh(generation: generation)
        }
    }

    func cancelRefresh() {
        self.loadController.cancel()
        self.restorePriorStateAfterCancelledRefresh()
    }

    func bookmark(for postID: Int) -> PostBookmark {
        self.bookmarksByPostID[postID]
            ?? PostBookmark(postID: postID, isBookmarked: false, syncStatus: .synced)
    }

    func toggleBookmark(for postID: Int) {
        guard let toggleBookmark else { return }
        do {
            let updated = try toggleBookmark(postID: postID)
            self.bookmarksByPostID[postID] = updated
            self.reloadFailedCount()
            self.flushOutbox()
        } catch {
            self.diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(name: "feed-bookmark-toggle"),
                reason: ErrorDiagnostics.reason(for: error)
            )
        }
    }

    func retryFailedBookmarks(postID: Int? = nil) {
        guard let retryBookmarkSync else { return }
        do {
            try retryBookmarkSync(postID: postID)
            self.reloadBookmarks()
            self.flushOutbox()
        } catch {
            self.diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(name: "feed-bookmark-retry"),
                reason: ErrorDiagnostics.reason(for: error)
            )
        }
    }

    func reloadBookmarks() {
        guard let bookmarkRepository else { return }
        do {
            let all = try bookmarkRepository.allBookmarks()
            self.bookmarksByPostID = Dictionary(uniqueKeysWithValues: all.map { ($0.postID, $0) })
            self.reloadFailedCount()
        } catch {
            // Keep last known map.
        }
    }

    private func reloadFailedCount() {
        guard let bookmarkRepository else {
            self.failedOutboxCount = 0
            return
        }
        self.failedOutboxCount = (try? bookmarkRepository.failedMutationCount()) ?? 0
    }

    private func beginRefresh() -> Int {
        self.refreshGeneration += 1
        // Preserve last stable state across overlapping retries so cancel does
        // not restore `.loading` after failed → retry × N.
        if case .loading = self.state {
            // Keep existing `stateBeforeRefresh`.
        } else {
            self.stateBeforeRefresh = self.state
        }
        self.showLoadingStateIfNeeded()
        self.liveActivity.refreshDidStart()
        return self.refreshGeneration
    }

    private func performRefresh(generation: Int) async {
        await Task.yield()
        do {
            let result = try await self.refreshFeed()
            guard generation == self.refreshGeneration else { return }
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            if result.posts.isEmpty {
                self.state = .empty
            } else {
                self.state = .content(posts: result.posts, isStale: result.isStale)
                if result.isStale {
                    self.diagnostics.releaseCheckFailed(
                        ReleaseDiagnosticCheck(
                            name: "feed-cache-fallback",
                            metadata: ["postCount": String(result.posts.count)]
                        ),
                        reason: "Serving cached feed after remote fetch failed"
                    )
                }
            }
            self.reloadBookmarks()
            self.liveActivity.refreshDidSucceed(
                postCount: result.posts.count,
                isStale: result.isStale
            )
            self.completedRefreshCount += 1
            self.stateBeforeRefresh = nil
        } catch is CancellationError {
            guard generation == self.refreshGeneration else { return }
            self.restorePriorStateAfterCancelledRefresh()
        } catch {
            guard generation == self.refreshGeneration else { return }
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(name: "feed-refresh"),
                reason: ErrorDiagnostics.reason(for: error)
            )
            self.state = .failed(FeedDisplayError(error))
            self.liveActivity.refreshDidFail()
            self.completedRefreshCount += 1
            self.stateBeforeRefresh = nil
        }
    }

    private func restorePriorStateAfterCancelledRefresh() {
        if case .loading = self.state, let previous = self.stateBeforeRefresh {
            self.state = previous
        }
        self.stateBeforeRefresh = nil
        self.liveActivity.refreshDidCancel()
    }

    private func showLoadingStateIfNeeded() {
        if case .content = self.state {
            return
        }
        self.state = .loading
    }
}
