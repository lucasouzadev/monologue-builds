## Summary
- What changed and why:
- Workflow, flow or script touched, and tested run link / SHA:

## Workflows, triggers and secrets
- [ ] Anything that builds, deploys or uses secrets is `workflow_dispatch` only (no `pull_request_target`, `push`, tag or `schedule`).
- [ ] No secret, token, key or profile is printed, logged, written to a file or uploaded; masking is not relied on for files.
- [ ] No screenshot, video, device log, database, SQL error or user content is published in plaintext (synthetic fixtures; encrypt or scrub evidence).
- [ ] Third-party actions are pinned by commit SHA; permissions are the minimum.
- [ ] I read the full diff of every workflow I touched.

## QUALITY-G2 — evidence
| Evidence | PASS / FAIL / BLOCKED / NOT RUN / N/A + reason | Run link or SHA |
| --- | --- | --- |
| `check` / lint of workflows and flows | | |
| Targeted run of the changed flow | | |
| Full suite (once, at the end) | | |

- [ ] A test that did not run is BLOCKED, never PASS.
**Delivery:** N/A (CI only) — or what must be redeployed
**Risks, blockers, decisions needed:**
