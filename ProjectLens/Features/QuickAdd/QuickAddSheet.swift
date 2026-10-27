import SwiftUI

enum QuickAddEntry: String, CaseIterable, Identifiable {
    case expense, income, recurringCommitment, transfer

    var id: Self { self }

    var title: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        case .recurringCommitment: "Recurring commitment"
        case .transfer: "Transfer"
        }
    }

    var symbol: String {
        switch self {
        case .expense: "arrow.up.right"
        case .income: "arrow.down.left"
        case .recurringCommitment: "repeat"
        case .transfer: "arrow.left.arrow.right"
        }
    }

    var summary: String {
        switch self {
        case .expense: "Everyday spending and project costs"
        case .income: "Earnings from your work and beyond"
        case .recurringCommitment: "Subscriptions and regular payments"
        case .transfer: "Movement between your accounts"
        }
    }
}

/// A reusable chooser preview. It intentionally exposes no save or data-entry controls.
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: QuickAddEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NeonOrbit.Spacing.large) {
                    Text("Start with a type.")
                        .font(NeonOrbit.Typography.heading)
                        .accessibilityAddTraits(.isHeader)
                    Text("Explore the planned entry types. Creating and saving entries isn’t available yet.")
                        .font(NeonOrbit.Typography.body)
                        .foregroundStyle(NeonOrbit.secondaryText)
                    VStack(spacing: NeonOrbit.Spacing.medium) {
                        ForEach(QuickAddEntry.allCases) { entry in
                            entryButton(entry)
                        }
                    }
                    if let selection {
                        Text("\(selection.title) selected. Entry forms are coming in a future release. Nothing has been saved.")
                            .font(NeonOrbit.Typography.body)
                            .foregroundStyle(NeonOrbit.secondaryText)
                            .accessibilityIdentifier("quickAdd.preview")
                    }
                }
                .padding(NeonOrbit.Spacing.large)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("quickAdd.entries")
            .background(NeonOrbit.background.ignoresSafeArea())
            .foregroundStyle(NeonOrbit.primaryText)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(NeonOrbit.Typography.label)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: NeonOrbit.Radius.control))
                .tint(NeonOrbit.actionFill)
                .foregroundStyle(NeonOrbit.onAction)
                .accessibilityIdentifier("quickAdd.done")
                .padding(NeonOrbit.Spacing.medium)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .background(NeonOrbit.background)
            }
        }
        .tint(NeonOrbit.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func entryButton(_ entry: QuickAddEntry) -> some View {
        let isSelected = selection == entry
        return Button {
            withAnimation(NeonOrbit.Motion.selection(reduceMotion: reduceMotion)) {
                selection = entry
            }
        } label: {
            HStack(alignment: .top, spacing: NeonOrbit.Spacing.medium) {
                Image(systemName: entry.symbol)
                    .font(.title3)
                    .foregroundStyle(entry == .income ? NeonOrbit.positive : NeonOrbit.secondaryAccent)
                    .frame(minWidth: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: NeonOrbit.Spacing.extraSmall) {
                    Text(entry.title).font(NeonOrbit.Typography.label)
                    Text(entry.summary)
                        .font(NeonOrbit.Typography.caption)
                        .foregroundStyle(NeonOrbit.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(NeonOrbit.accent)
                    .accessibilityHidden(true)
            }
            .padding(NeonOrbit.Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(NeonOrbit.surface, in: RoundedRectangle(cornerRadius: NeonOrbit.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: NeonOrbit.Radius.control)
                    .strokeBorder(isSelected ? NeonOrbit.accent : NeonOrbit.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Previews this entry type. Does not create an entry.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("quickAdd.\(entry.rawValue)")
    }
}
