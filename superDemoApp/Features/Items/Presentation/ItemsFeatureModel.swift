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
    private let deleteItems: DeleteItemsUseCase
    private let diagnostics: ReleaseDiagnosticsReporting

    private(set) var state: ItemsState = .loading
    private let loadController = AsyncLoadController()
    private var stateBeforeRefresh: ItemsState?

    init(
        loadItems: LoadItemsUseCase,
        addItem: AddItemUseCase,
        deleteItems: DeleteItemsUseCase,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared
    ) {
        self.loadItems = loadItems
        self.addItem = addItem
        self.deleteItems = deleteItems
        self.diagnostics = diagnostics
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

    func addItemNow() async {
        do {
            _ = try self.addItem()
            await self.refreshAndWait()
        } catch {
            self.recordFailure(name: "items-add", error: error)
            self.state = .failed(DisplayError(error))
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

    private func performRefresh() async {
        await Task.yield()
        do {
            let items = try self.loadItems()
            guard !Task.isCancelled else {
                self.restorePriorStateAfterCancelledRefresh()
                return
            }
            self.state = items.isEmpty ? .empty : .content(items)
            self.stateBeforeRefresh = nil
        } catch is CancellationError {
            self.restorePriorStateAfterCancelledRefresh()
        } catch {
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
            reason: String(describing: error)
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
