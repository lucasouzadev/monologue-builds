---
name: pr-quality
description: Writes and self-reviews pull requests with honest quality evidence (QUALITY-G1 before, QUALITY-G2 before Done/merge), lints the PR description locally, and explains CI "pr-quality" failures. Use when opening or updating a PR, before saying a change is Done, when reviewing a PR, or when the pr-quality check fails.
---

# PR quality

Why: "done" without evidence and tests reported as passed when they never ran are the costliest recurring failures. The PR is where that is checked, by the author and by CI.

## Before opening the PR (the author, human or agent)
1. **Self-review the diff** (QUALITY-G2 step 1): debug leftovers, duplication, secrets, overflow/clipping, unrelated changes. Smaller is better; split if it mixes root causes.
2. **Run the real checks** and record each as `PASS`, `FAIL`, `BLOCKED`, `NOT RUN` or `N/A`, always with evidence (command, SHA, run link) or a reason. Never write PASS for something not executed; open and read screenshots before citing them.
3. **Fill the template** (`.github/PULL_REQUEST_TEMPLATE.md`): summary and tested SHA; G1 boxes; the G2 table; one delivery channel; risks and decisions needed. Keep it short and factual.
4. **Lint it locally** (offline): save the description to a file and run
   `python3 .github/scripts/pr_quality.py --body-file PR.md --git-base origin/<default>`
   Fix every ❌; read every ⚠️ (risk areas are reminders, not verdicts).
5. **Distinguish** implementation · PR/merge · deploy · production-verified. Never write "in production" because of a merge.
6. The owner merges; an agent never merges on its own.

## Reviewing a PR
Read the diff, not the description. Check each claimed PASS has evidence you can open; look at areas flagged ⚠️ (workflows, hooks, migrations, dependencies, native shell, auth). A green `pr-quality` check only means the PR is well-formed and honest-looking: it does not prove correctness.

## When the CI check fails
It lists each failure. Typical fixes: fill the unfilled table rows; add a reason after BLOCKED / NOT RUN / N/A; add evidence next to PASS; keep only the delivery option that applies; remove placeholders; delete anything that looks like a secret (and rotate it at the source). The script and config come from the **base** branch, so changing them in the same PR does not help: change them in a separate, reviewed PR.

## Tuning
`.github/pr-quality.json` overrides the defaults (headings, states, delivery channel, extra rules/areas). Public CI repos use the CI variant (`pr-quality.ci.json`). Standing project rules belong in that file, not in this skill.
