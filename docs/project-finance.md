# Phase 3 — Projects, budgets and recorded profitability

Projects and transactions use the existing LedgerRepository actor and LedgerStore. There is no second finance store or new dependency. Home/branding, currency-separated ledger totals, Money CRUD and Quick Add remain in place.

## Projects and associations

- A project has a stable UUID, trimmed 1–120 character name, description up to 2,000 characters, planned/active/completed/archived status, optional start/end dates, currency and optional expense budget. If both dates exist, end must be on or after start. Duplicate names are permitted; links use IDs, never names.
- Create/edit in Projects; open a detail to inspect finances, add linked entries, edit existing entries, archive/restore, or confirm deletion. Archived projects are grouped separately, retain all history and can still receive entries. Restore sets status to active; edit can select any status.
- Transaction forms in Money, Quick Add and project details share the same implementation. Select another project to relink, or No project to unlink. Selecting a project never changes the amount or currency silently. A project-origin form explicitly starts with that project's currency and ID.
- Every linked transaction must match the project's currency. The repository rejects missing projects and currency mismatches before writing. Project currency is locked while any entries are linked; unlink them first to change it. The UI explains mismatches and preserves the draft on failure.
- Confirmed project deletion removes the project and clears its links in one atomic write. Transaction IDs, kinds, amounts, currencies, categories, dates and notes are retained, so ledger totals are unchanged. The action is irreversible; archiving is the reversible alternative.

## Financial meaning

All calculations use checked Foundation Decimal operations and canonical decimal strings. Budgets reuse the currency's precision and 12 whole-digit input limit; blank means no limit, zero is a real limit, and negatives/excess precision are rejected. Each project has one currency; no exchange rates or combined multi-currency sum exist.

| Metric | Definition |
| --- | --- |
| Revenue | Sum of linked income |
| Expenses | Sum of linked expenses |
| Profit / loss | Revenue − expenses; negative means loss |
| Remaining budget | Budget − expenses; negative means over budget |

Income does not replenish a budget. A profitable project can still exceed its expense budget. No-budget and no-entry states are explicit. Dates/status do not filter totals; all linked history is included. These are recorded flows, not account balances, accrual accounting or forecasts.

## Schema 1 → 2 migration

The file remains `Application Support/Koshvya/ledger-v1.json` so existing installations find it. Its internal version becomes 2, containing projects and transactions together. There is no parallel project file.

1. Read and decode the original, validating transaction fields and unique IDs before any write.
2. Group nonblank legacy labels by exact trimmed text **and transaction currency**. Each group becomes an active project with no budget/dates/description. Matching is case-sensitive; no fuzzy matching or currency conversion occurs. Blank/absent labels stay unlinked. The UI continues to show project names through the new relationship.
3. Preserve every transaction UUID and financial/metadata field, replacing only the label with its group's project UUID. Validate all links, currencies and calculated totals.
4. Persist the original bytes as `ledger-v1.json.v1-backup` using atomic writing and complete iOS file protection. Never overwrite an existing backup with different bytes; report a safe read error instead.
5. Atomically replace the original with schema 2, then publish. Reloads reuse persisted project IDs. A failed validation/backup/write blocks opening and retains the original ledger; retry after resolving the storage issue. A crash after backup and before replacement can safely retry against matching backup bytes.

Unrecognized versions and corrupt documents block mutations; nothing is auto-reset. Old schema-1-only app builds cannot open schema 2. Backup restoration is a maintainer-assisted recovery operation, not an in-app feature: replacing schema 2 with its old backup would discard subsequent edits and must never be done automatically. The backup is retained, contains historical data and may enter device backups. Uninstall/data removal can remove both files. There is no cloud sync or app-managed export/recovery.

## Validation

See [validation](validation.md) for actual local and CI results. Tests cover CRUD/reload/archive, stable links/relink/unlink, deletion preservation, currency/orphan rejection, exact budgets/profitability, migration/backup failures and UI create/link workflows. Minimum-iOS, physical-device, VoiceOver and full appearance audits remain separate release checks.
