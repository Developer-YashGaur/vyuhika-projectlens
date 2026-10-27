import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testBrandingOnHomeAndSpringboard() {
        let app = isolatedApp()
        app.launch()
        XCTAssertTrue(app.images["home.logo"].waitForExistence(timeout: 10))
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "Koshvya Home approved logo"
        home.lifetime = .keepAlways
        add(home)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.icons["Koshvya"].firstMatch.waitForExistence(timeout: 10))
        let icon = XCTAttachment(screenshot: springboard.screenshot())
        icon.name = "Koshvya iPhone Home Screen icon"
        icon.lifetime = .keepAlways
        add(icon)
    }

    @MainActor
    func testAllDestinationsAndQuickAddPreserveSelection() {
        let app = isolatedApp()
        app.launch()
        XCTAssertTrue(app.images["home.logo"].waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.images["home.logo"].waitForExistence(timeout: 5))
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
    func testProjectCreationEditArchiveAndRelaunch() throws {
        let app = isolatedApp()
        app.launch()
        try createProject(app, name: "UI Project", budget: "1000")
        projectRow(app, name: "UI Project").tap()
        XCTAssertTrue(app.buttons["project.edit"].waitForExistence(timeout: 5))
        app.buttons["project.edit"].tap()
        let name = app.textFields["project.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(" Renamed")
        try dismissKeyboard(in: app)
        app.buttons["project.save"].tap()
        XCTAssertTrue(app.navigationBars["UI Project Renamed"].waitForExistence(timeout: 5))
        let archive = app.buttons["project.archive"]
        try scrollTo(archive, in: app, containerID: "project.detail", upwards: true)
        archive.tap()
        XCTAssertTrue(app.buttons["Restore project"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["Projects"].tap()
        let row = projectRow(app, name: "UI Project Renamed")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Archived"))
    }

    @MainActor
    func testLinkedExpenseUpdatesBudgetAndCanBeUnlinkedFromMoney() throws {
        let app = isolatedApp()
        app.launch()
        try createProject(app, name: "UI Linked Project", budget: "100")
        projectRow(app, name: "UI Linked Project").tap()
        let addExpense = app.buttons["project.addExpense"]
        try scrollTo(addExpense, in: app, containerID: "project.detail", upwards: true)
        addExpense.tap()
        let amount = app.textFields["transaction.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap(); amount.typeText("12.34")
        let category = app.textFields["transaction.category"]
        category.tap(); category.typeText("UI Linked Tools")
        try dismissKeyboard(in: app)
        app.buttons["transaction.save"].tap()
        XCTAssertTrue(app.buttons["project.edit"].waitForExistence(timeout: 5))
        let remaining = app.descendants(matching: .any).matching(identifier: "project.remaining").firstMatch
        try scrollTo(remaining, in: app, containerID: "project.detail", upwards: false)
        XCTAssertTrue(remaining.label.contains("87.66"))
        let profit = app.descendants(matching: .any).matching(identifier: "project.profit").firstMatch
        try scrollTo(profit, in: app, containerID: "project.detail", upwards: false)
        XCTAssertTrue(profit.label.contains("12.34"))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Koshvya project budget and profitability"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        app.launch()
        app.buttons["Money"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Linked Tools")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("UI Linked Project"))
        row.tap()
        let picker = app.buttons["transaction.project"]
        try scrollTo(picker, in: app, containerID: "transaction.form", upwards: true)
        picker.tap()
        app.buttons["No project"].tap()
        app.buttons["transaction.save"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertFalse(row.label.contains("Project:"))
        XCTAssertTrue(row.label.contains("12.34"))
    }

    @MainActor
    private func createProject(_ app: XCUIApplication, name: String, budget: String) throws {
        app.buttons["Projects"].tap()
        let create = app.buttons["project.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "projects.empty").firstMatch.waitForExistence(timeout: 5),
                      "Each project workflow must start with its own empty ledger")
        create.tap()
        let field = app.textFields["project.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText(name)
        let amount = app.textFields["project.budget"]
        try scrollTo(amount, in: app, containerID: "project.form", upwards: true)
        amount.tap(); amount.typeText(budget)
        XCTAssertEqual(amount.value as? String, budget)
        try dismissKeyboard(in: app)
        app.buttons["project.save"].tap()
        XCTAssertTrue(projectRow(app, name: name).waitForExistence(timeout: 5))
    }

    @MainActor
    private func projectRow(_ app: XCUIApplication, name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "project.row.", name)).firstMatch
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, containerID: String,
                          upwards: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        try dismissKeyboard(in: app, file: file, line: line)

        // Scope gestures to the presented form/detail, never an arbitrary first list
        // (which can belong to the screen behind a sheet).
        let scroll = app.descendants(matching: .any).matching(identifier: containerID).firstMatch
        let exists = scroll.waitForExistence(timeout: 5)
        if !exists { attachInteractionFailure(app, element: element, containerID: containerID) }
        _ = try XCTUnwrap(exists ? scroll : nil, "Missing scroll container \(containerID)", file: file, line: line)
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            if upwards { scroll.swipeUp() } else { scroll.swipeDown() }
        }
        let reachable = element.exists && element.isHittable
        if !reachable { attachInteractionFailure(app, element: element, containerID: containerID) }
        // XCTUnwrap retains the reachability assertion and stops the workflow on failure.
        let identifier = element.exists ? element.identifier : "requested control (absent)"
        _ = try XCTUnwrap(reachable ? element : nil,
                          "Could not reveal \(identifier) in \(containerID)", file: file, line: line)
    }

    @MainActor
    private func dismissKeyboard(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) throws {
        // Full-frame swipes and pinned save controls can intersect the keyboard.
        // End editing through the real toolbar action and wait for the state change.
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }
        let hideKeyboard = app.buttons["form.hideKeyboard"]
        let available = hideKeyboard.waitForExistence(timeout: 5)
        if !available { attachInteractionFailure(app, element: hideKeyboard, containerID: "keyboard dismissal") }
        _ = try XCTUnwrap(available ? hideKeyboard : nil, "Missing keyboard dismissal action", file: file, line: line)
        hideKeyboard.tap()
        let dismissed = keyboard.waitForNonExistence(timeout: 5)
        if !dismissed { attachInteractionFailure(app, element: keyboard, containerID: "keyboard dismissal") }
        _ = try XCTUnwrap(dismissed ? hideKeyboard : nil, "Keyboard still covers the form", file: file, line: line)
    }

    @MainActor
    private func attachInteractionFailure(_ app: XCUIApplication, element: XCUIElement, containerID: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Unreachable control in \(containerID)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let target = element.exists ? "\(element.identifier), frame \(element.frame), hittable \(element.isHittable)" : "Absent from accessibility tree"
        let hierarchy = XCTAttachment(string: "Target: \(target)\nContainer: \(containerID)\n\(app.debugDescription)")
        hierarchy.name = "Form accessibility hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
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
