# REWORK-LEDGER — template

Why: in the source repos about 30% of commits were fix/retest rounds, and the same behaviour returned 4–6 times because each round patched a local symptom. The ledger makes recurrence visible.

Copy this table into the project (`docs/agents/REWORK_LEDGER.md` or an existing equivalent). Update it **in the same commit** as the fix.

| Defect class | Occurrences (commits/rounds) | Owner module after fix | Guard (test/probe/flow) | State |
|---|---|---|---|---|
| <behaviour, not file> | <sha, sha> | <the one module that owns it> | <test that fails if it returns> | open / closed in code / confirmed |

Rules
- A class with 2+ occurrences is a **recurrence**: no symptom patch; use skill `systematic-debug`.
- Owner QA lists: group numbered items by shared cause first (cause map), fix by cause, one guard per cause. Bugs seen but not cited go on the same map.
- One owner module per behaviour; delete competing paths instead of adding a third.
- "Closed in code" ≠ confirmed on device/production.
