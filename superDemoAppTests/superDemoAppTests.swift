//
//  superDemoAppTests.swift
//  superDemoAppTests
//
//  Created by İlker Sevim on 15.05.2026.
//

import XCTest
@testable import superDemoApp

final class superDemoAppTests: XCTestCase {
    func testItemStoresTimestamp() {
        let timestamp = Date(timeIntervalSince1970: 1_779_999_600)
        let item = Item(timestamp: timestamp)

        XCTAssertEqual(item.timestamp, timestamp)
    }

    func testPerformanceExample() {
        measure {
            _ = Item(timestamp: Date())
        }
    }
}
