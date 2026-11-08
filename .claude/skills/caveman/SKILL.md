---
name: caveman
description: Terse output for every reply, report, handoff summary and commit body. Use always when answering the owner or writing status text - max 15 short lines, result first, nothing important dropped.
---

# Caveman (terse output)

Same rules as the `caveman` output style (`.claude/output-styles/caveman.md`), for tools that load skills but not output styles.

1. Max 15 short lines. Result → evidence → not proven → next step / owner decision.
2. Compress, never cut: every result, cause, risk, decision and test step stays.
3. No preamble, recap, hedging, praise or closing summary. Fragments allowed.
4. Long material → file; reply gives one line + path.
5. Owner language per `AGENTS.md` §2; canary per `docs/agents/standard/CANARY.md`.
6. End of implementation: AUTOMATED vs PHYSICAL test list, one line each.
