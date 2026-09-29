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
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testDashboardShowsProductionRisks() {
        let app = UiTestSupport.launchApplication(from: self)

        // Same dashboard scroll path as Engineering demos — `app.buttons[...]` +
        // unscrolled `scrollToElement` missed the CollectionView link on CI.
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "productionRisksLink",
            screenIdentifier: "productionRisksScreen",
            in: app
        )
    }

    @MainActor
    func testDeepLinkOpensFeedTab() {
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openDeepLink("superdemo://feed", in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))
    }

    @MainActor
    func testDeepLinkOpensItemsTab() {
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openDeepLink("superdemo://items", in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))
    }

    @MainActor
    func testDeepLinkOpensFeedPostDetail() {
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openDeepLink("superdemo://feed/1", in: app)

        // Compact split may prefer the detail column after pending post selection,
        // so sidebar-only chrome checks can miss — wait for detail (or Feed chrome
        // that includes feedPostDetail-*).
        let detail = app.descendants(matching: .any).matching(identifier: "feedPostDetail-1").firstMatch
        let opened =
            detail.waitForExistence(timeout: 30)
                || (
                    UiTestSupport.waitForFeedChrome(in: app, timeout: 10)
                        && detail.waitForExistence(timeout: 15)
                )
        XCTAssertTrue(opened, "Feed post detail did not open from superdemo://feed/1")
    }

    @MainActor
    func testUIKitShowcaseCollectionIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)

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
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))
    }

    @MainActor
    func testFeedPostRowOpensDetail() {
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))

        let postRow = app.descendants(matching: .any).matching(identifier: "feedPostRow-1").firstMatch
        XCTAssertTrue(postRow.waitForExistence(timeout: 10))
        postRow.tap()

        let detail = app.descendants(matching: .any).matching(identifier: "feedPostDetail-1").firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 10), "Feed post detail did not open from list selection")
    }

    /// Selection-driven Feed/Items smoke on the hosted iPhone destination.
    /// Hosted iPad/Mac lanes are **build-only** — see `docs/testing.md` (adaptive shell note).
    @MainActor
    func testItemRowOpensDetail() {
        let app = UiTestSupport.launchApplication(from: self, extraArguments: ["-ReviewerDemoMode"])

        UiTestSupport.openItemsTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForItemsChrome(in: app))

        let list = app.descendants(matching: .any).matching(identifier: "itemsList").firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 15), "Items list missing after reviewer seed")

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "itemRow-"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Seeded item row missing")
        row.tap()

        let detail = app.descendants(matching: .any).matching(identifier: "itemDetail").firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 10), "Item detail did not open from list selection")
    }

    @MainActor
    func testFeedAccessibilityChromeRowsAndRetry() {
        let app = UiTestSupport.launchApplication(from: self)

        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))

        let refresh = app.descendants(matching: .any).matching(identifier: "refreshFeed").firstMatch
        XCTAssertTrue(refresh.waitForExistence(timeout: 10))
        XCTAssertEqual(refresh.label, "Refresh Feed")

        let postRow = app.descendants(matching: .any).matching(identifier: "feedPostRow-1").firstMatch
        XCTAssertTrue(postRow.waitForExistence(timeout: 10))
        XCTAssertEqual(postRow.label, "UI Test Post. Stable feed content for UI tests and simulator runs.")

        app.terminate()
        let failingApp = UiTestSupport.launchApplication(from: self, extraArguments: ["-UITestingFeedFailure"])
        UiTestSupport.openFeedTab(in: failingApp)

        let failed = failingApp.descendants(matching: .any).matching(identifier: "feedFailed").firstMatch
        let loading = failingApp.descendants(matching: .any).matching(identifier: "feedLoading").firstMatch
        let retry = failingApp.buttons["feedRetry"].firstMatch

        XCTAssertTrue(failed.waitForExistence(timeout: 10), "Expected feedFailed with -UITestingFeedFailure")
        XCTAssertTrue(failingApp.staticTexts["Could Not Load Feed"].waitForExistence(timeout: 10))
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        XCTAssertEqual(retry.label, "Retry")

        retry.tap()

        // No-op tap would leave feedFailed in place forever — require a real
        // loading→failed cycle (or brief absence of failed while loading).
        let attemptDeadline = Date().addingTimeInterval(5)
        var sawRefreshAttempt = false
        while Date() < attemptDeadline {
            if loading.exists || !failed.exists {
                sawRefreshAttempt = true
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(
            sawRefreshAttempt,
            "Retry tap did not start a feed refresh (missing feedLoading / feedFailed never left)"
        )

        XCTAssertTrue(
            failed.waitForExistence(timeout: 10),
            "Expected feedFailed again after Retry with -UITestingFeedFailure"
        )
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        XCTAssertEqual(retry.label, "Retry")
    }

    @MainActor
    func testStaleFeedFixtureShowsBannerOnFeedTab() {
        let app = UiTestSupport.launchApplication(from: self, extraArguments: ["-StaleFeedDemo"])
        UiTestSupport.openFeedTab(in: app)
        XCTAssertTrue(UiTestSupport.waitForFeedChrome(in: app))

        let banner = app.descendants(matching: .any).matching(identifier: "feedStaleBanner").firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 10))

        let postRow = app.descendants(matching: .any).matching(identifier: "feedPostRow-1").firstMatch
        XCTAssertTrue(postRow.waitForExistence(timeout: 10))
    }

    @MainActor
    func testStaleFeedEngineeringDemoShowsBanner() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "staleFeedDemoLink",
            screenIdentifier: "staleFeedDemoScreen",
            in: app
        )

        let banner = app.descendants(matching: .any).matching(identifier: "feedStaleBanner").firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 15))
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
