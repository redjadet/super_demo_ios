//
//  UiTestSupport.swift
//  superDemoAppUITests
//

import XCTest

enum UiTestSupport {
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
}
