import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testAllDestinationsAndQuickAddPreserveSelection() {
        let app = isolatedApp()
        app.launch()
        for title in ["Home", "Money", "Projects", "Upcoming"] {
            // Native tab accessibility containers vary across iOS versions.
            let tab = app.buttons[title]
            XCTAssertTrue(tab.waitForExistence(timeout: 10))
            tab.tap()
            XCTAssertTrue(tab.isSelected)
            XCTAssertTrue(app.navigationBars[title].exists)
            app.buttons["quickAdd.open"].tap()
            XCTAssertTrue(app.navigationBars["Quick Add"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.navigationBars.matching(identifier: "Quick Add").count, 1)
            app.buttons["quickAdd.done"].tap()
            XCTAssertTrue(tab.isSelected)
            XCTAssertTrue(app.buttons["quickAdd.open"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testQuickAddFormsAndPlannedTypesResetOnReopen() {
        let app = isolatedApp()
        app.launch()
        app.buttons["quickAdd.open"].tap()
        let entries = app.scrollViews["quickAdd.entries"]
        let done = app.buttons["quickAdd.done"]
        XCTAssertTrue(entries.waitForExistence(timeout: 5))
        for kind in ["expense", "income"] {
            let entry = app.buttons["quickAdd.\(kind)"]
            reveal(entry, in: entries, above: done)
            entry.tap()
            XCTAssertTrue(app.buttons["transaction.save"].waitForExistence(timeout: 5))
            app.buttons["transaction.cancel"].tap()
            XCTAssertTrue(done.waitForExistence(timeout: 5))
        }
        for identifier in ["recurringCommitment", "transfer"] {
            let entry = app.buttons["quickAdd.\(identifier)"]
            reveal(entry, in: entries, above: done)
            entry.tap()
            XCTAssertEqual(entry.value as? String, "Selected")
        }
        XCTAssertTrue(app.staticTexts["quickAdd.preview"].label.contains("Nothing has been saved."))
        done.tap()
        app.buttons["quickAdd.open"].tap()
        XCTAssertFalse(app.staticTexts["quickAdd.preview"].exists)
        reveal(app.buttons["quickAdd.transfer"], in: app.scrollViews["quickAdd.entries"], above: done)
        XCTAssertEqual(app.buttons["quickAdd.transfer"].value as? String, "Not selected")
        app.navigationBars["Quick Add"].swipeDown()
        XCTAssertTrue(app.buttons["quickAdd.open"].waitForExistence(timeout: 5))
        app.buttons["quickAdd.open"].tap()
        XCTAssertEqual(app.navigationBars.matching(identifier: "Quick Add").count, 1)
    }

    @MainActor
    func testQuickAddRemainsReachableAtAccessibilitySize() {
        let app = isolatedApp()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let quickAdd = app.buttons["quickAdd.open"]
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 10))
        assertHittable(quickAdd)
        quickAdd.tap()
        XCTAssertTrue(app.buttons["quickAdd.done"].waitForExistence(timeout: 5))
        let transfer = app.buttons["quickAdd.transfer"]
        reveal(transfer, in: app.scrollViews["quickAdd.entries"], above: app.buttons["quickAdd.done"])
        transfer.tap()
        XCTAssertEqual(transfer.value as? String, "Selected")
        let done = app.buttons["quickAdd.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        done.tap()
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 5))
        assertHittable(quickAdd)
    }

    @MainActor
    func testExpensePersistsAcrossLaunchAndUpdatesHomeTotals() {
        let app = isolatedApp()
        app.launch()
        addTransaction(app, kind: "expense", category: "UI Test Tools", amount: "123.45")
        app.buttons["Money"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Test Tools")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Expense"))
        app.terminate()
        app.launch()
        app.buttons["Money"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons["Home"].tap()
        let total = app.staticTexts["total.INR.Expenses"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertTrue(total.label.contains("123.45"))
    }

    @MainActor
    func testIncomeAppearsInMoney() {
        let app = isolatedApp()
        app.launch()
        addTransaction(app, kind: "income", category: "UI Test Invoice", amount: "200.25")
        app.buttons["Money"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Test Invoice")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Income"))
    }

    @MainActor
    private func isolatedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--ui-test-ledger", UUID().uuidString]
        return app
    }

    @MainActor
    private func addTransaction(_ app: XCUIApplication, kind: String, category: String, amount: String) {
        app.buttons["quickAdd.open"].tap()
        let entry = app.buttons["quickAdd.\(kind)"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        reveal(entry, in: app.scrollViews["quickAdd.entries"], above: app.buttons["quickAdd.done"])
        entry.tap()
        let field = app.textFields["transaction.amount"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(amount)
        let categoryField = app.textFields["transaction.category"]
        categoryField.tap()
        categoryField.typeText(category)
        let save = app.buttons["transaction.save"]
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons["quickAdd.open"].waitForExistence(timeout: 5))
        assertHittable(app.buttons["quickAdd.open"])
    }

    @MainActor
    private func assertHittable(_ element: XCUIElement) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func reveal(_ entry: XCUIElement, in scroll: XCUIElement, above footer: XCUIElement) {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if entry.isHittable && entry.frame.maxY < footer.frame.minY { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        XCTAssertLessThan(entry.frame.maxY, footer.frame.minY)
    }

}
