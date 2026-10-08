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
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        self.waitForNewItemCommand(in: app)
        app.typeKey("n", modifierFlags: .command)

        let title = app.textFields["itemDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "New Item must select its editor")
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Desktop keyboard note")
        let note = app.textViews["itemDetailNote"]
        note.click()
        note.typeText("Saved with Command-S")
        XCTAssertTrue(app.staticTexts["itemDetailUnsaved"].waitForExistence(timeout: 5))
        app.typeKey("s", modifierFlags: .command)
        let saved = expectation(
            for: NSPredicate(format: "isEnabled == false"),
            evaluatedWith: app.buttons["itemDetailSave"]
        )
        wait(for: [saved], timeout: 10)

        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(app.buttons["refreshFeed"].waitForExistence(timeout: 10))
        app.typeKey("2", modifierFlags: .command)
        let row = app.descendants(matching: .tableRow)
            .matching(NSPredicate(format: "label CONTAINS %@", "Desktop keyboard note")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.click()
        XCTAssertEqual(title.value as? String, "Desktop keyboard note")
        XCTAssertEqual(note.value as? String, "Saved with Command-S")
        XCTAssertFalse(app.buttons["itemDetailSave"].isEnabled)
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
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        self.waitForNewItemCommand(in: app)
        app.typeKey("n", modifierFlags: .command)
        XCTAssertTrue(app.textFields["itemDetailTitle"].waitForExistence(timeout: 10))
        app.textViews["itemDetailNote"].click()
        app.textViews["itemDetailNote"].typeText("Discard this unsaved draft only after confirmation")
        let row = app.descendants(matching: .tableRow)
            .matching(NSPredicate(format: "label CONTAINS %@", "New note")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
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
    private func waitForNewItemCommand(in app: XCUIApplication) {
        let loaded = expectation(
            for: NSPredicate(format: "isEnabled == true"),
            evaluatedWith: app.buttons["addItem"]
        )
        wait(for: [loaded], timeout: 10)
    }
}
#endif
