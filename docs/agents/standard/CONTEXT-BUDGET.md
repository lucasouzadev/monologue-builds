# CONTEXT-BUDGET — Spend fewer tokens, lose nothing

## Budgets (targets, not laws — if exceeded, trimming is part of the task)
| Item | Target |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | ≤ 120 lines / ≤ 4k tokens |
| Session state file | ≤ 1k tokens |
| Any agent doc | ≤ 2k tokens; split or move history out of the boot path |
| Skill body | ≤ 60 lines; detail in a referenced doc one level deep |
| Reply to the owner | ≤ 15 short lines |

## Automatic mechanisms (Claude Code, committed in `.claude/`)
- `outputStyle: caveman` — terse replies by default (`keep-coding-instructions: true`, so engineering behaviour is kept).
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` in `settings.json` `env` — compacts earlier, before quality degrades. Can only lower the threshold. If a Claude Code version ignores it in project settings, nothing breaks; `/autocompact <tokens>` is the manual alternative.
- `PreCompact` hook — its output instructs the summary to keep the active state (goal, approvals, decisions, files, commands with results, next step).
- `SessionStart` hook (`startup|resume|compact`) — re-injects branch, last commits and the session state file.
- `CLAUDE.md` is re-read from disk after compaction; durable rules belong there or in `AGENTS.md`, never only in chat.

## Habits
- Search before reading; read line ranges; batch independent tool calls; stop when you can act.
- Pass paths and criteria to sub-agents, not pasted content.
- Write the handoff *before* the context fills; record approvals there.
- A fix never becomes a new paragraph in the entry file: it goes to the plan's execution block, the handoff, or the ledger.
- Decision by the owner → one line in `AGENTS.md` + dated entry in `OWNER_DECISIONS.md`.
- Duplicate rule in two files → keep one, point the other to it.

## Untouchable (never traded for tokens)
Correctness, critical test coverage, verbatim code/commands/errors, every result, cause, risk and decision in a reply.
