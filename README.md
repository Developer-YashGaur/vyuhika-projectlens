# Koshvya

A local finance and project intelligence app by Vyuhika, built for iPhone with the Neon Orbit design language.

## Implemented

- Native Home, Money, Projects and Upcoming navigation with adaptive light/dark styling.
- Approved Koshvya iPhone app icon and Home logo.
- Create, read, edit and delete income/expense entries: positive amount, currency, category, date, notes and optional persisted project link.
- Home all-time income, expense and net totals from saved entries, kept separate by currency.
- Persistent projects with descriptions, status, optional dates, currency and optional expense budget; create, edit, archive/restore and confirmed deletion.
- Project revenue, expenses, profit/loss and remaining budget, with editable linked transactions.
- Quick Add forms, validation, atomic local persistence, loading/retry states and delete confirmation.

Upcoming remains an honest planned-feature screen. Transfers and recurring commitments are labeled not yet available. No backend, authentication, account connection, AI, synchronization or conversion is implemented. No real-looking sample financial records are seeded.

## Development

Open `ProjectLens.xcodeproj`, select the shared `ProjectLens` scheme and an iPhone simulator. Minimum iOS 17, Swift 6, no third-party packages. The internal project/target names and `com.vyuhika.projectlens` bundle ID deliberately remain stable; the display name is Koshvya.

```bash
bash scripts/ci-ios.sh
```

CI remains Xcode 26.6 on macos-26 with required build/test status and always-run xcresult diagnostics/artifacts. Local toolchain: Xcode 27.1. See [validation](docs/validation.md) for actual results and environment restrictions.

## Local data

The versioned ledger is in Application Support/Koshvya/ledger-v1.json inside the app sandbox. Decimal amounts are stored as exact strings; no binary floating-point money arithmetic is used. Supported currencies: INR, USD, EUR, GBP (2 decimal places), JPY (0), KWD (3). Amounts must be positive with at most 12 whole-number digits. Grouping, symbols and scientific notation are rejected; the current locale's decimal separator or canonical dot is accepted. Excess precision is rejected, never silently rounded.

The form defaults to INR and always shows the currency. Totals are all-time recorded flows, not bank balances. Project associations use stable UUIDs. A linked entry must use its project’s currency; a project’s currency is fixed while entries are linked. Editing an unlinked currency relabels the amount; it does not perform conversion. Creating an entry from a project preselects that project and currency.

Schema 2 stores projects and transactions together at the original ledger path. Schema 1 migrates on first read: each exact trimmed project label and currency becomes a project with no budget; unlabeled entries remain unlinked. The original bytes are retained as `ledger-v1.json.v1-backup` before atomic replacement. A backup or migration failure blocks opening without resetting data. Older builds cannot read schema 2. See [project finance and migration](docs/project-finance.md) for policies and recovery limitations.

Budget consumption is expenses only: remaining budget = budget − expenses. Profit/loss = revenue − expenses. Income never replenishes a budget; a negative remaining amount means over budget. A blank budget means no limit, while zero is an explicit limit. Dates and status do not filter financial history. Archived projects retain their links and can receive entries. Deleting a project unlinks its transactions in the same atomic write and preserves them in Money.

An actor serializes file access; atomic writes and iOS complete file protection protect local storage. Corrupt/unsupported files block writes rather than being reset. Errors do not log financial contents. Data remains until edited/deleted or the app is removed; standard device backups may contain the ledger. No app-managed cloud sync, export/recovery or custom encryption is provided. Do not treat this pre-release milestone as a finished financial system.

## Documentation and release work

See [architecture](docs/architecture.md), [PRD](docs/PRD.md), [design system](docs/design-system.md) and [icon deliverables](docs/branding.md). Signing, privacy disclosures, minimum-runtime and device accessibility verification remain release requirements.

Copyright 2026 Vyuhika. [Apache-2.0](LICENSE). Repository history retains the former ProjectLens name.
