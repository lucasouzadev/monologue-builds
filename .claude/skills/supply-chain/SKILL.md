---
name: supply-chain
description: Dependencies, CI/CD, build provenance, release signing and update channels (app auto-update, OTA web bundles, store releases). Use when adding or upgrading a dependency, editing CI workflows, preparing a release, or touching any update mechanism.
---

# Supply chain and updates

Why: Software Supply Chain Failures entered the OWASP Top 10:2025 at #3 and Inadequate Supply Chain Security is M2 in the Mobile Top 10 2024. The update channel is the highest-privilege channel there is: it installs code on every client.

1. **Every dependency is third-party code running with your privileges.** Lockfiles committed, reproducible installs; SCA in CI; SBOM per release; adoption criteria (maintenance, popularity, permissions, install scripts, licence). *Essential (SCA + SBOM).*
2. **CI is part of the product.** Actions/plugins pinned by commit hash; minimal token permissions; no secrets in jobs triggered by untrusted PRs; workflow changes reviewed like code.
3. **Signed provenance.** SLSA Build L1 = provenance exists; L2 = signed by a hosted build platform; L3 = hardened, isolated build with signing secrets out of reach of user steps. Verify provenance when consuming artifacts. *Recommended (L2) / Advanced (L3, Source track).*
4. **Signed, verified, rollback-resistant updates.** The client checks signature **and** freshness before installing; rejects versions older than one already seen (rollback), detects expired metadata (freeze), caps download size (endless data). Offline signing keys separated by role, threshold signatures for critical ones. Staged rollout with controlled rollback. Applies to OTA web bundles in hybrid apps too. *Essential (signature + HTTPS) / Advanced (full TUF model).*
5. **Secrets** never in the repo or client: see `security-core` #8.

## Verify
- CI gate fails on known critical vulnerabilities (with a documented exception path).
- `git grep` for unpinned `uses:` lines; secret scanner in pre-commit and CI.
- An OTA bundle built for a newer native runtime is refused by older clients; an older bundle cannot replace a newer one.

## Gotchas
- A new dependency that adds native code changes the build, not just the bundle — tell the owner.
- "Just bump it" across a major version is a migration: read the changelog, run the full suite.

Sources: OWASP Top 10:2025 A03/A08; SLSA v1.1/v1.2; NIST SSDF PW.4, PS.4 (v1.2 draft); The Update Framework (TUF) security docs.
