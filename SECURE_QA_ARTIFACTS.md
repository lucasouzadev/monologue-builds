# CI privacy boundary — Monologue Builds (public repository)

This repository is PUBLIC. Workflow logs, public branches and published artifacts may be visible to anyone. User notes, draft text, images, tokens, credentials, database exports, raw logcat/syslog and plaintext screenshots must never be published here.

## Changes in this PR
1. The Android and iOS Maestro workflows **no longer push screenshots to public `screens-*` branches**.
2. The scripts still create screenshots and Maestro diagnostics on their ephemeral runner, for quality analysis.
3. The workflow packages these files locally and encrypts the complete tarball with **AES-256-GCM**, using a fresh random salt/nonce and an authenticated integrity tag. It uploads **only** `visual-evidence.tgz.enc` for 7 days. A missing/short `ARTIFACT_PASSPHRASE` is a hard failure with no plaintext fallback.
4. The new static job tests syntax, invalid/absent screenshot cases, encryption round-trip, tamper rejection, and asserts raw screenshot publication cannot silently return.
5. Native compilation remains subject to the explicit owner approval rule in Monologue's constitution. Nothing here starts native builds, OTA, deploy or database migrations.

For this formatting gate, workflow encryption binds the dedicated repository secret
`M2_QA_EVIDENCE_PASSPHRASE` to the tool's `ARTIFACT_PASSPHRASE` environment variable.
It must contain at least 24 characters. The existing `ARTIFACT_PASSPHRASE` repository
secret still decrypts earlier APK/IPA artifacts and must not be overwritten to fix
visual evidence encryption. Both workflows check the evidence key before starting
tests. Local decryption still uses the environment variable below, with the evidence
key rather than the APK key.

## Accessing screenshots for authorized QA
Download the encrypted artifact to a **private workstation**, not a public issue or shared link. From the repo root, do not paste the passphrase into terminal commands/history:

```bash
read -rs ARTIFACT_PASSPHRASE
export ARTIFACT_PASSPHRASE
node tools/decrypt-visual-evidence.mjs visual-evidence.tgz.enc visual-evidence.tgz
unset ARTIFACT_PASSPHRASE
mkdir -p private-review
tar -xzf visual-evidence.tgz -C private-review
```

Store the decrypted files outside the public repository; delete local plaintext when finished. Never post decrypted screenshots in PRs or issues, and always inspect them in a private environment before marking visual QA PASS.

## Security limits and unresolved legacy risks
- **Encryption mitigates public artifact exposure; it does not make all public-runner activity confidential.** Build/source checkouts, third-party actions, caches, command errors, debug logs and a compromised runner can expose information before encryption.
- The repository has **historical `screens-android*` and `screens-ios*` branches** created by older workflows; this PR does not erase or revoke them. Review and remove them using authorized repository administration, and audit previously uploaded artifacts for accidental exposure. Rotate any potentially disclosed test credentials.
- Review of the historical branches (2026-10-30, read-only, nothing deleted): 202 branches (133 `screens-android*`, 69 `screens-ios*`), created 2026-10-09 to 2026-10-14, one commit each, 5,117 files at the tips: 4,390 PNG (251 of them 0 bytes), 726 uiautomator `.xml`. All 726 XML files were scanned for e-mails, phone numbers, URLs, tokens, UUIDs, IPs, CPF and internal hosts: none found; the only URL is `https://example.com/e2e`; the long digit strings are millisecond timestamps used as test markers. The 485 distinct text values not present verbatim in `maestro/` were read: app UI strings and synthetic QA fixtures. All 4,140 non-empty PNGs were checked for metadata: no GPS, no personal text (XMP only says "Screenshot"). Only 6 PNGs were looked at (iOS and Android, chosen from the riskiest types: gallery, attach, media viewer, system dialog, onboarding): simulator stock photos and QA fixtures. **Not inspected:** the other ~4,130 PNGs (no OCR available); pixel content of those is unverified. Whether the branches should be deleted is the owner's decision.
- Some build workflows currently cache or upload private app binaries, and public-source checkouts may involve tokens. Those workflows are **not certified as zero-exposure**. Do not move new private-source unit/security tests or real-user data into this repo until a separate threat assessment and isolation controls pass.
- Source-agnostic/synthetic tests (Maestro YAML validation, encryption self-test, no-secret guard) are appropriate for public CI. Full native evidence and runtime E2E require protected execution and secrets management, plus reviewed artifacts.
- An encrypted artifact remains publicly downloadable ciphertext. Confidentiality depends on the passphrase and authenticated encryption; do not share or reuse the passphrase outside the authorized team.

## Required follow-up before treating the pipeline as a release gate
Review old branch/artifact retention, cached binaries, logs and token privileges; validate an actual staged Android/iOS run with encrypted-only output; then configure required checks in a protected branch/release workflow. A green static test alone is **not** native QA certification.
