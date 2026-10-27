import SwiftUI

struct ProjectForm: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let existing: LedgerProject?
    @State private var name: String
    @State private var details: String
    @State private var status: ProjectStatus
    @State private var currency: LedgerCurrency
    @State private var budget: String
    @State private var hasStart: Bool
    @State private var hasEnd: Bool
    @State private var start: Date
    @State private var end: Date
    @State private var errorMessage: String?
    @State private var submitting = false
    @FocusState private var focused: Field?
    private enum Field: Hashable { case name, details, budget }

    init(existing: LedgerProject? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _details = State(initialValue: existing?.description ?? "")
        _status = State(initialValue: existing?.status ?? .active)
        _currency = State(initialValue: existing?.currency ?? .INR)
        _budget = State(initialValue: existing?.budget.map(LedgerAmount.canonical) ?? "")
        _hasStart = State(initialValue: existing?.startDate != nil)
        _hasEnd = State(initialValue: existing?.endDate != nil)
        _start = State(initialValue: existing?.startDate ?? Date())
        _end = State(initialValue: existing?.endDate ?? Date())
    }

    private var currencyLocked: Bool {
        guard let existing else { return false }
        return ledger.transactions.contains { $0.projectID == existing.id }
    }

    var body: some View {
        Form {
            Section("Project") {
                TextField("Project name", text: $name)
                    .focused($focused, equals: .name)
                    .accessibilityIdentifier("project.name")
                TextField("Description (optional)", text: $details, axis: .vertical)
                    .focused($focused, equals: .details)
                    .accessibilityIdentifier("project.description")
                Picker("Status", selection: $status) {
                    ForEach(ProjectStatus.allCases) { Text($0.title).tag($0) }
                }.accessibilityIdentifier("project.status")
            }.listRowBackground(NeonOrbit.surface)
            Section {
                Picker("Currency", selection: $currency) {
                    ForEach(LedgerCurrency.allCases) { Text($0.rawValue).tag($0) }
                }
                .disabled(currencyLocked)
                .accessibilityIdentifier("project.currency")
                TextField("Budget (optional)", text: $budget)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .budget)
                    .accessibilityIdentifier("project.budget")
            } header: { Text("Expense budget") }
            footer: {
                Text("Budget is an expense limit, not revenue or profit. Leave blank for no budget; zero is allowed. \(currencyLocked ? "Currency is fixed while transactions are linked." : "Changing currency does not convert the budget.")")
            }.listRowBackground(NeonOrbit.surface)
            Section {
                Toggle("Start date", isOn: $hasStart)
                if hasStart { DatePicker("Starts", selection: $start, displayedComponents: .date) }
                Toggle("End date", isOn: $hasEnd)
                if hasEnd { DatePicker("Ends", selection: $end, displayedComponents: .date) }
            } header: { Text("Optional dates") }
            footer: { Text("Dates describe the project. Financial summaries include all linked entries, regardless of date. Archiving keeps the project and its financial history; it can still receive entries.") }
            .listRowBackground(NeonOrbit.surface)
        }
        .accessibilityIdentifier("project.form")
        .scrollContentBackground(.hidden)
        .background(NeonOrbit.background.ignoresSafeArea())
        .foregroundStyle(NeonOrbit.primaryText)
        .navigationTitle(existing == nil ? "New project" : "Edit project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(submitting || ledger.isSaving)
                    .accessibilityIdentifier("project.cancel")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide Keyboard") { focused = nil }
                    .accessibilityIdentifier("form.hideKeyboard")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                guard !submitting else { return }
                submitting = true
                focused = nil
                Task { await save() }
            } label: {
                Text(submitting ? "Saving…" : "Save project")
                    .font(NeonOrbit.Typography.label)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(NeonOrbit.actionFill)
            .foregroundStyle(NeonOrbit.onAction)
            .disabled(submitting || ledger.isSaving || !ledger.hasLoaded || ledger.isLoading)
            .accessibilityIdentifier("project.save")
            .padding(NeonOrbit.Spacing.medium)
            .background(NeonOrbit.background)
        }
        .interactiveDismissDisabled(submitting || ledger.isSaving)
        .alert("Could not save project", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func save() async {
        defer { submitting = false }
        do {
            let project = try LedgerProject(id: existing?.id ?? UUID(), name: name, description: details,
                                            status: status, startDate: hasStart ? start : nil, endDate: hasEnd ? end : nil,
                                            currency: currency, budgetText: budget)
            try await ledger.saveProject(project, editing: existing != nil)
            dismiss()
        } catch {
            errorMessage = (error as? LedgerError)?.errorDescription ?? "Could not write to local storage. Your draft has not been saved. Please retry."
        }
    }
}
