# Koshvya architecture

One native iPhone SwiftUI app module, iOS 17 minimum, Swift 6 language mode. Internal ProjectLens target/scheme/bundle identity is preserved. No external packages, backend, provider integration or authentication.

## Boundaries

- App: lifecycle, one LedgerStore/actor repository, native tab navigation and a single Quick Add presenter.
- Domain/Transaction.swift: immutable validated transaction values, explicit currency precision, exact Decimal parsing/string encoding and checked totals grouped by currency. No SwiftUI or storage dependencies.
- Persistence/LedgerRepository.swift: actor-isolated CRUD, versioned JSON document, validation on decode, duplicate-ID checks, atomic replacement and complete iOS file protection.
- Persistence/LedgerStore.swift: main-actor observable loading/saving/error state, sorted records and totals; publishes only after successful persistence. Blocks mutations while loading or another write is active.
- Features: Home summaries, Money list/edit/delete confirmation, Quick Add chooser and shared create/edit form. Projects and Upcoming remain planned-feature placeholders.
- Shared/DesignSystem: Neon Orbit tokens and reusable empty states. Services remains unimplemented.

## Storage decision

A small versioned document store fits the current single-user local CRUD scope without frameworks or speculative repository protocols. It re-reads and validates the file before each mutation; one actor serves the app. This is not a multi-process or high-volume database. Each write replaces the whole document, so revisit indexing/storage using measured ledger size before large imports or background integrations. There are no app extensions or shared writers.

Schema 1 stores UUID, kind, canonical decimal amount string, supported currency, category, date, notes and optional project label. Dates use Codable Date's instant representation; display follows the device locale/calendar. No month boundaries or accounting periods are inferred. Decimal sums use checked Foundation decimal operations and never combine currencies. Financial precision is rejected rather than rounded. The schema version must be understood before writes; unreadable files are never auto-reset.

The ledger lives in Application Support/Koshvya, with atomic file replacement and iOS complete file protection. Access while the device is locked can fail safely and should be retried after unlock. Standard device backups remain enabled; there is no custom encryption, synchronization or logging of financial contents. Uninstalling the app can remove its local data. Export/recovery, migrations to future schemas and multi-device conflict policy require separate work.

## UI and concurrency

The app creates one LedgerStore and injects it through the existing SwiftUI environment. File I/O runs on the repository actor rather than the UI actor. The initial read shows a loading state; read failures show Retry and block saving. Forms keep drafts locally, validate on submit, suppress duplicate submissions, retain drafts on errors and dismiss after a successful write. Cancel does not persist. Editing retains the transaction UUID. Delete asks for confirmation and reports failures. Home and Money share the same published snapshot.

DEBUG UI tests provide a UUID-named isolated ledger in a dedicated caches subdirectory; no user ledger is erased and no data is pre-seeded. Release builds ignore the test override. UI tests create their own entries and verify display/relaunch persistence.

## Build and release

Keep the checked-in Xcode project and existing shared scheme/CI requirements. User-facing display name is Koshvya; targets and bundle ID remain ProjectLens/com.vyuhika.projectlens to preserve history and installed data identity. The AppIcon slot is prepared without fabricated artwork or a configured release icon. See branding.md for required deliverables. Device signing, privacy disclosures, icon validation and minimum iOS 17/device accessibility checks are still required before distribution.
