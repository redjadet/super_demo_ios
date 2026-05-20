//
//  superDemoAppUITests.swift
//  superDemoAppUITests
//
//  Created by İlker Sevim on 15.05.2026.
//

import XCTest

final class superDemoAppUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    override func tearDown() {
        UiTestSupport.terminateApplication(XCUIApplication())
        super.tearDown()
    }

    @MainActor
    func testLaunchShowsAddItemControl() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testDashboardShowsProductionRisks() {
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
        let app = UiTestSupport.launchApplication()

        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 10))
        dashboard.tap()
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionReadinessDashboard", in: app)

        let showcaseLink = app.buttons["uikitShowcaseLink"]
        UiTestSupport.scrollToElement(showcaseLink, in: app)
        XCTAssertTrue(showcaseLink.waitForExistence(timeout: 20))
        showcaseLink.tap()
        XCTAssertTrue(app.collectionViews["uikitShowcaseCollection"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testFeedTabIsReachable() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("-UITesting")
            app.launch()
        }
    }
}
