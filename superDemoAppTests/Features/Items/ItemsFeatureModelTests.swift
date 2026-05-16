//
//  ItemsFeatureModelTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class ItemsFeatureModelRepositorySpy: ItemRepository {
    var storedItems: [ItemEntity] = []

    func fetchItems() throws -> [ItemEntity] {
        self.storedItems
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        let item = ItemEntity(id: UUID(), timestamp: timestamp)
        self.storedItems.append(item)
        return item
    }

    func deleteItems(ids: [UUID]) throws {
        self.storedItems.removeAll { ids.contains($0.id) }
    }
}

@Suite("Items feature model")
struct ItemsFeatureModelTests {
    @Test
    @MainActor
    func refreshKeepsExistingContentVisible() async {
        let repository = ItemsFeatureModelRepositorySpy()
        repository.storedItems = [ItemEntity(id: UUID(), timestamp: Date())]
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
        await model.refresh()

        repository.storedItems.append(ItemEntity(id: UUID(), timestamp: Date()))
        let refreshTask = Task { await model.refresh() }
        await Task.yield()

        if case .loading = model.state {
            Issue.record("Expected existing content to remain visible during refresh")
        }

        await refreshTask.value
    }
}
