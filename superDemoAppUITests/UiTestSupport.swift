//
//  UiTestSupport.swift
//  superDemoAppUITests
//

import XCTest

enum UiTestSupport {
    /// Launches the app with flags that disable live network in UI-test builds.
    @MainActor
    static func launchApplication() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        return app
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

            let hasItemsUI = app.staticTexts["No Items"].exists
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
    static func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        var remainingSwipes = 4
        while !element.exists, remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
    }
}
