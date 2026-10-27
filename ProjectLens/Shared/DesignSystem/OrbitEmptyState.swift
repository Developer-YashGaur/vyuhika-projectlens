import SwiftUI

/// A shared editorial layout, with honest context instead of invented balances.
struct OrbitEmptyState: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let message: String
    let detail: String
    let identifier: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NeonOrbit.Spacing.large) {
                Text(eyebrow)
                    .font(NeonOrbit.Typography.eyebrow)
                    .tracking(1)
                    .foregroundStyle(NeonOrbit.secondaryText)
                orbitMark
                Text(title)
                    .font(NeonOrbit.Typography.title)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(NeonOrbit.Typography.heading)
                    .foregroundStyle(NeonOrbit.secondaryText)
                VStack(alignment: .leading, spacing: NeonOrbit.Spacing.small) {
                    Label("Taking shape", systemImage: "sparkle")
                        .font(NeonOrbit.Typography.label)
                        .foregroundStyle(NeonOrbit.accent)
                    Text(detail)
                        .font(NeonOrbit.Typography.body)
                        .foregroundStyle(NeonOrbit.secondaryText)
                }
                .padding(NeonOrbit.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NeonOrbit.surface, in: RoundedRectangle(cornerRadius: NeonOrbit.Radius.surface))
                .overlay {
                    RoundedRectangle(cornerRadius: NeonOrbit.Radius.surface)
                        .strokeBorder(NeonOrbit.border, lineWidth: 1)
                }
                .shadow(color: NeonOrbit.Elevation.color, radius: NeonOrbit.Elevation.radius, y: NeonOrbit.Elevation.offset)
            }
            .padding(NeonOrbit.Spacing.large)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(NeonOrbit.primaryText)
        .background(NeonOrbit.background.ignoresSafeArea())
        .accessibilityIdentifier(identifier)
    }

    private var orbitMark: some View {
        ZStack {
            Circle()
                .stroke(NeonOrbit.accent.opacity(0.20), lineWidth: 1)
                .frame(width: 124, height: 124)
            Ellipse()
                .stroke(NeonOrbit.secondaryAccent.opacity(0.45), lineWidth: 1)
                .frame(width: 160, height: 72)
                .rotationEffect(.degrees(-25))
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(NeonOrbit.accent)
                .frame(width: 88, height: 88)
                .background {
                    Circle().fill(LinearGradient(
                        colors: [NeonOrbit.accent.opacity(0.16), NeonOrbit.secondaryAccent.opacity(0.07)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
        }
        .frame(maxWidth: .infinity, minHeight: 152)
        .accessibilityHidden(true)
    }
}
