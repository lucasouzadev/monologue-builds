---
name: intent-compiler
description: Silently turns the owner's plain, casual message into an effective internal brief (goal, context, acceptance, constraints, mode, skills, output) before acting - the owner never writes or sees a prompt. Use on every owner message that asks for work, feedback or a decision; skip pure approvals ("pode", "sim") and slash commands.
---

# Intent compiler (invisible)

The owner talks like in a meeting. You turn that talk into the prompt a prompt engineer would have written — **for yourself**, before acting. Rubric and examples: [rubric.md](rubric.md).

## Compile (in your head or scratch, never in the reply)
```
GOAL        verb + observable result, one line
CONTEXT     what the owner said + what the repo says: handoff, last commits, files/screens named or implied
            (search to resolve "aquilo", "a tela nova", "o bug de ontem"); quote the owner's words for intent
ACCEPTANCE  how we both know it is done, in numbers or visible behaviour
CONSTRAINTS AGENTS.md rules that apply (approval gate, build/release rules, design system, security)
OUT OF SCOPE what not to touch, even if tempting
MODE        Fixer | Builder | Product | Architect | Lens | Auditor | Status
SKILLS      the 1–3 skills/docs to load (e.g. systematic-debug, ux-check, security-core)
UNKNOWNS    only what changes the result and the repo cannot answer → at most ONE question
OUTPUT      what the owner gets back: plan for approval | answer | status | evidence
```

## Then act on the brief
- Enough to act → do the next step (the approval gate still applies before any write).
- One blocking unknown → ask it as a multiple-choice question, recommendation first. Fill everything else with stated defaults ("assumi X; se não, diga").
- Restate only GOAL + ACCEPTANCE to the owner, in one line, when the task is non-trivial. The rest of the brief stays invisible.
- The brief is not stored in files; GOAL + ACCEPTANCE + approvals go to the handoff when the session closes.

## Never
Show the brief unless the owner asks ("mostra o brief", "como você entendeu?"). Ask the owner to rephrase as a prompt. Invent context the repo does not confirm — mark it as an assumption.
