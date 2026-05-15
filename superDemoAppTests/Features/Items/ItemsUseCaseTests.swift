//
//  ItemsUseCaseTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class ItemsRepositorySpy: ItemRepository {
    var storedItems: [ItemEntity] = []
    var addedTimestamps: [Date] = []
    var deletedIDSets: [[UUID]] = []

    func fetchItems() throws -> [ItemEntity] {
        self.storedItems
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        self.addedTimestamps.append(timestamp)
        let item = ItemEntity(id: UUID(), timestamp: timestamp)
        self.storedItems.append(item)
        return item
    }

    func deleteItems(ids: [UUID]) throws {
        self.deletedIDSets.append(ids)
        self.storedItems.removeAll { ids.contains($0.id) }
    }
}

@Suite("Items use cases")
struct ItemsUseCaseTests {
    @Test
    @MainActor
    func loadItemsReturnsRepositoryOrder() throws {
        let repository = ItemsRepositorySpy()
        let timestamp = Date(timeIntervalSince1970: 1_779_999_600)
        repository.storedItems = [ItemEntity(id: UUID(), timestamp: timestamp)]

        let items = try LoadItemsUseCase(repository: repository)()

        #expect(items == repository.storedItems)
    }

    @Test
    @MainActor
    func addItemPersistsThroughRepository() throws {
        let repository = ItemsRepositorySpy()
        let timestamp = Date(timeIntervalSince1970: 1_779_999_900)

        let item = try AddItemUseCase(repository: repository)(timestamp: timestamp)

        #expect(item.timestamp == timestamp)
        #expect(repository.addedTimestamps == [timestamp])
        #expect(repository.storedItems.count == 1)
    }

    @Test
    @MainActor
    func deleteItemsSendsIDsToRepository() throws {
        let repository = ItemsRepositorySpy()
        let first = ItemEntity(id: UUID(), timestamp: Date())
        let second = ItemEntity(id: UUID(), timestamp: Date())
        repository.storedItems = [first, second]

        try DeleteItemsUseCase(repository: repository)(ids: [first.id])

        #expect(repository.deletedIDSets == [[first.id]])
        #expect(repository.storedItems == [second])
    }
}
