# Koshvya

A local finance and project intelligence app by Vyuhika, built for iPhone with the Neon Orbit design language.

## Implemented

- Native Home, Money, Projects and Upcoming navigation with adaptive light/dark styling.
- Create, read, edit and delete income/expense entries: positive amount, currency, category, date, notes and optional project label.
- Home all-time income, expense and net totals from saved entries, kept separate by currency.
- Quick Add forms, validation, atomic local persistence, loading/retry states and delete confirmation.

Projects and Upcoming remain honest planned-feature screens. Transfers and recurring commitments are labeled not yet available. No backend, authentication, account connection, AI, synchronization or conversion is implemented. No real-looking sample financial records are seeded.

## Development

Open `ProjectLens.xcodeproj`, select the shared `ProjectLens` scheme and an iPhone simulator. Minimum iOS 17, Swift 6, no third-party packages. The internal project/target names and `com.vyuhika.projectlens` bundle ID deliberately remain stable; the display name is Koshvya.

```bash
bash scripts/ci-ios.sh
```

CI remains Xcode 26.6 on macos-26 with required build/test status and always-run xcresult diagnostics/artifacts. Local toolchain: Xcode 27.1. See [validation](docs/validation.md) for actual results and environment restrictions.

## Local data

The versioned ledger is in Application Support/Koshvya/ledger-v1.json inside the app sandbox. Decimal amounts are stored as exact strings; no binary floating-point money arithmetic is used. Supported currencies: INR, USD, EUR, GBP (2 decimal places), JPY (0), KWD (3). Amounts must be positive with at most 12 whole-number digits. Grouping, symbols and scientific notation are rejected; the current locale's decimal separator or canonical dot is accepted. Excess precision is rejected, never silently rounded.

The form defaults to INR and always shows the currency. Totals are all-time recorded flows, not bank balances. Project association is a user-entered label, not a project database relationship. Editing currency relabels the entry; it does not perform conversion.

An actor serializes file access; atomic writes and iOS complete file protection protect local storage. Corrupt/unsupported files block writes rather than being reset. Errors do not log financial contents. Data remains until edited/deleted or the app is removed; standard device backups may contain the ledger. No app-managed cloud sync, export/recovery or custom encryption is provided. Do not treat this pre-release milestone as a finished financial system.

## Documentation and release work

See [architecture](docs/architecture.md), [PRD](docs/PRD.md), [design system](docs/design-system.md) and [icon deliverables](docs/branding.md). App icon artwork, signing, privacy disclosures, minimum-runtime and device accessibility verification remain release requirements.

Copyright 2026 Vyuhika. [Apache-2.0](LICENSE). Repository history retains the former ProjectLens name.
