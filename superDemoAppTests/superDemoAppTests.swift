//
//  superDemoAppTests.swift
//  superDemoAppTests
//

import XCTest
@testable import superDemoApp

final class superDemoAppTests: XCTestCase {
    @MainActor
    func testItemMapsToEntity() {
        let timestamp = Date(timeIntervalSince1970: 1_779_999_600)
        let item = Item(timestamp: timestamp)

        XCTAssertEqual(item.toEntity(), ItemEntity(id: item.id, timestamp: timestamp))
    }
}
