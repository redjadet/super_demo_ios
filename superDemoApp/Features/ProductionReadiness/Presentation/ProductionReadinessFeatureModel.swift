//
//  ProductionReadinessFeatureModel.swift
//  superDemoApp
//

import Foundation
import Observation

enum ProductionReadinessState: Equatable {
    case loading
    case content(ProductionReadinessSnapshot, score: Int)
    case failed(ProductionReadinessDisplayError)
}

@MainActor
@Observable
final class ProductionReadinessFeatureModel {
    private let loadSnapshot: LoadProductionReadinessSnapshotUseCase
    private let scoreSnapshot: ScoreProductionReadinessUseCase

    private(set) var state: ProductionReadinessState = .loading
    private let loadController = AsyncLoadController()
    private var stateBeforeRefresh: ProductionReadinessState?

    var isInitialLoading: Bool {
        if case .loading = self.state {
            return true
        }
        return false
    }

    init(
        loadSnapshot: LoadProductionReadinessSnapshotUseCase,
        scoreSnapshot: ScoreProductionReadinessUseCase = ScoreProductionReadinessUseCase()
    ) {
        self.loadSnapshot = loadSnapshot
        self.scoreSnapshot = scoreSnapshot
    }

    func refresh() {
        self.stateBeforeRefresh = self.state
        self.showLoadingStateIfNeeded()
        self.loadController.run { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
    }

    func refreshAndWait() async {
        self.stateBeforeRefresh = self.state
        self.showLoadingStateIfNeeded()
        await self.loadController.runAndWait { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
    }

    func cancelRefresh() {
        self.loadController.cancel()
        self.restorePriorStateAfterCancelledRefresh()
    }

    private func performRefresh() async {
        await Task.yield()
        do {
            let snapshot = try await self.loadSnapshot()
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.state = .content(snapshot, score: self.scoreSnapshot(snapshot: snapshot))
            self.stateBeforeRefresh = nil
        } catch is CancellationError {
            self.restorePriorStateAfterCancelledRefresh()
        } catch {
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.state = .failed(ProductionReadinessDisplayError(error))
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
