# Koshvya architecture

One native iPhone SwiftUI app module, iOS 17 minimum, Swift 6 language mode. Internal ProjectLens target/scheme/bundle identity is preserved. No external packages, backend, provider integration or authentication.

## Boundaries

- App: lifecycle, one LedgerStore/actor repository, native tab navigation and a single Quick Add presenter.
- Domain/Transaction.swift and Project.swift: immutable validated transaction values, explicit currency precision, exact Decimal parsing/string encoding and checked totals grouped by currency. Project validation, stable associations, single-currency project financials and a shared ledger snapshot. No SwiftUI or storage dependencies.
- Persistence/LedgerRepository.swift: actor-isolated CRUD, versioned JSON document, validation on decode, duplicate-ID/relationship/currency checks, schema-1 migration with protected original backup, atomic replacement and complete iOS file protection.
- Persistence/LedgerStore.swift: main-actor observable loading/saving/error state, sorted records/projects and checked ledger/project totals; publishes only after successful persistence. Blocks mutations while loading or another write is active.
- Features: Home summaries, Money list/edit/delete confirmation, Quick Add chooser and shared create/edit form. Projects supports CRUD, archive/restore, budgets, profitability and shared transaction forms. Upcoming remains a planned-feature placeholder.
- Shared/DesignSystem: Neon Orbit tokens and reusable empty states. Services remains unimplemented.

## Storage decision

A small versioned document store fits the current single-user local CRUD scope without frameworks or speculative repository protocols. It re-reads and validates the file before each mutation; one actor serves the app. This is not a multi-process or high-volume database. Each write replaces the whole document, so revisit indexing/storage using measured ledger size before large imports or background integrations. There are no app extensions or shared writers.

Schema 2 stores transactions and projects in one document at the original `ledger-v1.json` path. Transactions contain UUID, kind, canonical decimal amount string, currency, category, date, notes and optional project UUID. Projects contain UUID, name, description, status, optional dates, currency and optional canonical decimal budget string. Dates use Codable Date's instant representation; display follows the device locale/calendar. Optional dates describe the project and do not bound financial calculations.

The repository validates the entire snapshot before persistence: unique IDs, existing project links, matching linked currencies, exact totals and valid decoded values. Project deletion clears links in the same atomic replacement, preserving transaction IDs and all other fields. Renaming keeps relationships; currency changes are rejected while links exist. Archive is an organizational status, not a financial lock. Project summaries reuse the existing LedgerTotals and checked Decimal operations, filtering by UUID and refusing mismatched currencies. Budget minus expenses and revenue minus expenses are separate calculations; there is no combined project/currency total.

On first read, valid schema 1 migrates to schema 2. Exact trimmed label plus currency identifies a migrated project; blank labels remain unlinked. All transaction fields/IDs are preserved and project IDs are persisted before the snapshot is published. A byte-for-byte original backup with complete iOS file protection is written before replacing the original ledger; conflicting existing backup bytes block migration. Invalid or unsupported files are never reset. See [migration policy](project-finance.md).

The ledger lives in Application Support/Koshvya, with atomic file replacement and iOS complete file protection. Access while the device is locked can fail safely and should be retried after unlock. Standard device backups remain enabled; there is no custom encryption, synchronization or logging of financial contents. Uninstalling the app can remove its local data. The migration backup also contains historical financial data and is retained with standard device backups. Export/recovery UI, future schema migrations and multi-device conflict policy require separate work.

## UI and concurrency

The app creates one LedgerStore and injects it through the existing SwiftUI environment. File I/O runs on the repository actor rather than the UI actor. The initial read shows a loading state; read failures show Retry and block saving. Forms keep drafts locally, validate on submit, suppress duplicate submissions, retain drafts on errors and dismiss after a successful write. Cancel does not persist. Editing retains the transaction UUID. Delete asks for confirmation and reports failures. Home, Money and Projects share the same published snapshot. Project forms follow the same save/error lifecycle. Financial summaries are recomputed from the persisted snapshot, never stored as mutable totals.

DEBUG UI tests provide a UUID-named isolated ledger in a dedicated caches subdirectory; no user ledger is erased and no data is pre-seeded. Release builds ignore the test override. UI tests create their own entries and verify display/relaunch persistence.

## Build and release

Keep the checked-in Xcode project and existing shared scheme/CI requirements. User-facing display name is Koshvya; targets and bundle ID remain ProjectLens/com.vyuhika.projectlens to preserve history and installed data identity. The approved AppIcon and Home logo remain unchanged. See branding.md for source assets and release requirements. Device signing, privacy disclosures, icon validation and minimum iOS 17/device accessibility checks are still required before distribution.
