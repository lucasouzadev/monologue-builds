# QUALITY-GATES — Two checkpoints in every task

Applies to fixes, features, refactors, specs, plans, backend and infra work. Gates do not authorize edits before owner approval, nor builds, nor turn a merge into a deploy. Projects append their concrete matrix (viewports, devices, commands) in their own gates doc.

## States
PASS (evidence available) · FAIL (open a fix) · BLOCKED (needs permission, tool, device or decision) · NOT RUN (applicable but not executed — never PASS) · N/A (out of scope, with an objective reason).

## QUALITY-G1 — before the final plan or any code
1. **Surface map:** routes/screens/components, UI states (loading, empty, error, success, offline), platforms, APIs, data/schema, jobs, CI, release channel; existing consumers and neighbouring flows.
2. **Visual contract** (if UI): design system tokens, typography, contrast, themes, i18n, focus/keyboard, sheets/menus, motion, safe areas.
3. **Presentation matrix:** the project's viewports/devices, orientations, zoom/large text, long content. Emulation does not prove native behaviour.
4. **Edge cases:** long strings, emoji/accents, slow network, expired session, large upload, empty and huge lists, back/deep link, resume from background.
5. **Risk map:** authZ (user A ⇏ user B), input/output validation, secrets, dependencies, concurrency, idempotency, retries, schema compatibility, cost, performance. Money/limit/webhook → skill `fundamentals-audit`. Reference OWASP ASVS (web/API) and MASVS (mobile).
6. **Tests designed before the solution:** unit/integration, E2E per platform, named screenshots, measurable acceptance, performance baseline, rollback.
7. **Release impact:** delivery channel, compatibility with clients already in the field; merged ≠ deployed ≠ verified.

A plan without a G1 section is not ready to implement.

## QUALITY-G2 — before saying Done, asking to merge or publishing
1. Self-review the diff: debug leftovers, duplication, overflow, clipping, z-index, alignment, keyboard and safe areas.
2. Run the canonical checks and the E2E flows of the change; screenshots per viewport/theme/locale, **opened and read** (a passing run without looking at images is not visual proof).
3. Native surfaces: real build/runtime flows on each affected platform, or `BLOCKED (native validation)`.
4. Data/backend: migration from the previous version, cross-user denial, input validation, retries/timeouts, partial failure, log sanitization.
5. Performance & security: baseline vs after in the same environment; dependency audit; zero secrets in the client bundle.
6. Delivery: CI result (real), rollout/rollback, post-deploy smoke; never "in production" from a merge alone.

## Risk classes
P0 critical (data exposure, auth bypass, published secret, irreversible loss) — stop and escalate. P1 high (essential function broken or inaccessible, cross-tenant leak, untested critical path) — no release. P2 moderate. P3 cosmetic. Waivers only from the owner, with scope, deadline and mitigation; never for P0, legal duty or exposed secret.

## Evidence record (per task, in the project's QA folder)
Change/SHA · G1 summary · web E2E · native E2E · data/backend · performance · release · defects (P0–P3, retest, owner of BLOCKED items). No PII or secrets in evidence.
