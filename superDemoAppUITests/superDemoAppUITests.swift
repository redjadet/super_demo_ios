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

        // Screen id alone false-greens an empty risks list. Seeded sample risks
        // always include `push-notifications` — require that row + title/mitigation.
        let pushRow = app.descendants(matching: .any)
            .matching(identifier: "productionRiskRow-push-notifications")
            .firstMatch
        XCTAssertTrue(
            pushRow.waitForExistence(timeout: 10),
            "Missing seeded productionRiskRow-push-notifications"
        )
        let label = pushRow.label
        XCTAssertTrue(
            label.contains("Push Notifications"),
            "Push risk row title missing from accessibility label: \(label)"
        )
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("Mitigation")
                || label.localizedCaseInsensitiveContains("APNs")
                || label.localizedCaseInsensitiveContains("TestFlight"),
            "Push risk mitigation/detail missing from accessibility label: \(label)"
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
        // One soft relaunch — shard runners can leave Accessibility snapshots wedged
        // after several Engineering demos (CI: Timed out while evaluating UI query).
        for attempt in 1 ... 2 {
            let app = UiTestSupport.launchApplication(from: self, extraArguments: ["-ReviewerDemoMode"])

            UiTestSupport.openItemsTab(in: app)
            guard UiTestSupport.waitForItemsChrome(in: app, timeout: 20) else {
                app.terminate()
                if attempt == 2 {
                    XCTFail("Items chrome missing after reviewer seed")
                }
                continue
            }
            guard UiTestSupport.waitForItemsLoadSettled(in: app, timeout: 20) else {
                app.terminate()
                if attempt == 2 {
                    XCTFail("Items load did not settle after reviewer seed")
                }
                continue
            }

            let list = app.descendants(matching: .any).matching(identifier: "itemsList").firstMatch
            guard list.waitForExistence(timeout: 12) else {
                app.terminate()
                if attempt == 2 {
                    XCTFail("Items list missing after reviewer seed")
                }
                continue
            }

            let row = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "itemRow-"))
                .firstMatch
            guard row.waitForExistence(timeout: 10) else {
                app.terminate()
                if attempt == 2 {
                    XCTFail("Seeded item row missing")
                }
                continue
            }
            row.tap()

            let detail = app.descendants(matching: .any).matching(identifier: "itemDetail").firstMatch
            if detail.waitForExistence(timeout: 10) {
                return
            }
            app.terminate()
            if attempt == 2 {
                XCTFail("Item detail did not open from list selection")
            }
        }
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
        XCTAssertEqual(
            postRow.label,
            "Architecture snapshot. Deterministic Feed row for reviewer mode, UI tests, and simulator walks."
        )

        app.terminate()
        let failingApp = UiTestSupport.launchApplication(from: self, extraArguments: ["-UITestingFeedFailure"])
        UiTestSupport.openFeedTab(in: failingApp)
        XCTAssertTrue(failingApp.staticTexts["Could Not Load Feed"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(["feedFailed-1"], in: failingApp, timeout: 10),
            "Initial feed failure missing attempt-1 outcome chrome"
        )

        let retry = failingApp.buttons["feedRetry"].firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        XCTAssertEqual(retry.label, "Retry")
        retry.tap()
        // Must advance completedRefreshCount — Retry-still-exists alone was a no-op pass.
        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                ["feedFailed-2", "feedLoading"],
                in: failingApp,
                timeout: 15
            ),
            "Retry tap did not start a new feed refresh cycle"
        )
        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(["feedFailed-2"], in: failingApp, timeout: 15),
            "Retry tap did not return to failed outcome for attempt 2"
        )
        XCTAssertTrue(failingApp.buttons["feedRetry"].firstMatch.waitForExistence(timeout: 10))
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
