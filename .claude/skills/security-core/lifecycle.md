# Secure and performant lifecycle

| Stage | Principle | Verify | Priority |
|---|---|---|---|
| Requirements | Security level and performance budgets defined before building | ASVS level / MASTG profile chosen; budgets written | Essential |
| Design | Threat model per relevant feature | Diagram + threats + mitigations recorded | Essential |
| Code | Review with security/performance checklist; SAST on PR | No merge with an open high finding | Essential |
| Dependencies | SCA + SBOM + adoption policy; secret scanning | CI gate; SBOM per release | Essential |
| Build | Signed provenance from a hosted build platform | SLSA Build L2 (L3 advanced) | Recommended |
| Security tests | DAST/API in staging; authorization tests; MASTG on mobile; periodic pentest | Reports with fix deadlines by severity | Recommended |
| Performance tests | Benchmarks in CI; modest device and slow network | Budget gate | Essential |
| Release | Staged rollout/canary with rollback and anti-rollback | Vitals watched before 100% | Recommended |
| Operation | Observability: RUM, crash/ANR/hang, security logs with alerts | Actionable alerts with an owner | Essential |
| Response | Incident plan, vulnerability disclosure channel, secret rotation | Periodic drill; published VDP | Recommended |

## Minimum dashboard
| Area | Metric | Public target |
|---|---|---|
| Web | LCP / INP / CLS at p75 | ≤ 2.5 s / ≤ 200 ms / ≤ 0.1 |
| Android | User-perceived crash / ANR (% DAU) | < 1.09 % / < 0.47 % (8 % per device model) |
| Mobile | Cold / warm / hot start | "Excessive" ≥ 5 s / ≥ 2 s / ≥ 1.5 s |
| iOS/macOS | Hang rate | ≥ 250 ms reported; > 500 ms severe |
| Any UI | Response / task / frame | ~100 ms / ~50 ms / ~16 ms |
| Security | Time to fix a critical vulnerability | By policy; track the trend |
| Security | Days between upstream patch (runtime/WebView/OS libs) and your release | Lower is better |
| Security | Secrets found in repo/artifacts | Zero |
| Supply chain | Releases with SBOM and signed provenance | 100 % |
| Identity | Users with a phishing-resistant factor | Growing |
