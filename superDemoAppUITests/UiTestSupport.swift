//
//  UiTestSupport.swift
//  superDemoAppUITests
//

import XCTest

enum UiTestSupport {
    private static let terminateTimeout: TimeInterval = 20

    /// Ends a running app instance so the next `launch()` does not hang on XCTest terminate (common on CI).
    @MainActor
    static func terminateApplication(_ app: XCUIApplication) {
        guard app.state != .notRunning else { return }

        app.terminate()
        _ = app.wait(for: .notRunning, timeout: self.terminateTimeout)
    }

    /// Launches the app with flags that disable live network in UI-test builds.
    @MainActor
    static func launchApplication(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"] + extraArguments
        self.terminateApplication(app)
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
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

    /// Opens the Feed tab when the root shell uses `TabView`.
    @MainActor
    static func openFeedTab(in app: XCUIApplication) {
        self.openTab(
            titled: "Feed",
            accessibilityIdentifier: "feedTab",
            in: app
        )
    }

    /// Waits for Feed chrome (toolbar, states, or list). `isSelected` on tab buttons is unreliable on CI.
    @MainActor
    static func waitForFeedChrome(in app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let refresh = app.buttons["refreshFeed"]
            let refreshToolbar = app.toolbars.buttons["refreshFeed"]
            let refreshEmpty = app.buttons["refreshFeedEmpty"]
            let refreshLabel = app.buttons["Refresh Feed"]
            let retry = app.buttons["feedRetry"]
            let loading = app.progressIndicators.firstMatch
            let feedFailed = app.staticTexts["Could Not Load Feed"]
            let feedEmpty = app.staticTexts["No Posts"]
            let feedList = app.descendants(matching: .any).matching(identifier: "feedList").firstMatch
            let firstPostCell = app.cells.firstMatch

            let hasFeedUI =
                refresh.exists
                    || refreshToolbar.exists
                    || refreshEmpty.exists
                    || refreshLabel.exists
                    || retry.exists
                    || loading.exists
                    || feedFailed.exists
                    || feedEmpty.exists
                    || feedList.exists
                    || firstPostCell.exists
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
    @MainActor
    private static func tapFirstHittable(
        matching identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        let query = app.descendants(matching: .any).matching(identifier: identifier)
        guard query.firstMatch.waitForExistence(timeout: timeout) else {
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

        query.firstMatch.tap()
    }

    /// Waits for Items chrome (toolbar, empty-state action, list, or error).
    @MainActor
    static func waitForItemsChrome(in app: XCUIApplication, timeout: TimeInterval = 25) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let addItem = app.descendants(matching: .any).matching(identifier: "addItem").firstMatch
            let addItemEmpty = app.descendants(matching: .any).matching(identifier: "addItemEmpty").firstMatch
            if addItem.exists || addItemEmpty.exists {
                return true
            }

            let hasItemsUI =
                app.staticTexts["No Items"].exists
                    || app.staticTexts["Could Not Load Items"].exists
                    || app.cells.firstMatch.exists
            if hasItemsUI {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
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
        timeout: TimeInterval = 20,
        maxSwipes: Int = 12
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var remainingSwipes = maxSwipes

        while Date() < deadline, !element.exists, remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }
}
