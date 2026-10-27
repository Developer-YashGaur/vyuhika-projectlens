import XCTest
@testable import ProjectLens

final class ApplicationConfigurationTests: XCTestCase {
    func testApplicationIdentity() {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.bundleIdentifier, "com.vyuhika.projectlens")
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "ProjectLens")
    }

    func testPhoneOnlyAndMinimumOS() {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "UIDeviceFamily") as? [Int], [1])
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "MinimumOSVersion") as? String, "17.0")
    }
}
