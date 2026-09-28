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
    /// Bumps on each refresh so superseded work cannot restore the wrong UI
    /// (failed → retry × N → cancel must keep `.failed`, not stuck `.loading`).
    private var refreshGeneration = 0

    var isInitialLoading: Bool {
        if case .loading = self.state {
            return true
        }
        return false
    }

    init(
        loadSnapshot: LoadProductionReadinessSnapshotUseCase,
        scoreSnapshot: ScoreProductionReadinessUseCase
    ) {
        self.loadSnapshot = loadSnapshot
        self.scoreSnapshot = scoreSnapshot
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
        if case .loading = self.state {
            // Keep last stable `stateBeforeRefresh` across overlapping retries.
        } else {
            self.stateBeforeRefresh = self.state
        }
        self.showLoadingStateIfNeeded()
        return self.refreshGeneration
    }

    private func performRefresh(generation: Int) async {
        await Task.yield()
        do {
            let snapshot = try await self.loadSnapshot()
            guard generation == self.refreshGeneration else { return }
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.state = .content(snapshot, score: self.scoreSnapshot(snapshot: snapshot))
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
