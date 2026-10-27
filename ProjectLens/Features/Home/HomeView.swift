import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            NeonOrbit.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: NeonOrbit.Spacing.large) {
                    Image(systemName: "circle.hexagongrid")
                        .font(.largeTitle)
                        .foregroundStyle(NeonOrbit.accent)
                        .accessibilityHidden(true)
                    Text("ProjectLens")
                        .font(NeonOrbit.Typography.title)
                        .accessibilityAddTraits(.isHeader)
                    Text("A clearer view of your projects and finances.")
                        .font(NeonOrbit.Typography.body)
                        .foregroundStyle(NeonOrbit.secondaryText)
                    Text("Your workspace is taking shape. Financial tools are planned for future releases.")
                        .font(NeonOrbit.Typography.body)
                        .padding(NeonOrbit.Spacing.large)
                        .background(NeonOrbit.surface, in: RoundedRectangle(cornerRadius: NeonOrbit.cornerRadius))
                }
                .foregroundStyle(NeonOrbit.primaryText)
                .padding(NeonOrbit.Spacing.extraLarge)
                .frame(maxWidth: 560, alignment: .leading)
            }
        }
        .accessibilityIdentifier("home.placeholder")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
