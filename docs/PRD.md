# Koshvya product requirements

Koshvya is Vyuhika's native iPhone finance and project intelligence app, formerly called ProjectLens. Neon Orbit remains the visual direction. Target users: developers, freelancers, indie hackers and startup founders.

## Implemented through Phase 3

- Local income/expense CRUD with amount, currency, category, date, notes and optional persisted project UUID.
- Quick Add forms, validation and safe local persistence; no fictional financial records.
- Money list with editing and confirmed deletion; Home all-time per-currency flow totals derived from stored entries.
- Persistent project workspaces with create/edit/archive/restore/delete, description, status, optional dates/currency/budget, and linked transaction controls.
- Project revenue, expenses, remaining expense budget and profit/loss, with explicit single-currency rules and safe schema migration.
- Native navigation, light/dark, scalable type, accessibility labels and reduced-motion-aware existing interactions.

The supported currency set and precision are explicit in README. There is no conversion or cross-currency total. Net recorded is income less expenses, not a bank balance. Project budget consumption and profitability are distinct; deleting a project preserves and unlinks its transactions.

## Planned, not implemented

Transfers, recurring commitments, invoices, split allocation, release planning, financial intelligence, provider integrations, synchronization, collaboration and AI-supported insights. No onboarding, authentication, backend, paid integration or monetization is included. These plans have no delivery commitments.

## Acceptance and limits

Records survive relaunch, invalid input cannot save, cancel leaves storage unchanged, failed reads/writes report safe errors, and corrupt/future-version files are not overwritten. Decimal totals remain exact and currency-separated. Financial records do not enter logs. Local data uses OS protection and standard device backups; app-managed export/recovery is not yet available. CI, device accessibility and minimum-runtime results must be reported accurately, including blocked checks.
