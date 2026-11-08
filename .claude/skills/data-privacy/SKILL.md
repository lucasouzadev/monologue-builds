---
name: data-privacy
description: Data in transit, data at rest, privacy/minimization and safe logging. Use when touching storage, encryption, TLS, personal data, analytics or third-party SDKs, logs or telemetry, backups or account deletion.
---

# Data, crypto and privacy

1. **Encrypt in transit, never invent crypto.** TLS everywhere, no cleartext exceptions (platform configs block it); HSTS on the web; never disable certificate validation, "temporarily" included; platform libraries and approved algorithms only; pinning only with a rotation plan. *Essential (pinning: Advanced).*
2. **Store less, store in the right place.** Tokens and keys in the OS vault, never in preferences, plain SQLite or `localStorage`. Keep sensitive data out of backups, logs, HTTP caches, app-switcher screenshots and the clipboard. Hardware-backed keys where available. *Essential.*
3. **Minimize.** Data you never collected cannot leak and creates no legal duty (LGPD/GDPR). For each field: purpose, legal basis, retention. Inventory third-party SDKs and what they collect. Account and data deletion path exists. Store privacy manifests match reality. *Essential.*
4. **Useful logs, no secrets, with alerts.** Never log passwords, access tokens, session IDs (hash them to correlate), keys, connection strings, card data or sensitive PII. Neutralize CR/LF and delimiters (log injection, CWE-117). Treat logs from other zones as untrusted. Log security events (failed logins, access denials, privilege changes) **and alert on them** — a log without an alert detects nothing. *Essential.*

## Verify
- grep the build artifact and sample logs for tokens/PII; inspect backup and cache contents on a device.
- Privacy review per new field/SDK; deletion test removes data everywhere it was copied (storage objects included).
- Security-event alert fires in staging.

## Gotchas
- Web storage and preference files are plain text.
- Error trackers and analytics often capture URLs with tokens or personal data — scrub before sending.
- Public CI logs and artifacts are public: synthetic fixtures only.

Sources: OWASP Top 10:2025 A04/A09; OWASP MASVS-STORAGE/CRYPTO/NETWORK/PRIVACY (v2.1.0); OWASP Mobile Top 10 2024 M5/M9; OWASP Logging Cheat Sheet.
