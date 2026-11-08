# DONE — Definition of done

Done only when every applicable item is ✓ or `N/A (reason)`. Blank = not checked. Anything else is WIP.

**Code** — canonical checks green for every touched package · diff read (no debug logs, dead imports, unjustified `any`, PII).
**Security** — authorization enforced on the server, A ⇏ B tested for data changes · no secret in client/bundle/repo · uploads validated (size, type, sanitized path) · security/trust copy matches the code.
**Product/UX** — UI states (loading, empty, error, success, offline) · themes · i18n for every user-facing string · design tokens only · UX checklist walked; broken rule named in the handoff.
**Tests** — happy path · neighbours without regression · acceptance edge cases · integration test for flows with money, limits, permissions or other users' data · race / idempotency / tampered client value when read-decide-write · bug fix has a test that failed before.
**Release** — migrations versioned and backward compatible · delivery channel declared · compatible with clients in the field · rollback written for medium/high risk.
**Docs** — handoff replaced · plan checkboxes · changelog for user-visible change · rework ledger row for fixes of a known class.
**Gates** — QUALITY-G1 recorded · QUALITY-G2 executed with evidence · no open P0/P1 · nothing FAIL/BLOCKED while calling it Done.

PR open ≠ merged. File written ≠ feature delivered. Merged ≠ in production.
