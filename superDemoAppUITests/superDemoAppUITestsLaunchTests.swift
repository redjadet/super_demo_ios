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

        let addItem = app.buttons["addItem"]
        let addByLabel = app.buttons["Add Item"]
        XCTAssertTrue(
            addItem.waitForExistence(timeout: 5) || addByLabel.waitForExistence(timeout: 1)
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
