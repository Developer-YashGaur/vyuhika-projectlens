import SwiftUI

struct MoneyView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @State private var editing: LedgerTransaction?
    @State private var deleting: LedgerTransaction?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if ledger.isLoading {
                ProgressView("Opening your ledger…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = ledger.loadError {
                LedgerLoadError(message: error)
            } else if ledger.transactions.isEmpty {
                OrbitEmptyState(symbol: "creditcard", eyebrow: "MONEY · YOUR LOCAL LEDGER",
                                title: "Start with one entry.", message: "Your money, in focus.",
                                detail: "Use Quick Add to save income or an expense on this device. No accounts are connected.", identifier: "money.empty")
            } else {
                List {
                    Section {
                        ForEach(ledger.transactions) { record in
                            Button { editing = record } label: { row(record) }
                                .buttonStyle(.plain)
                                .accessibilityHint("Edit transaction")
                                .swipeActions {
                                    Button("Delete", role: .destructive) { deleting = record }
                                        .disabled(ledger.isSaving)
                                }
                                .listRowBackground(NeonOrbit.surface)
                        }
                    } header: { Text("All transactions") }
                    footer: { Text("Amounts stay in their original currency. No exchange rates or account balances are inferred.") }
                }
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("money.transactions")
            }
        }
        .foregroundStyle(NeonOrbit.primaryText)
        .background(NeonOrbit.background.ignoresSafeArea())
        .sheet(item: $editing) { record in
            NavigationStack {
                TransactionForm(kind: record.kind, existing: record) { editing = nil }
            }.tint(NeonOrbit.accent)
        }
        .confirmationDialog("Delete this transaction?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete transaction", role: .destructive) {
                guard let record = deleting else { return }
                deleting = nil
                Task {
                    do { try await ledger.delete(record) }
                    catch { errorMessage = (error as? LedgerError)?.errorDescription ?? "Could not delete the transaction. Please retry." }
                }
            }
        } message: { Text("This removes the entry from this device.") }
        .alert("Could not delete", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func row(_ record: LedgerTransaction) -> some View {
        VStack(alignment: .leading, spacing: NeonOrbit.Spacing.small) {
            Text(record.category).font(NeonOrbit.Typography.label)
            Text("\(record.kind.title) · \(record.currency.rawValue) \(record.currency.formatted(record.amount))")
                .foregroundStyle(record.kind == .income ? NeonOrbit.positive : NeonOrbit.primaryText)
            Text(record.date, style: .date).font(NeonOrbit.Typography.caption)
            if let project = ledger.project(id: record.projectID) { Text("Project: \(project.name)").font(NeonOrbit.Typography.caption) }
            if !record.notes.isEmpty { Text(record.notes).font(NeonOrbit.Typography.caption) }
        }
        .padding(.vertical, NeonOrbit.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("transaction.\(record.id.uuidString)")
    }
}

struct LedgerLoadError: View {
    @EnvironmentObject private var ledger: LedgerStore
    let message: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NeonOrbit.Spacing.large) {
                Text("Your ledger needs attention").font(NeonOrbit.Typography.heading).accessibilityAddTraits(.isHeader)
                Text(message)
                Button("Retry") { Task { await ledger.load() } }
                    .buttonStyle(.borderedProminent)
            }.padding(NeonOrbit.Spacing.large)
        }
    }
}
