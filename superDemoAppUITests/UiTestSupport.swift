//
//  UiTestSupport.swift
//  superDemoAppUITests
//

import XCTest

enum UiTestSupport {
    private static let terminateTimeout: TimeInterval = 20
    private static let foregroundTimeout: TimeInterval = 30

    /// Ends a running app instance so the next `launch()` does not hang on XCTest terminate (common on CI).
    @MainActor
    static func terminateApplication(_ app: XCUIApplication) {
        guard app.state != .notRunning else { return }

        app.terminate()
        _ = app.wait(for: .notRunning, timeout: self.terminateTimeout)
    }

    /// Launches the app with flags that disable live network in UI-test builds.
    ///
    /// Pass `from:` so launch-progress XCTFails (`continueAfterFailure`) can
    /// terminate + retry once — needed when Simulator wedges mid-suite.
    ///
    /// Note: `XCUIApplication.launchTimeout` is unavailable on CI Xcode 27
    /// (compile error on run 36585758371). Cap relies on foreground wait +
    /// one relaunch here, and `bin/ci-iphone-test.sh` sim-reboot retry on
    /// “Timed out while requesting launch progress”.
    @MainActor
    static func launchApplication(
        from testCase: XCTestCase? = nil,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"] + extraArguments

        let previousContinue = testCase?.continueAfterFailure
        if let testCase {
            testCase.continueAfterFailure = true
        }
        defer {
            if let testCase, let previousContinue {
                testCase.continueAfterFailure = previousContinue
            }
        }

        let attempts = testCase == nil ? 1 : 2
        for attempt in 1 ... attempts {
            self.terminateApplication(app)
            app.launch()
            if app.wait(for: .runningForeground, timeout: self.foregroundTimeout) {
                return app
            }
            self.terminateApplication(app)
            if attempt < attempts {
                RunLoop.current.run(until: Date().addingTimeInterval(2))
            }
        }

        XCTFail("App did not reach runningForeground after \(attempts) launch attempt(s)")
        return app
    }

    /// Opens a custom-scheme deep link against a running app.
    @MainActor
    static func openDeepLink(_ urlString: String, in app: XCUIApplication) {
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid deep link URL: \(urlString)")
            return
        }
        app.open(url)
    }

    /// Opens the Dashboard tab across iPhone bottom tabs and iPad top/sidebar tabs.
    @MainActor
    static func openDashboardTab(in app: XCUIApplication) {
        self.openTab(
            titled: "Dashboard",
            accessibilityIdentifier: "dashboardTab",
            in: app
        )
    }

    /// Opens an Engineering demos `NavigationLink` from the Production Readiness dashboard.
    @MainActor
    static func openEngineeringDemo(
        linkIdentifier: String,
        screenIdentifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 20
    ) {
        self.openDashboardTab(in: app)
        let dashboard = self.waitForListOrCollection(
            identifier: "productionReadinessDashboard",
            in: app
        )

        // Prefer dashboard-scoped query — app-wide `.any` walks are slow/flaky on
        // long Engineering demo lists under Xcode 27 CI sims.
        let link = dashboard.descendants(matching: .any).matching(identifier: linkIdentifier).firstMatch
        // Reset to top so mid/lower links (Feed widget … watch) are reached by
        // downward scroll even when a prior demo left the list mid-way.
        self.scrollToTop(on: dashboard)
        self.scrollToElement(
            link,
            in: app,
            within: dashboard,
            timeout: max(timeout, 55),
            maxSwipes: 55
        )
        XCTAssertTrue(
            link.waitForExistence(timeout: min(timeout, 12)),
            "Missing demo link \(linkIdentifier)"
        )
        if !link.isHittable {
            self.scrollToElement(link, in: app, within: dashboard, timeout: 15, maxSwipes: 16)
        }
        XCTAssertTrue(link.isHittable, "Demo link \(linkIdentifier) exists but is not hittable")
        link.tap()

        let screen = app.descendants(matching: .any).matching(identifier: screenIdentifier).firstMatch
        XCTAssertTrue(screen.waitForExistence(timeout: timeout), "Missing demo screen \(screenIdentifier)")
    }

    /// True when any descendant matches `identifier` within `timeout`.
    ///
    /// Prefers typed queries (`staticTexts` / `buttons`) before `descendants(.any)`
    /// so Flutter / large trees do not stall each poll.
    @MainActor
    static func waitForAnyIdentifier(
        _ identifiers: [String],
        in app: XCUIApplication,
        timeout: TimeInterval = 15
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let found = identifiers.contains { identifier in
                if app.staticTexts.matching(identifier: identifier).firstMatch.exists {
                    return true
                }
                if app.buttons.matching(identifier: identifier).firstMatch.exists {
                    return true
                }
                if app.otherElements.matching(identifier: identifier).firstMatch.exists {
                    return true
                }
                return app.descendants(matching: .any).matching(identifier: identifier).firstMatch.exists
            }
            if found {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    /// True when any descendant identifier has the given prefix (e.g. `visionLine_`).
    @MainActor
    static func waitForIdentifierPrefix(
        _ prefix: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 15
    ) -> Bool {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        let match = app.descendants(matching: .any).matching(predicate).firstMatch
        return match.waitForExistence(timeout: timeout)
    }

    /// Opens the Feed tab when the root shell uses `TabView`.
    @MainActor
    static func openFeedTab(in app: XCUIApplication) {
        self.openTab(
            titled: "Feed",
            accessibilityIdentifier: "feedTab",
            in: app
        )
    }

    /// Waits for Feed chrome (toolbar, states, list, row, or post detail).
    /// Compact `NavigationSplitView` may show only the detail column after
    /// `superdemo://feed/<id>` selection — treat `feedPostDetail-*` as Feed UI.
    /// `isSelected` on tab buttons is unreliable on CI.
    /// Does **not** accept bare `app.cells.firstMatch` — Dashboard/Items also have
    /// cells, which previously false-greened Feed tab / deep-link smoke.
    @MainActor
    static func waitForFeedChrome(in app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let detailPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "feedPostDetail-")
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "feedPostRow-")
        let failedPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "feedFailed-")
        while Date() < deadline {
            let refresh = app.buttons["refreshFeed"]
            let refreshToolbar = app.toolbars.buttons["refreshFeed"]
            let refreshEmpty = app.buttons["refreshFeedEmpty"]
            let refreshLabel = app.buttons["Refresh Feed"]
            let retry = app.buttons["feedRetry"]
            let feedFailed = app.descendants(matching: .any).matching(failedPredicate).firstMatch
            let feedFailedLabel = app.staticTexts["Could Not Load Feed"]
            let feedLoading = app.descendants(matching: .any).matching(identifier: "feedLoading").firstMatch
            let feedEmpty = app.staticTexts["No Posts"]
            let feedList = app.descendants(matching: .any).matching(identifier: "feedList").firstMatch
            let feedPostRow = app.descendants(matching: .any).matching(rowPredicate).firstMatch
            let feedPostDetail = app.descendants(matching: .any).matching(detailPredicate).firstMatch
            let staleBanner = app.descendants(matching: .any).matching(identifier: "feedStaleBanner").firstMatch

            let hasFeedUI =
                refresh.exists
                    || refreshToolbar.exists
                    || refreshEmpty.exists
                    || refreshLabel.exists
                    || retry.exists
                    || feedFailed.exists
                    || feedFailedLabel.exists
                    || feedLoading.exists
                    || feedEmpty.exists
                    || feedList.exists
                    || feedPostRow.exists
                    || feedPostDetail.exists
                    || staleBanner.exists
            if hasFeedUI {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    /// Opens the Items tab when the root shell uses `TabView`.
    @MainActor
    static func openItemsTab(in app: XCUIApplication) {
        self.openTab(
            titled: "Items",
            accessibilityIdentifier: "itemsTab",
            in: app
        )
    }

    /// Resolves tabs on iPhone (`tabBars`) and iPad (top bar / sidebar), avoiding ambiguous multi-match taps.
    /// Fails the test when no tab control can be tapped — never silently no-ops.
    @MainActor
    private static func openTab(
        titled title: String,
        accessibilityIdentifier: String,
        in app: XCUIApplication
    ) {
        let tabBarButton = app.tabBars.buttons[title]
        if tabBarButton.waitForExistence(timeout: 3) {
            if !tabBarButton.isSelected {
                tabBarButton.tap()
            }
            return
        }

        // iPadOS 18+ often exposes tabs outside `tabBars` (top bar / sidebar).
        let titledQuery = app.buttons.matching(NSPredicate(format: "label == %@", title))
        if titledQuery.firstMatch.waitForExistence(timeout: 3) {
            let titledCount = titledQuery.count
            for index in 0 ..< titledCount {
                let element = titledQuery.element(boundBy: index)
                if element.exists, element.isHittable {
                    element.tap()
                    return
                }
            }
        }

        self.tapFirstHittable(matching: accessibilityIdentifier, in: app, timeout: 5)
    }

    /// Taps the first hittable match for an accessibility id (iPad can expose duplicate tab nodes).
    /// Missing or non-hittable ids fail the test — silent return caused false greens on wrong tabs.
    @MainActor
    private static func tapFirstHittable(
        matching identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        let query = app.descendants(matching: .any).matching(identifier: identifier)
        guard query.firstMatch.waitForExistence(timeout: timeout) else {
            XCTFail("Tab control \(identifier) did not appear within \(timeout)s")
            return
        }

        let count = query.count
        if count > 0 {
            for index in 0 ..< count {
                let element = query.element(boundBy: index)
                if element.exists, element.isHittable {
                    element.tap()
                    return
                }
            }
        }

        let fallback = query.firstMatch
        guard fallback.exists else {
            XCTFail("Tab control \(identifier) vanished before tap")
            return
        }
        // Last resort: XCTest may still accept tap when isHittable is flaky on CI.
        fallback.tap()
    }

    /// Waits for Items chrome (toolbar, empty-state action, list, row, or error).
    /// Does **not** accept bare `app.cells.firstMatch` — other tabs also have cells.
    ///
    /// Uses short `waitForExistence` slices instead of bare `.exists` — on CI,
    /// unbounded accessibility snapshot evaluation of toolbar `addItem` has hung
    /// for minutes (`Timed out while evaluating UI query` in `testItemRowOpensDetail`).
    @MainActor
    static func waitForItemsChrome(in app: XCUIApplication, timeout: TimeInterval = 25) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "itemRow-")
        let identifiers = [
            "itemsList",
            "itemDetail",
            "itemsEmpty",
            "itemsFailed",
            "itemsLoading",
            "addItem",
            "addItemEmpty",
        ]
        while Date() < deadline {
            let slice = min(0.8, max(0.2, deadline.timeIntervalSinceNow))
            // Prefer feature-body IDs before toolbar add — fewer hanging snapshots.
            for identifier in identifiers {
                let match = app.descendants(matching: .any)
                    .matching(identifier: identifier)
                    .firstMatch
                if match.waitForExistence(timeout: slice) {
                    return true
                }
                if Date() >= deadline {
                    return false
                }
            }
            let itemRow = app.descendants(matching: .any)
                .matching(rowPredicate)
                .firstMatch
            if itemRow.waitForExistence(timeout: slice) {
                return true
            }
            let noItems = app.staticTexts["No Items"].waitForExistence(timeout: 0.2)
            let loadFailed = app.staticTexts["Could Not Load Items"].waitForExistence(timeout: 0.2)
            if noItems || loadFailed {
                return true
            }
        }
        return false
    }

    /// Waits until Items leave the first-load placeholder (or show list/empty/failed).
    @MainActor
    static func waitForItemsLoadSettled(in app: XCUIApplication, timeout: TimeInterval = 20) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "itemRow-")
        while Date() < deadline {
            let slice = min(0.8, max(0.2, deadline.timeIntervalSinceNow))
            let settledIDs = ["itemsList", "itemsEmpty", "itemsFailed", "itemDetail", "addItemEmpty"]
            for identifier in settledIDs {
                let match = app.descendants(matching: .any)
                    .matching(identifier: identifier)
                    .firstMatch
                if match.waitForExistence(timeout: slice) {
                    return true
                }
                if Date() >= deadline {
                    return false
                }
            }
            let itemRow = app.descendants(matching: .any)
                .matching(rowPredicate)
                .firstMatch
            if itemRow.waitForExistence(timeout: slice) {
                return true
            }
            // Still on skeleton — keep polling until timeout.
            let loading = app.descendants(matching: .any)
                .matching(identifier: "itemsLoading")
                .firstMatch
            _ = loading.waitForExistence(timeout: 0.2)
        }
        return false
    }

    /// SwiftUI `List` surfaces as a table on iOS; collection view on some SDKs.
    @MainActor
    @discardableResult
    static func waitForListOrCollection(
        identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) -> XCUIElement {
        let table = app.tables[identifier]
        if table.waitForExistence(timeout: timeout) {
            return table
        }
        let collection = app.collectionViews[identifier]
        XCTAssertTrue(collection.waitForExistence(timeout: timeout))
        return collection
    }

    @MainActor
    static func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        within scrollContainer: XCUIElement? = nil,
        timeout: TimeInterval = 25,
        maxSwipes: Int = 20
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var remainingSwipes = maxSwipes
        let scroller: XCUIElement
        if let scrollContainer, scrollContainer.exists {
            scroller = scrollContainer
        } else {
            scroller = app
        }

        while Date() < deadline, remainingSwipes > 0 {
            // Existence is enough to stop searching; callers handle hittability.
            if element.exists {
                if element.isHittable {
                    return
                }
                // Visible but not hittable — nudge once more then let caller decide.
                if remainingSwipes <= 2 {
                    return
                }
            }

            // Prefer a long drag on the list/collection; `swipeUp` alone often
            // no-ops on SwiftUI List under Xcode 27 / iOS 27 CI sims.
            self.dragScrollUp(on: scroller)
            if remainingSwipes % 2 == 0 {
                scroller.swipeUp(velocity: .slow)
            }
            if remainingSwipes % 5 == 0 {
                app.swipeUp()
            }
            remainingSwipes -= 1
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
    }

    /// Pull the Engineering demos list back to the top before searching mid/lower links.
    @MainActor
    private static func scrollToTop(on scroller: XCUIElement) {
        guard scroller.exists else {
            return
        }
        for _ in 0 ..< 6 {
            self.dragScrollDown(on: scroller)
        }
        scroller.swipeDown(velocity: .fast)
    }

    /// Slow vertical drag — more reliable than `swipeUp` for long Engineering demos lists.
    @MainActor
    private static func dragScrollUp(on scroller: XCUIElement) {
        guard scroller.exists else {
            return
        }
        let start = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
        start.press(forDuration: 0.08, thenDragTo: end)
    }

    @MainActor
    private static func dragScrollDown(on scroller: XCUIElement) {
        guard scroller.exists else {
            return
        }
        let start = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.22))
        let end = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
