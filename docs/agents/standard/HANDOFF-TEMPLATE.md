# HANDOFF template — the session state file

The handoff is **active state**, not history. **Replace** it; never append. Target ≤ 1k tokens. Write it before compaction and at the end of every session. The `SessionStart` hook re-injects it after `/compact` and on resume.

```markdown
# HANDOFF — <date> — <task ID / topic>

## Goal
<one line> — approved <date> by owner: <exactly what was approved>

## State (verified, with evidence)
- Implementation: done / partial (<what>) — branch `<b>`, SHA `<sha>`
- Merge: PR #<n> open | merged <date> | none
- Production: deployed + verified <how> | not confirmed
- QA: automated <PASS/FAIL/BLOCKED + command> · physical <pending items>

## Decisions (and why)
- ...

## Files touched
- path — why

## Next step (exact, first action)
...

## Risks / blocked / owner decisions needed
...

## Fix rounds only
Defect class · recurrence? · owner module · guard added · ledger updated
```

Never: "continue where I left off", secrets, personal data, the canary value.
