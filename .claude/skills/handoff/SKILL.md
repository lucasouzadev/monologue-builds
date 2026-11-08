---
name: handoff
description: Writes the session state file. Use before context compaction, when the context is getting large, at the end of every session, and whenever the owner approves a plan (to record the approval).
---

# Handoff

Template: `docs/agents/standard/HANDOFF-TEMPLATE.md`. Path: the session state file named in `AGENTS.md`.

1. **Replace** the file, never append. Target ≤ 1k tokens.
2. Keep only active state: goal + approval (date, exact scope), state split Implementation / Merge / Production / QA with evidence, decisions and why, files touched, exact next step, risks and owner decisions pending.
3. Verify before writing: git branch/SHA, PR state, real command results. Never write "done" for open PRs, unconfirmed deploys or pending QA.
4. Fix rounds: defect class, recurrence, owner module, guard, ledger updated.
5. No secrets, personal data or canary value.
6. Reply to the owner: one line with the path.
