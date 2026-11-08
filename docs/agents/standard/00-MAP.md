# 00-MAP — What to read, when

Why: measured boots in the source repos cost 12k–88k tokens before any work, and that cost is paid again after every compaction. Read by task. If a project doc and this map disagree, the project doc wins.

## Tier 0 — always (target ≤ 10k tokens)
1. `AGENTS.md` (entry point, ≤ 120 lines).
2. The session state file (`HANDOFF.md` or the task's handoff), ≤ 1k tokens.
3. One mode from `MODES.md`.

## Tier 1 — by task (open only your row)

| Task | Read |
|---|---|
| Choosing what to do next | project STATUS file |
| Bug, regression, "broke again" | `MODES.md#fixer`, skill `systematic-debug`, `REWORK-LEDGER` of the project |
| Feature | `MODES.md#builder`, `TASK-CONTRACT.md`, `QUALITY-GATES.md` |
| Product question, scope, acceptance | `MODES.md#product` |
| Architecture, schema, auth, deploy, rollback | `MODES.md#architect`, `THREAT-MODEL.md`, skill `security-core` |
| Login, tokens, sessions, MFA, OAuth | skill `identity-session` |
| Storage, encryption, PII, logs, analytics | skill `data-privacy` |
| Dependency, CI/CD, release, auto-update/OTA | skill `supply-chain` |
| UI, lists, network, startup, perf regression, budgets | skill `performance-core` |
| Platform code, deep links, IPC, WebView, headers/CSP | skill `platform-security` |
| Native builds, simulators/emulators, OTA, TestFlight, Maestro, no device/Mac available | skill `ci-device-lab` |
| Map an area before touching it | `MODES.md#lens` |
| Money, quota, invite, webhook, concurrency, "is it safe?" | skill `fundamentals-audit` |
| Any screen, control, sheet, list, motion | skill `ux-check` + project UX/design docs |
| Plan with several tasks / parallel work | `ORCHESTRATION.md` |
| Risky or irreversible action | `SAFEGUARDS.md` |
| User-visible change | `CHANGELOG-GUIDE.md` |
| Closing / handing off | `DONE.md`, `HANDOFF-TEMPLATE.md`, skill `handoff` |
| Context growing, vague request | `CONTEXT-BUDGET.md`, skill `session-preflight` |
| Session start, casual/feedback message, unsure owner | skill `session-guide`, `CONVERSATION.md` |
| Usage limit near, switching tool/session | skill `baton-pass` |

## Tier 2 — only when the task names it
ADRs, old handoffs, design captures, QA evidence, research and audit documents. Never open them "for context".

## Reading discipline
- Search before opening (`rg -n "<symbol|heading>"`), then read the line range. Batch independent reads.
- Never paste whole files or long logs into the conversation; quote the failing lines and the command.
- Stop reading the moment you can act.
