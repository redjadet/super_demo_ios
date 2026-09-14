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

    private(set) var state: FeedState = .loading
    private var refreshTask: Task<Void, Never>?
    private var stateBeforeRefresh: FeedState?

    init(
        refreshFeed: RefreshFeedUseCase,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared
    ) {
        self.refreshFeed = refreshFeed
        self.diagnostics = diagnostics
    }

    func refresh() {
        self.refreshTask?.cancel()
        self.stateBeforeRefresh = self.state
        self.showLoadingStateIfNeeded()

        self.refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
    }

    func refreshAndWait() async {
        self.refreshTask?.cancel()
        self.stateBeforeRefresh = self.state
        self.showLoadingStateIfNeeded()

        let operation = Task { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
        self.refreshTask = operation
        await operation.value
        if self.refreshTask == operation {
            self.refreshTask = nil
        }
    }

    func cancelRefresh() {
        self.refreshTask?.cancel()
        self.refreshTask = nil
        self.restorePriorStateAfterCancelledRefresh()
    }

    private func performRefresh() async {
        await Task.yield()
        do {
            let result = try await self.refreshFeed()
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
            self.stateBeforeRefresh = nil
        } catch is CancellationError {
            self.restorePriorStateAfterCancelledRefresh()
        } catch {
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(name: "feed-refresh"),
                reason: String(describing: error)
            )
            self.state = .failed(FeedDisplayError(error))
            self.stateBeforeRefresh = nil
        }
    }

    private func restorePriorStateAfterCancelledRefresh() {
        if case .loading = self.state, let previous = self.stateBeforeRefresh {
            self.state = previous
        }
        self.stateBeforeRefresh = nil
    }

    private func showLoadingStateIfNeeded() {
        if case .content = self.state {
            return
        }
        self.state = .loading
    }
}
