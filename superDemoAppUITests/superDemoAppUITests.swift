//
//  superDemoAppUITests.swift
//  superDemoAppUITests
//
//  Created by İlker Sevim on 15.05.2026.
//

import XCTest

final class superDemoAppUITests: XCTestCase {
    @MainActor
    func testLaunchShowsAddItemControl() {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launch()

        let addItem = app.buttons["addItem"]
        let addByLabel = app.buttons["Add Item"]
        XCTAssertTrue(
            addItem.waitForExistence(timeout: 5) || addByLabel.waitForExistence(timeout: 1)
        )
    }

    @MainActor
    func testLaunchPerformance() {
        continueAfterFailure = false

        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
