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

        let app = UiTestSupport.launchApplication()

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testDashboardShowsProductionRisks() {
        continueAfterFailure = false

        let app = UiTestSupport.launchApplication()

        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 10))
        dashboard.tap()
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionReadinessDashboard", in: app)

        let risksLink = app.buttons["productionRisksLink"]
        UiTestSupport.scrollToElement(risksLink, in: app)
        XCTAssertTrue(risksLink.waitForExistence(timeout: 10))
        risksLink.tap()
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionRisksScreen", in: app)
    }

    @MainActor
    func testUIKitShowcaseCollectionIsReachable() {
        continueAfterFailure = false

        let app = UiTestSupport.launchApplication()

        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 10))
        dashboard.tap()
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionReadinessDashboard", in: app)

        let showcaseLink = app.buttons["uikitShowcaseLink"]
        UiTestSupport.scrollToElement(showcaseLink, in: app)
        XCTAssertTrue(showcaseLink.waitForExistence(timeout: 10))
        showcaseLink.tap()
        XCTAssertTrue(app.collectionViews["uikitShowcaseCollection"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testFeedTabIsReachable() {
        continueAfterFailure = false

        let app = UiTestSupport.launchApplication()

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
