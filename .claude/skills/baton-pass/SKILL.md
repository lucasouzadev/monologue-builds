---
name: baton-pass
description: Generates a self-contained continuation prompt ("baton") so work can resume in another session, IDE, model or platform without losing context. Use when plan or session usage is high (weekly/5-hour limit near), when the context is about to be compacted and the owner wants a fresh start, when switching tools, or whenever the owner asks to "pass the baton", "continue elsewhere" or "generate a continuation prompt".
---

# Baton pass

Why: limits end sessions mid-task, and a new tool starts blind. A baton is the handoff written for a reader that has **no** access to this conversation, these skills or this machine — only the repository.

## When to offer
- The `usage-guard` hook reports weekly ≥ 85 % (or 5-hour ≥ 90 %): finish the current answer, then one line: *"Uso semanal em X %. Quer que eu gere o prompt de continuidade?"* (in the owner's language). Never stop work on your own because of usage.
- Before an intentional tool/session switch, or when the owner asks.

## Steps
1. **Verify the state** (do not write from memory): branch, last commit, `git status`, open PR, the result of the last real command, pending approvals.
2. **Update the handoff file** first (skill `handoff`) so the repository holds the same state.
3. **Write the baton** with the template below. Self-contained, ≤ 60 lines, plain Markdown, no tool-specific syntax (no slash commands, no skill names as instructions).
4. **Deliver** it in one fenced block in the chat (the only allowed exception to the 15-line limit) and, if the session allows, save a copy under the scratchpad/temp folder — never commit it.
5. **Never include** secrets, tokens, keys, personal data, the canary value, or internal URLs that grant access.

## Template
```markdown
# Continue: <project> — <task>
You are continuing work started in another session. Read before acting:
1. `AGENTS.md` (rules: approval before writing, evidence states PASS/FAIL/BLOCKED/NOT RUN, no secrets in chat) and `<handoff path>`.
2. `git fetch && git log --oneline -10 origin/<default>`; branch `<branch>` at `<sha>`; PR <#n | none>.

## Goal
<one line> — approved by the owner on <date>: <exact scope>. Anything beyond it needs a new approval.

## Done (with evidence)
- <item> — <command/result or file>

## In progress / exact next step
<the first concrete action, with file paths>

## Decisions already made (do not reopen)
- <decision> — why

## Open questions for the owner
- <question> (options, recommendation)

## How to verify
<commands that must pass; what to look at>

## Talk to the owner like this
Short replies (≤ 15 lines), result first, in <owner language>. Ask the owner how to address them.
```

## Gotchas
- A baton that says "continue where we left off" is useless: name files, commands and the next action.
- Approvals do not transfer silently: state exactly what was approved and that new scope needs a new "yes".
- If the work is uncommitted, say so first and commit/push (when allowed) before handing off — the next tool only sees the repository.
