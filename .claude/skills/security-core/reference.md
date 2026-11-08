# Security core — reference

## OWASP Top 10:2025 (final)
A01 Broken Access Control (now includes SSRF) · A02 Security Misconfiguration · A03 Software Supply Chain Failures (new) · A04 Cryptographic Failures · A05 Injection · A06 Insecure Design · A07 Authentication Failures · A08 Software or Data Integrity Failures · A09 Security Logging and Alerting Failures · A10 Mishandling of Exceptional Conditions (new).
Reading: risk moved from "code bug" to design, configuration and supply chain; failing open is now its own category.

## Catalogues to verify against
- **OWASP ASVS 5.0.0** (May 2025): 345 requirements in 17 chapters, 70 at L1; asks for documented security decisions. Best verifiable catalogue for web/API.
- **OWASP MASVS v2.1.0** (Jan 2024, adds MASVS-PRIVACY) + **MASTG v2**: control (MASVS) → weakness (MASWE) → test (MASTG). Levels became test profiles. Mobile Top 10 2024: M1 Improper Credential Usage, M2 Inadequate Supply Chain Security.
- **NIST SSDF** SP 800-218 v1.1 (final); v1.2 draft (Dec 2025) adds PO.6 continuous improvement and PS.4 robust updates — direction, not norm.
- **CISA Secure by Design**: eliminate whole vulnerability classes, no default passwords, MFA at no extra cost, multiple layers of defense.

## Sources
OWASP Top 10:2025 · OWASP ASVS 5.0 · OWASP MASVS/MASTG · NIST SP 800-218 · CISA "Principles and Approaches for Secure by Design Software" · Electron and Capacitor security guides (examples of principle only).
Check versions before citing them in a contract or audit.
