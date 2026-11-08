---
name: ci-device-lab
description: Offers and sets up a "device lab in CI" - GitHub Actions workflows that build and test mobile/web apps on hosted simulators and emulators, package installable builds (Android APK, iOS simulator app, TestFlight), publish Expo OTA updates, build with or without Expo/EAS, and run Maestro E2E flows. Use when the owner lacks a Mac, physical devices or spare machines, when native builds or device testing are needed, when Actions minutes run out, or when asked about CI builds, simulators, emulators, OTA, TestFlight or Maestro.
---

# CI device lab

Why: many people have one computer and one phone (or none of the right kind). Hosted runners give them an Android emulator, an iOS simulator on macOS, signing and store upload — triggered from a browser, readable by an agent. Offer this whenever a task needs a device, a Mac or a native build the owner cannot run locally.

## When to offer (one short question, recommendation first)
- No Mac → iOS simulator build, Maestro on simulator, TestFlight upload all run on `macos-*` runners.
- No Android device / weak machine → emulator + Maestro on `ubuntu-*` with KVM.
- Private repo out of Actions minutes → **public CI repo** that clones the private source read-only (standard hosted runners are free for public repos; confirm current GitHub pricing before promising it).
- Needs proof on "a phone" → screenshots/recordings as artifacts (encrypted or scrubbed when the repo is public).

## Setup flow (approval gate applies at each step)
1. **Pick the layout** ([architecture.md](architecture.md)): same repo (private, uses minutes) or private source + public CI repo (free minutes, stricter rules).
2. **Pick capabilities** and copy only those templates from `templates/` (table in [recipes.md](recipes.md)): Android debug APK · iOS simulator build · E2E Android · E2E iOS · Expo OTA · Expo/EAS build (cloud or `--local`) · bare Gradle/Xcode build · TestFlight · deploy jobs.
3. **List the secrets by name only** ([secrets.md](secrets.md)): what each is for, where the owner gets it, how to encode it. The owner pastes values **in GitHub → Settings → Secrets and variables → Actions**, never in the chat. If a value appears in the chat anyway: do not repeat it, tell the owner to rotate it.
4. **Harden the repo** (architecture.md §Hardening) before the first secret is added.
5. **First run small:** `workflow_dispatch` with the smoke flow only; read the job summary and failing screenshot; fix selectors; then widen. Expect selector tuning on the first real Maestro run.
6. Record the workflows, inputs and secret names (never values) in the project's `AGENTS.md` / runbook.

## Non-negotiables
- **Everything is `workflow_dispatch`.** No `push`, `pull_request_target`, `schedule` or tag triggers on workflows that hold secrets or produce builds. A secret-free lint/check job may run on PRs.
- **Real builds only on the owner's explicit order per execution** (TestFlight/store/signed builds email testers and reach real devices). Simulator/emulator builds for tests may get standing authorization if the owner says so.
- **Public repo = public logs and artifacts.** No screenshots, videos, device logs, databases, user content or SQL errors in plaintext: encrypt (`templates/scripts/encrypt-artifact.mjs`) or scrub. Synthetic fixtures and a dedicated empty test account only.
- **Least privilege:** read-only deploy key to the private repo; signing/upload secrets in protected Environments with a required reviewer; actions pinned by commit SHA.
- **Never print, echo, decode to logs, or commit** a secret, keystore, `.p8`, provisioning profile or token. Masking protects logs only, never files.
- A test not run is BLOCKED; a passing run without opening the screenshots is not visual proof.

## Safe guidance for beginners
- Explain each secret in plain words and what happens if it leaks; offer the safest option first (SSH deploy key over token; separate signing key for public debug APKs; App Store Connect API key with the minimum role).
- Never ask the owner to run commands that delete, revoke, publish or pay without saying exactly what they do; never suggest disabling security settings to make a run pass.
- Store-account actions (certificates, app records, submissions, billing) stay with the owner.

Troubleshooting: [troubleshooting.md](troubleshooting.md). What has and has not been verified on real runners: [VERIFIED.md](VERIFIED.md) — be upfront with the owner that the first run usually needs tuning.
