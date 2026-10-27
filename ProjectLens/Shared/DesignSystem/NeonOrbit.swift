import SwiftUI

/// Semantic, appearance-adaptive tokens. Financial colors never replace text labels.
enum NeonOrbit {
    static let background = Color("OrbitBackground")
    static let surface = Color("OrbitSurface")
    static let primaryText = Color("OrbitPrimaryText")
    static let secondaryText = Color("OrbitSecondaryText")
    static let accent = Color("AccentColor")
    static let secondaryAccent = Color("OrbitCyan")
    static let positive = Color("OrbitPositive")
    static let border = Color("OrbitBorder")
    static let actionFill = Color("OrbitActionFill")
    static let onAction = Color.white

    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let section: CGFloat = 48
    }

    enum Radius {
        static let control: CGFloat = 16
        static let surface: CGFloat = 24
    }

    enum Typography {
        static let title = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let heading = Font.system(.title2, design: .rounded, weight: .semibold)
        static let body = Font.body
        static let label = Font.headline
        static let caption = Font.subheadline
        static let eyebrow = Font.system(.caption, design: .monospaced, weight: .semibold)
    }

    enum Elevation {
        static let color = Color.black.opacity(0.10)
        static let radius: CGFloat = 12
        static let offset: CGFloat = 4
    }

    enum Motion {
        static let brief: TimeInterval = 0.18
        static func selection(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: brief)
        }
    }
}

struct OrbitActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Quick Add", systemImage: "plus")
                .font(NeonOrbit.Typography.label)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: NeonOrbit.Radius.control))
        .tint(NeonOrbit.actionFill)
        .foregroundStyle(NeonOrbit.onAction)
        .accessibilityHint("Opens the entry type chooser. Saving entries is not available yet.")
        .accessibilityIdentifier("quickAdd.open")
    }
}
