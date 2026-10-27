# Security

Koshvya is pre-release. It stores financial entries and project records locally in the app sandbox using atomic replacement and iOS complete file protection. There is no backend, authentication, analytics, provider integration, AI processing or app-managed synchronization. Standard device backups may include the ledger; no custom encryption or recovery/export mechanism is provided. Only the current main branch receives fixes; no released version is supported yet.

The app never intentionally logs financial amounts, notes or project descriptions. Invalid/unreadable files block writes; users can retry after unlocking the device. Do not commit real records, credentials or signing assets. Unit tests use temporary files; DEBUG UI tests use a separate UUID-scoped ledger without touching the user's data.

Do not disclose vulnerabilities or financial records in public issues. Use GitHub Security → Report a vulnerability if enabled. If absent, establish a private channel with the maintainer before sharing sensitive details. No monitored security email or response SLA is established.

Schema-1 migration retains a protected byte-for-byte backup before replacing the ledger; this file contains historical financial data, including transactions later deleted in the app. It is retained until the app’s data is removed and can be included in standard device backups. There is no in-app backup restore or erase control yet.

Cloud integration, telemetry, export, retention controls and future persistence migrations require dedicated threat-model/privacy decisions. Never embed provider secrets in the app.
