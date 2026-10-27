# AGENTS.md — monologue-builds (PUBLIC repository)

This repository holds CI only: native builds, OTA and Maestro E2E for the private `lucasouzadev/monologue` app. It contains **no app source**. Everything here, including workflow logs
and artifacts, can be read by anyone. The rules that govern the work live in the private repo: `AGENTS.md`, `docs/agents/TOOLING_AND_E2E_RUNBOOK.md`, `docs/agents/QUALITY_GATES_2026-10-14.md`.

## Never, in this repository
- Print, echo, log or commit a secret, token, passphrase, `.p8`, keystore, provisioning profile, or anything decoded from them. Masking protects logs only, never a file.
- Upload or publish raw screenshots, videos, logcat/syslog, databases, user notes, drafts or images. Evidence is encrypted (`SECURE_QA_ARTIFACTS.md`: AES-256-GCM, `visual-evidence.tgz.enc`).
  The README line saying screenshots are force-pushed to `screens-android` / `screens-ios` is **outdated**; `SECURE_QA_ARTIFACTS.md` wins.
- Add `pull_request`, `pull_request_target`, `push`, tag or `schedule` triggers to a workflow that uses secrets or starts a build. Everything here is `workflow_dispatch`; `quality-static.yml` (no secrets) is the only PR trigger.
- Start a **real native build** (`build.yml`: APK/IPA, TestFlight, store) without the owner's explicit order for that execution. Simulator/emulator-only builds for CI test runs have standing authorization; tell the owner when one starts. OTA to a compatible baseline needs no extra permission.
- Change a workflow "just to see": a workflow editor can read its secrets. Workflow changes go through a PR and a read of the diff.

## Working rules (from the private runbook §3.2)
- Newest state first (`tools/ci.sh`, latest runs); validate on `preview` before `development`; at most 5 flows per run; read the RESULT/STEP lines and the failing screenshot before re-running; the full suite once, at the end.
- One agent, no sub-agent fan-out. A run that exceeds its estimate is read (job steps), not blindly cancelled.
- A test that was not run is `BLOCKED`, never `PASS`.
