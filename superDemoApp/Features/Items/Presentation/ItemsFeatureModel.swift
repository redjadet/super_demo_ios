//
//  ItemsFeatureModel.swift
//  superDemoApp
//

import Foundation
import Observation

enum ItemsState: Equatable {
    case loading
    case content([ItemEntity])
    case empty
    case failed(DisplayError)
}

@MainActor
@Observable
final class ItemsFeatureModel {
    private let loadItems: LoadItemsUseCase
    private let addItem: AddItemUseCase
    private let updateItem: UpdateItemUseCase
    private let deleteItems: DeleteItemsUseCase
    private let diagnostics: ReleaseDiagnosticsReporting

    private(set) var state: ItemsState = .loading
    private let loadController = AsyncLoadController()
    private var stateBeforeRefresh: ItemsState?
    /// Bumps on each refresh so a superseded in-flight task cannot restore
    /// UI belonging to a newer operation (failed → retry × N → cancel).
    private var refreshGeneration = 0

    init(
        loadItems: LoadItemsUseCase,
        addItem: AddItemUseCase,
        updateItem: UpdateItemUseCase,
        deleteItems: DeleteItemsUseCase,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared
    ) {
        self.loadItems = loadItems
        self.addItem = addItem
        self.updateItem = updateItem
        self.deleteItems = deleteItems
        self.diagnostics = diagnostics
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

    func addItemNow() async {
        do {
            _ = try self.addItem()
            await self.refreshAndWait()
        } catch {
            self.recordFailure(name: "items-add", error: error)
            self.state = .failed(DisplayError(error))
        }
    }

    /// Persists the item and refreshes. Returns `false` on persistence failure
    /// so the detail editor can keep dirty state.
    @discardableResult
    func updateItemNow(_ item: ItemEntity) async -> Bool {
        do {
            try self.updateItem(item)
            await self.refreshAndWait()
            return true
        } catch {
            self.recordFailure(name: "items-update", error: error)
            self.state = .failed(DisplayError(error))
            return false
        }
    }

    func deleteItems(at offsets: IndexSet, in items: [ItemEntity]) async {
        let ids = offsets.compactMap { index in
            items.indices.contains(index) ? items[index].id : nil
        }
        do {
            try self.deleteItems(ids: ids)
            await self.refreshAndWait()
        } catch {
            self.recordFailure(name: "items-delete", error: error)
            self.state = .failed(DisplayError(error))
        }
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
        return self.refreshGeneration
    }

    private func performRefresh(generation: Int) async {
        await Task.yield()
        do {
            let items = try self.loadItems()
            guard generation == self.refreshGeneration else { return }
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.state = items.isEmpty ? .empty : .content(items)
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
            self.recordFailure(name: "items-refresh", error: error)
            self.state = .failed(DisplayError(error))
            self.stateBeforeRefresh = nil
        }
    }

    private func recordFailure(name: String, error: Error) {
        self.diagnostics.releaseCheckFailed(
            ReleaseDiagnosticCheck(name: name),
            reason: ErrorDiagnostics.reason(for: error)
        )
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
