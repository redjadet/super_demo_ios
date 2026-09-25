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
    private let diagnostics: ReleaseDiagnosticsReporting
    private let liveActivity: FeedRefreshLiveActivityControlling

    private(set) var state: FeedState = .loading
    private let loadController = AsyncLoadController()
    private var stateBeforeRefresh: FeedState?
    /// Bumps on each `refresh` / `refreshAndWait` so a superseded in-flight
    /// task cannot restore UI or end a newer Live Activity.
    private var refreshGeneration = 0

    init(
        refreshFeed: RefreshFeedUseCase,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared,
        liveActivity: FeedRefreshLiveActivityControlling = NoOpFeedRefreshLiveActivityController()
    ) {
        self.refreshFeed = refreshFeed
        self.diagnostics = diagnostics
        self.liveActivity = liveActivity
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

    private func beginRefresh() -> Int {
        self.refreshGeneration += 1
        self.stateBeforeRefresh = self.state
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
            self.liveActivity.refreshDidSucceed(
                postCount: result.posts.count,
                isStale: result.isStale
            )
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
