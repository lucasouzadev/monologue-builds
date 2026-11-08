# NO-HOOKS — Doing by hand what Claude Code hooks do

Codex, Cursor and other tools read `AGENTS.md` but run no hooks, output styles or statusline. The rules still apply; you perform the hook duties yourself.

| Claude Code does automatically | You do |
|---|---|
| `SessionStart`: injects branch, last commits, handoff | First action of a session: `git fetch`, `git log --oneline -5`, read the handoff file; brief the owner in 3 lines |
| `intent-brief`: reminds you to compile the message | For every owner request, silently compile goal · repo context · acceptance · constraints · mode · skills · ≤ 1 question; show only goal + acceptance |
| `caveman` output style | ≤ 15 short lines, result first, nothing important dropped |
| `action-guard`: asks before risky commands | Stop and ask the owner before: push to the default branch, force-push, deploy/migration, real builds or store releases, dispatching CI that builds or publishes, publishing packages, destructive SQL/infra, printing a secret, `curl \| sh`. One "yes" covers one action |
| `PreCompact` + `SessionStart(compact)` | When the context is large (~70 %) or before it is compacted: replace the handoff with the active state (goal, approvals with date, decisions, files, commands with real results, next step), then continue from it |
| `usage-guard`: weekly/5-hour limit | When the owner mentions limits, or work will clearly outlast the session: update the handoff and offer a continuation prompt (template in the `baton-pass` skill, or `HANDOFF-TEMPLATE.md`) |
| `verify.py` + metrics | Optional: `python3 .claude/agent-kit/verify.py` before trusting `.claude/` hooks from a PR; `metrics.py report` for the weekly review |

Cursor: the installer writes `.cursor/rules/agent-kit.mdc` (always applied) pointing here when `.cursor/` exists or `--cursor` is passed.
