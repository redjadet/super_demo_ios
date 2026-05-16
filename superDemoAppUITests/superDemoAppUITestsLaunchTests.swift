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

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
