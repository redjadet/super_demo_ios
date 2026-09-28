//
//  ItemEditorDraftTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftUI
import Testing
@testable import superDemoApp

@Suite("Item editor drafts")
struct ItemEditorDraftTests {
    @Test
    @MainActor
    func draftStoreIsolatesEntriesPerItemID() {
        let idA = UUID()
        let idB = UUID()
        var storage: [UUID: ItemEditorDraft] = [:]
        let binding = Binding(
            get: { storage },
            set: { storage = $0 }
        )

        let storeA = ItemDraftStoreBinding(itemID: idA, draftsByItemID: binding)
        let storeB = ItemDraftStoreBinding(itemID: idB, draftsByItemID: binding)

        storeA.save(ItemEditorDraft(title: "A draft", note: "keep A", revision: 1))
        storeB.save(ItemEditorDraft(title: "B draft", note: "keep B", revision: 2))

        #expect(storeA.load()?.title == "A draft")
        #expect(storeB.load()?.title == "B draft")

        storeA.clear()
        #expect(storeA.load() == nil)
        #expect(storeB.load()?.note == "keep B")
    }

    @Test
    @MainActor
    func updateItemNowFalseKeepsCallerResponsibleForDirtyState() async {
        let repository = FailingUpdateRepositorySpy()
        let item = ItemEntity(id: UUID(), title: "Old", note: "n", timestamp: Date())
        repository.storedItems = [item]
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            updateItem: UpdateItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
        await model.refreshAndWait()

        var updated = item
        updated.title = "New"
        #expect(await model.updateItemNow(updated) == false)
        #expect(repository.storedItems[0].title == "Old")
    }
}

@MainActor
private final class FailingUpdateRepositorySpy: ItemRepository {
    var storedItems: [ItemEntity] = []

    func fetchItems() throws -> [ItemEntity] {
        self.storedItems
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        ItemEntity(id: UUID(), title: "New note", note: "", timestamp: timestamp)
    }

    func updateItem(_: ItemEntity) throws {
        throw NSError(domain: "test", code: 1)
    }

    func deleteItems(ids _: [UUID]) throws {}
}
