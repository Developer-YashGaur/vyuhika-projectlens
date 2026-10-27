import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testPlaceholderLaunchesAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ProjectLens"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["ProjectLens"].isHittable)
        XCTAssertTrue(app.staticTexts["Your workspace is taking shape. Financial tools are planned for future releases."].exists)
    }
}
