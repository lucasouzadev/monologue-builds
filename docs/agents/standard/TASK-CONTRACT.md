# TASK-CONTRACT — Template for any non-trivial task

Use for issues, sub-agent briefs and roadmap items. A task without acceptance criteria is not ready.

```markdown
# TASK <ID> — <title>
Status: proposed | approved (<date>, by owner) | in progress | blocked | done
Goal (1–3 sentences, verifiable):
Context (why now):
In scope:            Out of scope:
Platforms / layers:
Dependencies & open decisions:
Files allowed to change:
Acceptance (observable, in numbers):
- [ ] ...
QUALITY-G1: surface · risks · tests designed · delivery · rollback
Risk class (P0–P3) and stop plan:
Tests: executed / not run (+reason)
User-visible change? changelog text:
Handoff: next owner, first next step
```

Rules: never widen scope to "improve" something the contract excludes; "done" needs evidence, not a commit; a draft spec is not permission to implement.
