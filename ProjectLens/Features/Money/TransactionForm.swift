import SwiftUI

struct TransactionForm: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    private let existing: LedgerTransaction?
    private let onSaved: () -> Void
    @State private var kind: TransactionKind
    @State private var amount: String
    @State private var currency: LedgerCurrency
    @State private var category: String
    @State private var date: Date
    @State private var notes: String
    @State private var project: String
    @State private var errorMessage: String?
    @State private var submitting = false

    init(kind: TransactionKind, existing: LedgerTransaction? = nil, onSaved: @escaping () -> Void) {
        self.existing = existing
        self.onSaved = onSaved
        _kind = State(initialValue: existing?.kind ?? kind)
        // The edit field accepts the canonical decimal separator as well as the locale's.
        _amount = State(initialValue: existing.map { LedgerAmount.canonical($0.amount) } ?? "")
        _currency = State(initialValue: existing?.currency ?? .INR)
        _category = State(initialValue: existing?.category ?? "")
        _date = State(initialValue: existing?.date ?? Date())
        _notes = State(initialValue: existing?.notes ?? "")
        _project = State(initialValue: existing?.project ?? "")
    }

    var body: some View {
        Form {
            Section("Transaction") {
                Picker("Type", selection: $kind) {
                    ForEach(TransactionKind.allCases) { Text($0.title).tag($0) }
                }
                TextField("Amount", text: $amount)
                    .focused($focused, equals: .amount)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("transaction.amount")
                Picker("Currency", selection: $currency) {
                    ForEach(LedgerCurrency.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("transaction.currency")
                TextField("Category", text: $category)
                    .focused($focused, equals: .category)
                    .accessibilityIdentifier("transaction.category")
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .listRowBackground(NeonOrbit.surface)
            Section {
                TextField("Project name (optional)", text: $project)
                    .focused($focused, equals: .project)
                    .accessibilityIdentifier("transaction.project")
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .focused($focused, equals: .notes)
                    .accessibilityIdentifier("transaction.notes")
            } header: { Text("Details") }
            footer: { Text("Stored on this device. Changing currency does not convert the amount. Project names are labels; no project workspace is created.") }
            .listRowBackground(NeonOrbit.surface)
        }
        .scrollContentBackground(.hidden)
        .background(NeonOrbit.background.ignoresSafeArea())
        .foregroundStyle(NeonOrbit.primaryText)
        .navigationTitle(existing == nil ? "Add \(kind.title)" : "Edit transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(submitting || ledger.isSaving)
                    .accessibilityIdentifier("transaction.cancel")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide Keyboard") { focused = nil }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                guard !submitting else { return }
                submitting = true
                focused = nil
                Task { await save() }
            } label: {
                Text(ledger.isSaving ? "Saving…" : "Save transaction")
                    .font(NeonOrbit.Typography.label)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(NeonOrbit.actionFill)
            .foregroundStyle(NeonOrbit.onAction)
            .disabled(submitting || ledger.isSaving || !ledger.hasLoaded || ledger.isLoading)
            .accessibilityIdentifier("transaction.save")
            .padding(NeonOrbit.Spacing.medium)
            .background(NeonOrbit.background)
        }
        .interactiveDismissDisabled(submitting || ledger.isSaving)
        .alert("Could not save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private enum Field: Hashable { case amount, category, project, notes }
    @FocusState private var focused: Field?

    private func save() async {
        defer { submitting = false }
        do {
            let record = try LedgerTransaction(id: existing?.id ?? UUID(), kind: kind, amountText: amount,
                                               currency: currency, category: category, date: date,
                                               notes: notes, project: project)
            try await ledger.save(record, editing: existing != nil)
            onSaved()
        } catch {
            errorMessage = (error as? LedgerError)?.errorDescription ?? "Could not write to local storage. Your changes have not been saved. Please retry."
        }
    }
}
