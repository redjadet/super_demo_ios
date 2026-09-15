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

        UiTestSupport.openDashboardTab(in: app)
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionReadinessDashboard", in: app)

        let risksLink = app.buttons["productionRisksLink"]
        UiTestSupport.scrollToElement(risksLink, in: app)
        XCTAssertTrue(risksLink.waitForExistence(timeout: 10))
        risksLink.tap()
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionRisksScreen", in: app)
    }

    @MainActor
    func testDeepLinkOpensFeedTab() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openDeepLink("superdemo://feed", in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))
    }

    @MainActor
    func testDeepLinkOpensItemsTab() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openDeepLink("superdemo://items", in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testUIKitShowcaseCollectionIsReachable() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openDashboardTab(in: app)
        _ = UiTestSupport.waitForListOrCollection(identifier: "productionReadinessDashboard", in: app)

        let showcaseLink = app.buttons["uikitShowcaseLink"]
        UiTestSupport.scrollToElement(showcaseLink, in: app)
        XCTAssertTrue(showcaseLink.waitForExistence(timeout: 20))
        showcaseLink.tap()
        XCTAssertTrue(app.collectionViews["uikitShowcaseCollection"].waitForExistence(timeout: 10))

        let firstCell = app.collectionViews["uikitShowcaseCollection"].cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
        let detail = app.descendants(matching: .any)
            .matching(identifier: "uikitModuleDetail")
            .firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
    }

    @MainActor
    func testFeedTabIsReachable() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))
    }

    @MainActor
    func testFeedAccessibilityChromeRowsAndRetry() {
        let app = UiTestSupport.launchApplication()

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))

        let refresh = app.descendants(matching: .any).matching(identifier: "refreshFeed").firstMatch
        XCTAssertTrue(refresh.waitForExistence(timeout: 10))
        XCTAssertEqual(refresh.label, "Refresh Feed")

        let postRow = app.descendants(matching: .any).matching(identifier: "feedPostRow-1").firstMatch
        XCTAssertTrue(postRow.waitForExistence(timeout: 10))
        XCTAssertEqual(postRow.label, "UI Test Post. Stable feed content for UI tests and simulator runs.")

        app.terminate()
        let failingApp = UiTestSupport.launchApplication(extraArguments: ["-UITestingFeedFailure"])
        UiTestSupport.openFeedTab(in: failingApp)
        XCTAssertTrue(failingApp.staticTexts["Could Not Load Feed"].waitForExistence(timeout: 10))

        let retry = failingApp.buttons["feedRetry"].firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        XCTAssertEqual(retry.label, "Retry")
        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
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
