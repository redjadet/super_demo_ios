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
    }
}
