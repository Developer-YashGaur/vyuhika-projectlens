import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var ledger: LedgerStore
    var body: some View {
        VStack(spacing: 0) {
            Image("KoshvyaLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220, maxHeight: 165)
                .padding(NeonOrbit.Spacing.small)
                .background(Color(red: 0.02, green: 0.03, blue: 0.08),
                            in: RoundedRectangle(cornerRadius: NeonOrbit.Radius.surface))
                .padding(.vertical, NeonOrbit.Spacing.small)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Koshvya by Vyuhika")
                .accessibilityIdentifier("home.logo")
            homeContent
        }
        .foregroundStyle(NeonOrbit.primaryText)
        .background(NeonOrbit.background.ignoresSafeArea())
        .toolbarBackground(NeonOrbit.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var homeContent: some View {
        Group {
            if ledger.isLoading {
                ProgressView("Opening your ledger…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = ledger.loadError {
                LedgerLoadError(message: error)
            } else if ledger.transactions.isEmpty {
                OrbitEmptyState(symbol: "circle.hexagongrid", eyebrow: "KOSHVYA · BY VYUHIKA",
                                title: "Big ideas.\nClearer horizons.", message: "Give your finances a place to begin.",
                                detail: "Add your first income or expense. Totals will appear here from your saved entries, separately for each currency.", identifier: "home.empty")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: NeonOrbit.Spacing.large) {
                        Text("Koshvya").font(NeonOrbit.Typography.title).accessibilityAddTraits(.isHeader)
                        Text("Your recorded money, in focus.").foregroundStyle(NeonOrbit.secondaryText)
                        Text("All-time totals · by currency").font(NeonOrbit.Typography.label)
                        ForEach(LedgerCurrency.allCases.filter { ledger.totals[$0] != nil }) { currency in
                            if let totals = ledger.totals[currency] {
                                VStack(alignment: .leading, spacing: NeonOrbit.Spacing.medium) {
                                    Text(currency.rawValue).font(NeonOrbit.Typography.heading)
                                    total("Income", totals.income, currency)
                                    total("Expenses", totals.expenses, currency)
                                    total("Net recorded", totals.net, currency)
                                }
                                .padding(NeonOrbit.Spacing.large)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(NeonOrbit.surface, in: RoundedRectangle(cornerRadius: NeonOrbit.Radius.surface))
                            }
                        }
                        Text("Totals reflect only your saved entries. Net recorded is income minus expenses, not a bank balance. Currencies are never combined.")
                            .font(NeonOrbit.Typography.caption).foregroundStyle(NeonOrbit.secondaryText)
                    }
                    .padding(NeonOrbit.Spacing.large)
                    .frame(maxWidth: 600, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func total(_ title: String, _ amount: Decimal, _ currency: LedgerCurrency) -> some View {
        VStack(alignment: .leading, spacing: NeonOrbit.Spacing.extraSmall) {
            Text(title).font(NeonOrbit.Typography.caption)
            Text(currency.formatted(amount)).font(NeonOrbit.Typography.heading)
                .accessibilityIdentifier("total.\(currency.rawValue).\(title)")
        }
    }
}
