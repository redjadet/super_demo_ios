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

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testFeedTabIsReachable() {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launch()

        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: 10))
        feedTab.tap()
        XCTAssertTrue(feedTab.isSelected)

        let refresh = app.buttons["refreshFeed"]
        let refreshToolbar = app.toolbars.buttons["refreshFeed"]
        let refreshLabel = app.buttons["Refresh Feed"]
        let retry = app.buttons["feedRetry"]
        let loading = app.progressIndicators.firstMatch
        let feedFailed = app.staticTexts["Could Not Load Feed"]
        let feedEmpty = app.staticTexts["No Posts"]
        let firstPostCell = app.cells.firstMatch
        XCTAssertTrue(
            refresh.waitForExistence(timeout: 15)
                || refreshToolbar.waitForExistence(timeout: 5)
                || refreshLabel.waitForExistence(timeout: 5)
                || retry.waitForExistence(timeout: 5)
                || loading.waitForExistence(timeout: 5)
                || feedFailed.waitForExistence(timeout: 15)
                || feedEmpty.waitForExistence(timeout: 5)
                || firstPostCell.waitForExistence(timeout: 20)
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
