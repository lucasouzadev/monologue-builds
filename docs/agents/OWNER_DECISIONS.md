# OWNER_DECISIONS — monologue-builds

Dated log of the owner's standing instructions (format: `docs/agents/standard/OWNER-DECISIONS-TEMPLATE.md`). Newest first; never delete, mark `SUPERSEDED`. The current one-line rule lives in `AGENTS.md`. The full log of build/OTA authorizations lives in the private repo (`AGENTS.md`, `docs/agents/OWNER_DECISIONS.md`).

## 2026-11-08 — Canary per session, early compaction, security/performance skills (agent-kit 1.1.0)
Rule: the owner gives the form of address at the start of each session; agents use it in every reply, keep it only in the conversation, never store it. Auto-compaction at a 200k-token window (`autoCompactWindow`), statusline shows context use; handoff from 70 %. Security/performance skills: `security-core`, `identity-session`, `data-privacy`, `supply-chain`, `performance-core`, `platform-security` (CI repos: the security subset). Kit source: `lucasouzadev/agent-kit-skill`.

## 2026-11-08 — Agent docs standard
Rule: this repo follows agent-kit 1.0.0 (English agent docs, caveman replies in Portuguese, private-name canary in every chat reply, never stored in files).

## 2026-10-23 — Simulator/emulator builds have standing authorization
Quote: "Pode rodar as builds para simuladores… Eu só preciso autorizar as builds reais, as que EU uso."
Rule: CI-only simulator/emulator builds need no per-run permission (tell the owner when one starts); real builds (`build.yml`, TestFlight, store) need an explicit order per execution.

## 2026-10-20 — Economy loop, one agent
Rule: review → fix → small flow → targeted run; ≤ 5 flows per run; no sub-agent fan-out. Source: private runbook §3.2.
