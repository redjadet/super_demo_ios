//
//  superDemoAppUITestsLaunchTests.swift
//  superDemoAppUITests
//
//  Created by İlker Sevim on 15.05.2026.
//

import XCTest

final class superDemoAppUITestsLaunchTests: XCTestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    @MainActor
    func testLaunch() {
        continueAfterFailure = false

        let app = UiTestSupport.launchApplication()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 30))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
