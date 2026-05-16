//
//  FeedFeatureModel.swift
//  superDemoApp
//

import Foundation
import Observation

enum FeedState: Equatable {
    case loading
    case content([FeedPost])
    case empty
    case failed(FeedDisplayError)
}

@MainActor
@Observable
final class FeedFeatureModel {
    private let refreshFeed: RefreshFeedUseCase

    private(set) var state: FeedState = .loading
    private var refreshTask: Task<Void, Never>?
    private var stateBeforeRefresh: FeedState?

    init(refreshFeed: RefreshFeedUseCase) {
        self.refreshFeed = refreshFeed
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
        await self.performRefresh()
    }

    func cancelRefresh() {
        self.refreshTask?.cancel()
        self.refreshTask = nil
        if case .loading = self.state, let previous = self.stateBeforeRefresh {
            self.state = previous
        }
        self.stateBeforeRefresh = nil
    }

    private func performRefresh() async {
        await Task.yield()
        do {
            let posts = try await self.refreshFeed()
            guard !Task.isCancelled else { return }
            self.state = posts.isEmpty ? .empty : .content(posts)
            self.stateBeforeRefresh = nil
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.state = .failed(FeedDisplayError(error))
            self.stateBeforeRefresh = nil
        }
    }

    private func showLoadingStateIfNeeded() {
        if case .content = self.state {
            return
        }
        self.state = .loading
    }
}
