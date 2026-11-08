# Rubric and examples

Built on prompt-engineering practice (clear goal, relevant context, explicit constraints, success criteria, output format, one canonical example over many rules).

## Quality checklist for a brief
- GOAL is testable; no "improve", "fix stuff".
- CONTEXT names real files/screens/commits found by searching, not guessed.
- ACCEPTANCE is observable (numbers, a screen state, a passing command).
- CONSTRAINTS cite the rule, not paraphrase it vaguely.
- Exactly one MODE; at most three SKILLS.
- UNKNOWNS ≤ 1 question; everything else has a declared default.

## Examples (owner's words → brief, abbreviated)

**"o login tá estranho no celular"**
GOAL fix the mobile login defect · CONTEXT handoff mentions auth refactor `a1b2c3`; `LoginScreen.tsx`, `useSession.ts` · ACCEPTANCE login succeeds at 360 px, keyboard does not cover the button, no console error · CONSTRAINTS approval before edit; reproduce first · MODE Fixer · SKILLS systematic-debug, ux-check · UNKNOWNS "estranho" = layout or failure? → check screenshots/logs first; ask only if both look fine · OUTPUT cause + smallest fix plan.

**"queria que desse pra exportar as notas"**
GOAL let users export notes · CONTEXT no export code exists (searched); notes stored in `notes` table · ACCEPTANCE user exports all notes to a file and reopens it · CONSTRAINTS new feature → spec + approval; privacy of exported data · MODE Product → Builder · SKILLS data-privacy · UNKNOWNS format → ask: "Markdown (recomendado), PDF ou JSON?" · OUTPUT short spec with states for approval.

**"como tá?"**
GOAL status · CONTEXT git log, open PRs, handoff · ACCEPTANCE status split implementation/merge/production/QA · MODE Status · OUTPUT ≤ 10 lines.

**"continua"**
GOAL execute the handoff's next step · CONTEXT handoff "Next step", approval recorded? · CONSTRAINTS if the approval does not cover it, ask · OUTPUT one-line confirmation, then work.
