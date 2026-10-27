import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @State private var creating = false

    var body: some View {
        Group {
            if ledger.isLoading {
                ProgressView("Opening your projects…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = ledger.loadError {
                LedgerLoadError(message: error)
            } else if ledger.projects.isEmpty {
                OrbitEmptyState(symbol: "square.stack.3d.up", eyebrow: "PROJECTS · YOUR WORK, IN FOCUS",
                                title: "Give your work a place.", message: "Plan a budget. Record the real costs.",
                                detail: "Use New project to begin. Link income and expenses to see recorded profit or loss alongside your expense budget.", identifier: "projects.empty")
            } else {
                List {
                    ForEach([false, true], id: \.self) { archived in
                        let projects = ledger.projects.filter { ($0.status == .archived) == archived }
                        if !projects.isEmpty {
                            Section(archived ? "Archived" : "Projects") {
                                ForEach(projects) { project in
                                    NavigationLink {
                                        ProjectDetailView(projectID: project.id)
                                    } label: {
                                        VStack(alignment: .leading, spacing: NeonOrbit.Spacing.small) {
                                            Text(project.name).font(NeonOrbit.Typography.label)
                                            Text("\(project.status.title) · \(project.currency.rawValue)")
                                                .foregroundStyle(NeonOrbit.secondaryText)
                                            if let financials = ledger.projectFinancials[project.id] {
                                                Text("Profit / loss: \(project.currency.formatted(financials.profit))")
                                                    .font(NeonOrbit.Typography.caption)
                                            }
                                        }
                                        .padding(.vertical, NeonOrbit.Spacing.small)
                                        .accessibilityElement(children: .combine)
                                    }
                                    .accessibilityIdentifier("project.row.\(project.id.uuidString)")
                                    .listRowBackground(NeonOrbit.surface)
                                }
                            }
                        }
                    }
                }
                .accessibilityIdentifier("projects.list")
                .scrollContentBackground(.hidden)
            }
        }
        .foregroundStyle(NeonOrbit.primaryText)
        .background(NeonOrbit.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { creating = true } label: { Label("New project", systemImage: "plus") }
                    .disabled(!ledger.hasLoaded || ledger.isLoading || ledger.isSaving)
                    .accessibilityIdentifier("project.create")
            }
        }
        .sheet(isPresented: $creating) {
            NavigationStack { ProjectForm() }.tint(NeonOrbit.accent)
        }
    }
}
