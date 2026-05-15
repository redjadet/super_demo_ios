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
    }
}
