//
//  superDemoAppTests.swift
//  superDemoAppTests
//

import SwiftData
import XCTest
@testable import superDemoApp

final class superDemoAppTests: XCTestCase {
    func testItemMapsToEntity() {
        let timestamp = Date(timeIntervalSince1970: 1_779_999_600)
        let item = Item(timestamp: timestamp)

        XCTAssertEqual(item.toEntity(), ItemEntity(id: item.id, timestamp: timestamp))
    }

    @MainActor
    func testSwiftDataRepositoryAddsAndFetchesItem() throws {
        let container = try ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let repository = SwiftDataItemRepository(context: context)
        let timestamp = Date(timeIntervalSince1970: 1_780_000_000)

        let created = try repository.addItem(timestamp: timestamp)
        let items = try repository.fetchItems()

        XCTAssertEqual(items, [created])
        XCTAssertEqual(created.timestamp, timestamp)
    }
}
