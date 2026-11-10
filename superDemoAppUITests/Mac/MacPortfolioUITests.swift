import XCTest

#if os(macOS)
final class MacPortfolioUITests: XCTestCase {
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
    func testKeyboardCreateSaveAndReopenItem() {
        let app = UiTestSupport.launchApplication(from: self)
        self.openItemsTab(in: app)
        self.createNewItemViaKeyboard(in: app)

        let title = app.textFields["itemDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "New Item must select its editor")
        // Prefer keyboard over click hit-testing — multi-display Macs can place the
        // detail column at AX coordinates XCTest cannot synthesize clicks for.
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Desktop keyboard note")
        app.typeKey(.tab, modifierFlags: [])
        app.typeText("Saved with Command-S")
        XCTAssertTrue(app.staticTexts["itemDetailUnsaved"].waitForExistence(timeout: 5))
        app.typeKey("s", modifierFlags: .command)
        let saved = expectation(
            for: NSPredicate(format: "isEnabled == false"),
            evaluatedWith: app.buttons["itemDetailSave"]
        )
        wait(for: [saved], timeout: 10)

        // Assert the editor itself before round-tripping via the sidebar —
        // list-row AX labels are secondary proof.
        XCTAssertEqual(title.value as? String, "Desktop keyboard note")
        let note = app.textViews["itemDetailNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertEqual(note.value as? String, "Saved with Command-S")
        XCTAssertFalse(app.buttons["itemDetailSave"].isEnabled)

        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(app.buttons["refreshFeed"].waitForExistence(timeout: 10))
        app.typeKey("2", modifierFlags: .command)
        let rowPredicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "itemRow-",
            "Desktop keyboard note"
        )
        let row = app.descendants(matching: .any).matching(rowPredicate).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Sidebar must show the saved title")
        row.click()
        XCTAssertEqual(title.value as? String, "Desktop keyboard note")
        XCTAssertEqual(note.value as? String, "Saved with Command-S")
    }

    @MainActor
    func testFileCommandsDisabledOutsideItems() {
        let app = UiTestSupport.launchApplication(from: self)
        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(app.buttons["refreshFeed"].waitForExistence(timeout: 10))
        app.menuBars.menuBarItems["File"].click()
        XCTAssertFalse(app.menuItems["New Item"].isEnabled)
        XCTAssertFalse(app.menuItems["Save Item"].isEnabled)
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testDeleteItemRequiresConfirmation() {
        let app = UiTestSupport.launchApplication(from: self)
        self.openItemsTab(in: app)
        self.createNewItemViaKeyboard(in: app)

        XCTAssertTrue(app.textFields["itemDetailTitle"].waitForExistence(timeout: 10))
        // defaultFocus lands on title; Tab moves into the Note TextEditor.
        app.typeKey(.tab, modifierFlags: [])
        app.typeText("Discard this unsaved draft only after confirmation")
        XCTAssertTrue(app.staticTexts["itemDetailUnsaved"].waitForExistence(timeout: 5))

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "itemRow-"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "New note must appear in the sidebar")
        row.rightClick()
        app.menuItems["Delete Item"].click()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].click()
        XCTAssertTrue(row.exists, "Cancel must preserve the note")
        XCTAssertTrue(app.staticTexts["itemDetailUnsaved"].exists)
        row.rightClick()
        app.menuItems["Delete Item"].click()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
        app.buttons["Delete"].click()
        XCTAssertTrue(app.staticTexts["Select an item"].waitForExistence(timeout: 10))
        XCTAssertFalse(row.exists)
        XCTAssertTrue(UiTestSupport.waitForAnyIdentifier(["itemsEmpty"], in: app))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "itemsFailed").firstMatch.exists)
    }

    @MainActor
    private func openItemsTab(in app: XCUIApplication) {
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        self.waitForNewItemCommand(in: app)
        if app.windows["main"].exists {
            app.windows["main"].click()
        }
    }

    @MainActor
    private func createNewItemViaKeyboard(in app: XCUIApplication) {
        app.typeKey("n", modifierFlags: .command)
        let title = app.textFields["itemDetailTitle"]
        if title.waitForExistence(timeout: 5) {
            return
        }
        app.menuBars.menuBarItems["File"].click()
        let newItem = app.menuItems["New Item"]
        XCTAssertTrue(newItem.waitForExistence(timeout: 5), "File → New Item must exist")
        XCTAssertTrue(newItem.isEnabled, "File → New Item must be enabled on the Items tab")
        newItem.click()
        XCTAssertTrue(title.waitForExistence(timeout: 10), "New Item must select its editor")
    }

    @MainActor
    private func waitForNewItemCommand(in app: XCUIApplication) {
        let loaded = expectation(
            for: NSPredicate(format: "isEnabled == true"),
            evaluatedWith: app.buttons["addItem"]
        )
        wait(for: [loaded], timeout: 10)
    }
}
#endif
