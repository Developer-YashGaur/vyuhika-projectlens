import SwiftUI

enum AppDestination: String, CaseIterable, Identifiable {
    case home, money, projects, upcoming

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .money: "Money"
        case .projects: "Projects"
        case .upcoming: "Upcoming"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .money: "creditcard"
        case .projects: "square.stack.3d.up"
        case .upcoming: "calendar"
        }
    }
}

struct NavigationShell: View {
    @State private var selection: AppDestination = .home
    @State private var isQuickAddPresented = false

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppDestination.allCases) { destination in
                NavigationStack {
                    destinationView(destination)
                        .navigationTitle(destination.title)
                        .toolbarBackground(NeonOrbit.background, for: .navigationBar)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            OrbitActionButton {
                                guard !isQuickAddPresented else { return }
                                isQuickAddPresented = true
                            }
                            .padding(.horizontal, NeonOrbit.Spacing.large)
                            .padding(.vertical, NeonOrbit.Spacing.medium)
                            .frame(maxWidth: 600)
                            .frame(maxWidth: .infinity)
                            .background(NeonOrbit.background)
                        }
                }
                .tabItem { Label(destination.title, systemImage: destination.symbol) }
                .tag(destination)
            }
        }
        .tint(NeonOrbit.accent)
        .toolbarBackground(NeonOrbit.surface, for: .tabBar)
        .sheet(isPresented: $isQuickAddPresented) {
            QuickAddSheet()
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .home:
            HomeView()
        case .money:
            MoneyView()
        case .projects:
            OrbitEmptyState(
                symbol: "square.stack.3d.up",
                eyebrow: "PROJECTS · IDEAS IN ORBIT",
                title: "Your next idea belongs here.",
                message: "A space for the work you care about.",
                detail: "Project finances and cost allocation are planned. No projects have been created.",
                identifier: "projects.empty"
            )
        case .upcoming:
            OrbitEmptyState(
                symbol: "calendar.badge.clock",
                eyebrow: "UPCOMING · LOOK AHEAD",
                title: "Give the future some space.",
                message: "A calmer view of what comes next.",
                detail: "Recurring commitments and release planning are planned. No reminders are scheduled.",
                identifier: "upcoming.empty"
            )
        }
    }
}
