# SECURITY-PERFORMANCE — Stack-agnostic invariants

Core only, always applicable. Detail lives in on-demand skills: `security-core`, `identity-session`, `data-privacy`, `supply-chain`, `performance-core`, `platform-security` — anchored on OWASP Top 10:2025, ASVS 5.0, MASVS v2.1, NIST SP 800-63-4, SSDF, SLSA, Core Web Vitals, Android vitals and Apple hang metrics.

1. **The client is hostile.** Authorization, validation and business rules (price, quota, limits, state) always on the server. No secret in binary, bundle, client env vars or repository.
2. **Every trust boundary receives hostile input** (native bridge/IPC, deep link, WebView, dependency, update, webhook): minimal surface, validation, deny by default.
3. **Secure by default, fail closed.** Never disable TLS, sandbox, isolation or validation "temporarily".
4. **Data:** collect the minimum; secrets in the OS vault; never log tokens, passwords, session IDs or sensitive PII.
5. **Dependencies and updates are third-party code:** lockfile, scan, SBOM, signed artifacts and updates with anti-rollback; CI actions pinned.
6. **Measure before optimizing:** real-user data, p75/p95, modest device, bad network. No number, no optimization.
7. **UI thread is sacred:** respond in ~100 ms, tasks ≤ ~50 ms, ~16 ms per frame; I/O and heavy work off it.
8. **Do less, load on demand;** keep budgets (bundle, startup, INP/hang, memory) and fail CI when they break.
9. Touching auth, data, network, dependencies, WebView/IPC, update or critical UI → load the matching skill/doc before coding.
10. Security vs convenience in doubt → state the trade-off, ask, record the decision.

Public thresholds: LCP ≤ 2.5 s · INP ≤ 200 ms · CLS ≤ 0.1 (p75) · Android crash < 1.09 % · ANR < 0.47 % · cold start < 5 s · iOS hang ≥ 250 ms reported, > 500 ms severe. Treat them as external floors; set stricter internal targets.
