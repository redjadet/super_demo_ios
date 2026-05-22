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

    /// Opens the Feed tab when the root shell uses `TabView`.
    @MainActor
    static func openFeedTab(in app: XCUIApplication) {
        let tabBarFeed = app.tabBars.buttons["Feed"]
        if tabBarFeed.waitForExistence(timeout: 10) {
            if !tabBarFeed.isSelected {
                tabBarFeed.tap()
            }
            return
        }

        let feedTabId = app.buttons["feedTab"]
        if feedTabId.waitForExistence(timeout: 5) {
            feedTabId.tap()
        }
    }

    /// Waits for Feed chrome (toolbar, states, or list). `isSelected` on tab buttons is unreliable on CI.
    @MainActor
    static func waitForFeedChrome(in app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let refresh = app.buttons["refreshFeed"]
            let refreshToolbar = app.toolbars.buttons["refreshFeed"]
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
        let tabBarItems = app.tabBars.buttons["Items"]
        if tabBarItems.waitForExistence(timeout: 10) {
            if !tabBarItems.isSelected {
                tabBarItems.tap()
            }
            return
        }

        let itemsTabId = app.buttons["itemsTab"]
        if itemsTabId.waitForExistence(timeout: 5) {
            itemsTabId.tap()
        }
    }

    /// Waits for Items chrome (toolbar, empty-state action, list, or error).
    @MainActor
    static func waitForItemsChrome(in app: XCUIApplication, timeout: TimeInterval = 25) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let addItem = app.descendants(matching: .any).matching(identifier: "addItem").firstMatch
            if addItem.exists {
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
