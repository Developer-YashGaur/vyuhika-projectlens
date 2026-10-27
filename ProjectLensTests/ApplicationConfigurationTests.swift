import XCTest
import UIKit
@testable import ProjectLens

final class ApplicationConfigurationTests: XCTestCase {
    func testApplicationIdentity() {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.bundleIdentifier, "com.vyuhika.projectlens")
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Koshvya")
    }

    func testPhoneOnlyAndMinimumOS() {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "UIDeviceFamily") as? [Int], [1])
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "MinimumOSVersion") as? String, "17.0")
    }

    @MainActor
    func testSemanticTextAndActionContrastInBothAppearances() throws {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for surface in ["OrbitBackground", "OrbitSurface"] {
                let background = try asset(surface, traits: traits)
                for foreground in ["OrbitPrimaryText", "OrbitSecondaryText", "AccentColor", "OrbitCyan", "OrbitPositive"] {
                    let text = try asset(foreground, traits: traits)
                    XCTAssertGreaterThanOrEqual(
                        contrast(text, background), 4.5,
                        "\(foreground) on \(surface) in \(style) must meet ordinary text contrast"
                    )
                }
            }
            XCTAssertGreaterThanOrEqual(contrast(.white, try asset("OrbitActionFill", traits: traits)), 4.5)
        }
    }

    func testReducedMotionDisablesCustomSelectionAnimation() {
        XCTAssertNil(NeonOrbit.Motion.selection(reduceMotion: true))
        XCTAssertNotNil(NeonOrbit.Motion.selection(reduceMotion: false))
    }

    @MainActor
    private func asset(_ name: String, traits: UITraitCollection) throws -> UIColor {
        try XCTUnwrap(UIColor(named: name, in: .main, compatibleWith: traits))
            .resolvedColor(with: traits)
    }

    private func contrast(_ first: UIColor, _ second: UIColor) -> Double {
        func luminance(_ color: UIColor) -> Double {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            XCTAssertEqual(alpha, 1)
            let linear = [red, green, blue].map { value in
                let channel = Double(value)
                return channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
            }
            return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
        }
        let firstValue = luminance(first)
        let secondValue = luminance(second)
        return (max(firstValue, secondValue) + 0.05) / (min(firstValue, secondValue) + 0.05)
    }
}
