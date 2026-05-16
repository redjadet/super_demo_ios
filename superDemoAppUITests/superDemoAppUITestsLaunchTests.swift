//
//  superDemoAppUITestsLaunchTests.swift
//  superDemoAppUITests
//
//  Created by İlker Sevim on 15.05.2026.
//

import XCTest

final class superDemoAppUITestsLaunchTests: XCTestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch() {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launch()

        let itemsTab = app.tabBars.buttons["Items"]
        if itemsTab.waitForExistence(timeout: 5) {
            itemsTab.tap()
        }

        let addItem = app.toolbars.buttons["addItem"]
        let addByLabel = app.toolbars.buttons["Add Item"]
        let addItemFallback = app.buttons["addItem"]
        XCTAssertTrue(
            addItem.waitForExistence(timeout: 10)
                || addByLabel.waitForExistence(timeout: 3)
                || addItemFallback.waitForExistence(timeout: 3)
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
