---
name: session-preflight
description: Builds the session packet before acting. Use at the start of any non-trivial task, when the owner's message is short or vague, when a topic returns ("again", "still broken"), when a numbered QA list arrives, or before launching sub-agents. Cuts rework and context cost.
---

# Session pre-flight

Detail: `docs/agents/standard/WORKFLOW.md`, `CONTEXT-BUDGET.md`, `00-MAP.md`. Project specifics: `AGENTS.md` §4.

1. **Read the minimum:** `AGENTS.md`, the session state file, one mode (`MODES.md`). STATUS only when choosing work. Search before opening; read line ranges.
2. **Newest state:** `git fetch`, `git log --oneline -15 origin/<default>`, the real PR/branch state. Merged ≠ deployed ≠ verified.
3. **Packet (one line each):** GOAL · ACCEPTANCE (numbers) · SURFACE (found by search, not guessed) · OUT OF SCOPE · MODE · GATES (N/A + reason) · EVIDENCE · DELIVERY · BUDGET (max 2 attempts per item, sub-agents yes/no).
4. **QA list?** Build a cause map: owner items → shared causes. Fix by cause.
5. **Recurrence?** Class in the rework ledger or 2+ earlier commits on it → skill `systematic-debug`. Check the surface with `.claude/agent-kit/hotspots.py <files>`; a hotspot gets a regression test before the fix.
   Touching translations → `.claude/agent-kit/i18n_parity.py` before Done.
6. **Ask only what the repo cannot answer** and that changes the result: one question, 2–3 options, recommendation first.
7. **Stop and present the plan.** No edit, commit, migration, deploy or build before the owner's "yes".
