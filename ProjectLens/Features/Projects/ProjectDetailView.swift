import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    @State private var editing = false
    @State private var deleting = false
    @State private var adding: TransactionKind?
    @State private var editingTransaction: LedgerTransaction?
    @State private var errorMessage: String?
    private var project: LedgerProject? { ledger.project(id: projectID) }

    var body: some View {
        Group {
            if ledger.isLoading {
                ProgressView("Opening your project…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = ledger.loadError {
                LedgerLoadError(message: error)
            } else if let project, let financials = ledger.projectFinancials[projectID] {
                content(project, financials)
            } else {
                ContentUnavailableView("Project unavailable", systemImage: "square.stack.3d.up", description: Text("The project may have been deleted. Its transactions remain in Money."))
            }
        }
        .foregroundStyle(NeonOrbit.primaryText)
        .background(NeonOrbit.background.ignoresSafeArea())
        .navigationTitle(project?.name ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { editing = true }
                    .disabled(project == nil || ledger.isSaving || !ledger.hasLoaded || ledger.isLoading)
                    .accessibilityIdentifier("project.edit")
            }
        }
        .sheet(isPresented: $editing) {
            if let project { NavigationStack { ProjectForm(existing: project) }.tint(NeonOrbit.accent) }
        }
        .sheet(item: $adding) { kind in
            if let project {
                NavigationStack {
                    TransactionForm(kind: kind, initialProject: project) { adding = nil }
                }.tint(NeonOrbit.accent)
            }
        }
        .sheet(item: $editingTransaction) { record in
            NavigationStack {
                TransactionForm(kind: record.kind, existing: record) { editingTransaction = nil }
            }.tint(NeonOrbit.accent)
        }
        .confirmationDialog("Delete this project?", isPresented: $deleting, titleVisibility: .visible) {
            Button("Delete project", role: .destructive) {
                guard let project else { return }
                Task {
                    do { try await ledger.deleteProject(project); dismiss() }
                    catch { errorMessage = (error as? LedgerError)?.errorDescription ?? "Could not delete project. Please retry." }
                }
            }
        } message: { Text("All linked income and expenses will be kept in Money and unlinked from this project. This cannot be undone.") }
        .alert("Could not change project", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func content(_ project: LedgerProject, _ financials: ProjectFinancials) -> some View {
        List {
            Section("Project") {
                Text("\(project.status.title) · \(project.currency.rawValue)")
                if !project.description.isEmpty { Text(project.description) }
                if let start = project.startDate { Text("Starts: \(start.formatted(date: .abbreviated, time: .omitted))") }
                if let end = project.endDate { Text("Ends: \(end.formatted(date: .abbreviated, time: .omitted))") }
            }.listRowBackground(NeonOrbit.surface)
            Section {
                metric("Revenue", financials.revenue, project.currency, "project.revenue")
                metric("Expenses", financials.expenses, project.currency, "project.expenses")
                metric("Profit / loss", financials.profit, project.currency, "project.profit")
            } header: { Text("Recorded profitability") }
            footer: { Text("Revenue minus expenses, from all linked entries. Negative profit / loss means a loss. This is recorded activity, not a bank balance or forecast.") }
            .listRowBackground(NeonOrbit.surface)
            Section {
                if let budget = project.budget, let remaining = financials.remainingBudget {
                    metric("Budget", budget, project.currency, "project.limit")
                    metric("Remaining budget", remaining, project.currency, "project.remaining")
                    if remaining < 0 { Text("Over budget").font(NeonOrbit.Typography.label) }
                } else {
                    Text("No budget set").accessibilityIdentifier("project.noBudget")
                    Text("Edit this project to set an expense limit.").foregroundStyle(NeonOrbit.secondaryText)
                }
            } header: { Text("Expense budget") }
            footer: { Text("Remaining budget is budget minus expenses. Income does not replenish the budget. A negative remainder means spending is over budget. All amounts are \(project.currency.rawValue); no currency conversion is performed.") }
            .listRowBackground(NeonOrbit.surface)
            Section("Linked transactions") {
                if financials.transactionCount == 0 {
                    Text("No linked entries yet. Add income or an expense here, or link an existing entry from Money.")
                        .foregroundStyle(NeonOrbit.secondaryText)
                }
                Button("Add expense") { adding = .expense }
                    .accessibilityIdentifier("project.addExpense")
                    .disabled(ledger.isSaving)
                Button("Add income") { adding = .income }
                    .accessibilityIdentifier("project.addIncome")
                    .disabled(ledger.isSaving)
                ForEach(ledger.transactions.filter { $0.projectID == projectID }) { record in
                    Button { editingTransaction = record } label: {
                        VStack(alignment: .leading, spacing: NeonOrbit.Spacing.small) {
                            Text(record.category).font(NeonOrbit.Typography.label)
                            Text("\(record.kind.title) · \(record.currency.formatted(record.amount))")
                            Text(record.date, style: .date).font(NeonOrbit.Typography.caption)
                        }.accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Edit or change project association")
                }
            }.listRowBackground(NeonOrbit.surface)
            Section {
                Button(project.status == .archived ? "Restore project" : "Archive project") {
                    Task {
                        do { try await ledger.saveProject(project.withStatus(project.status == .archived ? .active : .archived), editing: true) }
                        catch { errorMessage = (error as? LedgerError)?.errorDescription ?? "Could not change project status. Please retry." }
                    }
                }
                .accessibilityIdentifier("project.archive")
                .disabled(ledger.isSaving)
                Button("Delete project…", role: .destructive) { deleting = true }
                    .accessibilityIdentifier("project.delete")
                    .disabled(ledger.isSaving)
            } footer: { Text("Archiving preserves this project, its links and totals. Archived projects can still receive entries. Deleting keeps all transactions and removes only their project link.") }
            .listRowBackground(NeonOrbit.surface)
        }
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("project.detail")
    }

    private func metric(_ title: String, _ amount: Decimal, _ currency: LedgerCurrency, _ identifier: String) -> some View {
        VStack(alignment: .leading, spacing: NeonOrbit.Spacing.extraSmall) {
            Text(title).font(NeonOrbit.Typography.caption).foregroundStyle(NeonOrbit.secondaryText)
            Text(currency.formatted(amount)).font(NeonOrbit.Typography.heading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
