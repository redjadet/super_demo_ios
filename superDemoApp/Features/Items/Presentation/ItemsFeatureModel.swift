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

    private(set) var state: ItemsState = .loading

    init(
        loadItems: LoadItemsUseCase,
        addItem: AddItemUseCase,
        deleteItems: DeleteItemsUseCase
    ) {
        self.loadItems = loadItems
        self.addItem = addItem
        self.deleteItems = deleteItems
    }

    func refresh() async {
        self.state = .loading
        await Task.yield()
        do {
            let items = try self.loadItems()
            self.state = items.isEmpty ? .empty : .content(items)
        } catch {
            self.state = .failed(DisplayError(error))
        }
    }

    func addItemNow() async {
        do {
            _ = try self.addItem()
            await self.refresh()
        } catch {
            self.state = .failed(DisplayError(error))
        }
    }

    func deleteItems(at offsets: IndexSet, in items: [ItemEntity]) async {
        let ids = offsets.compactMap { index in
            items.indices.contains(index) ? items[index].id : nil
        }
        do {
            try self.deleteItems(ids: ids)
            await self.refresh()
        } catch {
            self.state = .failed(DisplayError(error))
        }
    }
}
