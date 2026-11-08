# ORCHESTRATION — Sub-agents without losing work or money

Use only when the plan is approved and has more than 2–3 tasks, or the owner asks to parallelize. Projects may forbid fan-out (e.g. "one agent" economy loops); the project rule wins.

## Slicing
1. One task = one verifiable result: few files, one validation command, one acceptance criterion. "And also" means two tasks.
2. Never delegate migrations, auth/RLS, deploys, secrets or anything irreversible. The approval gate binds sub-agents too.
3. Parallel only on disjoint file sets or isolated worktrees. Shared files (i18n, plans, entry docs) are touched by one agent at integration.
4. State on disk, not in the sub-agent's head: plan checkboxes and handoff updated before long tasks.
5. Checkpoint each verifiable step (validation run; small commit if commits are authorized).

## Brief
```
GOAL        <1 sentence>
CONTEXT     <paths: plan task, spec section, likely files> — do not paste content
DO / DON'T  <limits; "do not touch X">
ACCEPTANCE  <measurable>
VALIDATE    <exact commands>
RETURN      <diff summary, commands run with real output, risks, what was NOT done>
IF STUCK    <stop and describe; never improvise outside scope>
```

## Verification (by the coordinator)
Read the diff, not the summary. Re-run the canonical checks yourself. Compare counts with a baseline from a clean parent commit. Summary ≠ diff, a test "adjusted to pass", or files outside the list → send it back.

## When a sub-agent drops
`git status` + `git diff`: finished and coherent → review and validate; partial → continue or relaunch only the rest with a smaller brief; useless → discard and relaunch smaller.

## Model choice
Cheaper/faster models for search and mechanical edits; the strongest model for design, concurrency, auth, money and final review.
