# Security

ProjectLens is pre-release and not ready to hold sensitive financial data. No financial storage, backend, authentication or provider integration exists yet. Only the current main branch will receive security fixes during foundation development; no released versions are supported yet.

Do not disclose vulnerabilities, credentials or financial records in public issues. Once the public repository exists, use GitHub's **Security → Report a vulnerability** if private reporting is enabled. If that control is absent, a private reporting channel must be established with the maintainer before sharing sensitive details. No monitored security email or response SLA is established.

Before collecting data: define a threat model, data classification, retention/deletion policy and backup behavior. Use Keychain for credentials, platform data protection for local data, HTTPS for transport and narrowly scoped provider authorization. Never embed service secrets. Financial amounts and identifiers must not appear in logs or telemetry by default. Any sync, analytics or AI processing requires an explicit privacy and consent design.
