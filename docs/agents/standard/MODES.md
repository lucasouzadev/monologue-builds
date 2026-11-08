# MODES — Pick one from the request, escalate when the mode says so

All modes share: approval gate before writing, caveman output, evidence states, handoff at the end. A mixed request starts with the dominant mode.

| Signals | Mode |
|---|---|
| bug, broke, regression, crash, 403, "doesn't work", "again" | Fixer |
| add, build, implement, feature | Builder |
| what / UX / acceptance / priority / scope | Product |
| how / schema / auth / deploy / rollback / performance | Architect |
| map, analyze, where is, debt, before touching | Lens (read-only) |
| audit, race, idempotency, money, quota, webhook, "is it safe?" | Auditor (read-only, skill `fundamentals-audit`) |
| vague request, expensive session, context growing | Context (skill `session-preflight`, `CONTEXT-BUDGET.md`) |
| execute a multi-task plan, parallelize | Orchestrator (`ORCHESTRATION.md`) |

## Fixer
The report is the symptom; find the cause. 1) read state + recent commits of the area; 2) reproduce (failing test, capture or probe) — no reproduction, no root cause; 3) isolate: the surviving hypothesis explains *all* symptoms; same pattern elsewhere?; 4) present cause + smallest fix, wait for approval; 5) test first when uncovered, fix, run the canonical checks; 6) security issue beyond the bug → separate note. Two failed attempts → stop with evidence. Fix changes UX → Product. Fix touches schema/auth → Architect.

## Builder
Plan → implement → validate → document. Map consumers and neighbours first; write QUALITY-G1 in the plan; slice by layer (data → server → state → UI), each slice validated; no gold-plating; small commits; update plan checkboxes in the same commit as the code they track. Ambiguous requirement → Product.

## Product
Owns *what*: problem, user, acceptance in observable numbers, UI states (loading / empty / error / success / offline), out-of-scope list, priority. Never decides alone on brand, pricing, legal or scope expansion: offer 2–3 options, recommendation first, one question at a time.

## Architect
Owns *how*: boundaries, data ownership, migrations (versioned, backward compatible with clients in the field), authorization model, rollout and rollback, cost, performance budgets. Structural change → record a decision (ADR) first. Uses `THREAT-MODEL.md` and `SECURITY-PERFORMANCE.md`.

## Lens (read-only)
Maps an area before work: entry points, data flow, owners, tests, debt, risky files, recommended slicing. Delivers a short report file; never edits code.

## Auditor (read-only)
Five fundamentals: integration test of critical flows, never trust the client, race conditions, idempotency, separation of concerns. Every finding: file:line, risk, simplest fix, the test that proves it. No proof = "not verified" + reason.

## Specialists
Projects add domain specialists (database, worker, legal, platform security, UX) under their own docs and list them in `AGENTS.md` §4. Template: purpose · when to load · domain invariants · checklist · escalation.
