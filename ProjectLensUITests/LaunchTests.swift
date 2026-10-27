import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testAllDestinationsAndQuickAddPreserveSelection() {
        let app = XCUIApplication()
        app.launch()
        for title in ["Home", "Money", "Projects", "Upcoming"] {
            let tab = app.tabBars.buttons[title]
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
    func testQuickAddSelectionIsOnlyAPreviewAndResetsOnReopen() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["quickAdd.open"].tap()
        for identifier in ["expense", "income", "recurringCommitment", "transfer"] {
            let entry = app.buttons["quickAdd.\(identifier)"]
            if !entry.isHittable { app.swipeUp() }
            XCTAssertTrue(entry.isHittable)
            entry.tap()
            XCTAssertEqual(entry.value as? String, "Selected")
        }
        XCTAssertTrue(app.staticTexts["quickAdd.preview"].label.contains("Nothing has been saved."))
        app.buttons["quickAdd.done"].tap()
        app.buttons["quickAdd.open"].tap()
        XCTAssertFalse(app.staticTexts["quickAdd.preview"].exists)
        XCTAssertEqual(app.buttons["quickAdd.expense"].value as? String, "Not selected")
        // Verify native interactive dismissal also leaves the presenter reusable.
        app.navigationBars["Quick Add"].swipeDown()
        XCTAssertTrue(app.buttons["quickAdd.open"].waitForExistence(timeout: 5))
        app.buttons["quickAdd.open"].tap()
        XCTAssertEqual(app.navigationBars.matching(identifier: "Quick Add").count, 1)
    }

    @MainActor
    func testQuickAddRemainsReachableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let quickAdd = app.buttons["quickAdd.open"]
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 10))
        XCTAssertTrue(quickAdd.isHittable)
        quickAdd.tap()
        XCTAssertTrue(app.buttons["quickAdd.done"].waitForExistence(timeout: 5))
        let transfer = app.buttons["quickAdd.transfer"]
        for _ in 0..<8 {
            if transfer.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(transfer.isHittable)
        transfer.tap()
        XCTAssertEqual(transfer.value as? String, "Selected")
        XCTAssertTrue(app.buttons["quickAdd.done"].isHittable)
    }
}
