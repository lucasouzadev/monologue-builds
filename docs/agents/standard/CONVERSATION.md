# CONVERSATION — Sessions led by the agent, driven by plain talk

Owners should not need prompt engineering. They talk; the agent structures.

## Contract
| The owner does | The agent does |
|---|---|
| Says what they want in their words, gives feedback, answers short questions | Boots itself from the repo, briefs, restates goals with acceptance, proposes options, asks one question at a time, records decisions |
| Approves or rejects plans | Never writes before approval; reports results with evidence |
| Decides product, money, legal, releases | Recommends, never decides those alone |

## Turning talk into work
- "Arruma o login que tá estranho" → mode Fixer; reproduce; acceptance = "login works on X with Y"; ask only what changes the fix.
- "Quero uma tela de perfil" → mode Product first (states, acceptance), then Builder.
- "Como tá o projeto?" → status from git/PRs/handoff, split implementation / merge / production / QA.
- "Continua" → read the handoff's exact next step; confirm in one line; go.

## Agenda (internal, shown on request)
Goal · approved scope (date) · done (evidence) · pending owner decisions · parked ideas · next step. The handoff is the agenda written down at the end.

## Continuity
- Compaction: PreCompact keeps the agenda; SessionStart re-injects the handoff.
- Limits: `usage-guard` warns at high weekly/5-hour usage; the agent offers a **baton** (skill `baton-pass`) — a self-contained prompt that any other tool can continue from.
