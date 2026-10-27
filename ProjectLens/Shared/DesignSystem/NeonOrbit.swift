import SwiftUI

/// Semantic tokens for the initial dark Neon Orbit palette.
enum NeonOrbit {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.09)
    static let surface = Color(red: 0.075, green: 0.09, blue: 0.15)
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.72, green: 0.76, blue: 0.86)
    static let accent = Color(red: 0.35, green: 0.94, blue: 0.87)
    static let highlight = Color(red: 0.76, green: 0.65, blue: 1.0)
    static let cornerRadius: CGFloat = 20

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    enum Typography {
        static let title = Font.largeTitle.weight(.bold)
        static let heading = Font.title2.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption
    }
}
