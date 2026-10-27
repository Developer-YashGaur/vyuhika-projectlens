# Security

Koshvya is pre-release. It stores financial entries locally in the app sandbox using atomic replacement and iOS complete file protection. There is no backend, authentication, analytics, provider integration, AI processing or app-managed synchronization. Standard device backups may include the ledger; no custom encryption or recovery/export mechanism is provided. Only the current main branch receives fixes; no released version is supported yet.

The app never intentionally logs financial amounts, notes or project labels. Invalid/unreadable files block writes; users can retry after unlocking the device. Do not commit real records, credentials or signing assets. Unit tests use temporary files; DEBUG UI tests use a separate UUID-scoped ledger without touching the user's data.

Do not disclose vulnerabilities or financial records in public issues. Use GitHub Security → Report a vulnerability if enabled. If absent, establish a private channel with the maintainer before sharing sensitive details. No monitored security email or response SLA is established.

Cloud integration, telemetry, export, retention controls and future persistence migrations require dedicated threat-model/privacy decisions. Never embed provider secrets in the app.
