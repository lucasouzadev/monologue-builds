---
name: security-core
description: Stack-agnostic security principles for any change to authorization, APIs, data handling, input/output, configuration or error handling. Use before planning or reviewing such a change, and when writing a threat model. Covers threat modeling, zero trust in the client, deny-by-default authorization (IDOR/BOLA, SSRF), injection, fail-closed defaults, least privilege, defense in depth and memory-safe constructions.
---

# Security core

Format per item: **principle** → why → how to verify → priority (Essential = day 1 · Recommended = real users or sensitive data · Advanced = high risk, regulation, scale). Sources and the OWASP Top 10:2025 map: [reference.md](reference.md). Process and metrics: [lifecycle.md](lifecycle.md).

1. **Threat-model before coding, and when the design changes.** Insecure design is not fixed by good code. Verify: data-flow diagram with trust boundaries and "what can go wrong / what do we do / did we do it right?" answered for every feature with data, auth, payment or integration; decisions recorded. Template: `docs/agents/standard/THREAT-MODEL.md`. *Essential.*
2. **The client is not trusted.** Binaries, JS bundles and WebViews can be read, changed and replayed; client-only checks are suggestions. Verify: every authorization, price, limit, quota and business state is re-applied on the server; a test that calls the API without the UI cannot bypass it. Obfuscation/anti-tamper only raise cost. *Essential.*
3. **Authorize every request, deny by default.** Broken access control is #1 and now includes SSRF. Verify: each endpoint checks identity **and** ownership of the resource; automated tests try another user's resource; outbound calls to user-controlled URLs go through an allowlist. *Essential.*
4. **Validate input, encode output at the point of use.** XSS in hybrid/desktop apps becomes native code execution. Verify: parameterized queries only; context-aware encoding (HTML, URL, shell, log); no `eval` or command building by concatenation; server-side allowlist/schema validation. *Essential.*
5. **Secure by default, fail closed.** Misconfiguration and mishandled exceptions are top-10 categories; defaults are what most users run. Verify: no default passwords; debug and verbose telemetry off in production; errors deny instead of allow; every flag that loosens security has a written justification. *Essential.*
6. **Least privilege everywhere** (code, people, tokens, OS permissions, CI). Verify: minimal token scope and lifetime; OS permissions requested at the moment of use; CI/cloud keys minimal; native bridges expose task-specific functions only. *Essential.*
7. **Defense in depth.** Every layer fails one day. Verify: each critical asset lists ≥ 2 independent layers (e.g. server validation + CSP + renderer sandbox). *Recommended.*
8. **Secrets never in the client or the repository.** Verify: secret scanning in pre-commit and CI; `strings`/grep of the final artifact finds no private key; client build-time env vars **are public**; secret-requiring operations go through a backend; rotation documented. *Essential.*
9. **Prefer constructions that remove whole bug classes.** Verify: new code parsing untrusted input in a memory-safe language when possible; safe-by-construction APIs (parameterized queries, auto-escaping templates); roadmap for legacy. *Recommended.*

## Gotchas
- Authenticated ≠ authorized: test object by object, user A ⇏ user B.
- Hiding a button is not access control.
- A listing query must filter by owner explicitly even when row-level security exists.
- "Temporary" disabling of TLS, sandbox or validation is never temporary.
- Related skills: `identity-session`, `data-privacy`, `supply-chain`, `platform-security`, `fundamentals-audit`.
