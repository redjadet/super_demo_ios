//
//  SwiftDataItemRepositoryTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@Suite("SwiftData item repository")
struct SwiftDataItemRepositoryTests {
    @Test
    @MainActor
    func addItemPersistsAndFetches() throws {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let repository = SwiftDataItemRepository(context: context)
        let timestamp = Date(timeIntervalSince1970: 1_780_000_000)

        let created = try repository.addItem(timestamp: timestamp)
        let items = try repository.fetchItems()

        #expect(items == [created])
        #expect(created.timestamp == timestamp)
        #expect(created.title == "New note")
        #expect(created.note.isEmpty)
    }

    @Test
    @MainActor
    func updateItemPersistsTitleAndNote() throws {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let repository = SwiftDataItemRepository(context: context)

        var item = try repository.addItem(timestamp: Date())
        item.title = "Ship checklist"
        item.note = "Verify deep links"
        try repository.updateItem(item)

        let loaded = try repository.fetchItems()
        #expect(loaded.first?.title == "Ship checklist")
        #expect(loaded.first?.note == "Verify deep links")
    }

    @Test
    @MainActor
    func failedUpdateDoesNotLeavePendingMutations() throws {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        enum SaveFailure: Error { case boom }
        let repository = SwiftDataItemRepository(context: context) { _ in
            throw SaveFailure.boom
        }

        // Seed via a real save first.
        let seed = SwiftDataItemRepository(context: context)
        var item = try seed.addItem(timestamp: Date())
        item.title = "Original"
        item.note = "Keep me"
        try seed.updateItem(item)

        var dirty = item
        dirty.title = "Should roll back"
        dirty.note = "Pending mutation"
        do {
            try repository.updateItem(dirty)
            Issue.record("Expected update to throw")
        } catch {
            // expected
        }

        let loaded = try seed.fetchItems()
        #expect(loaded.first?.title == "Original")
        #expect(loaded.first?.note == "Keep me")
        #expect(context.hasChanges == false)
    }
}
