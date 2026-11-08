# CANARY — Owner's name in chat replies only

A weak signal that the agent loaded the rules. It proves nothing about tests, sources or correctness.

## Source, in priority order
1. A form of address the owner gives in the current chat.
2. The owner's **personal, private** agent settings (e.g. `~/.claude/CLAUDE.md` or Claude memory, Codex/Cursor user rules) — outside every repository.
3. Nothing available → write `CANARY NOT CONFIGURED` once and ask the owner to set it in their personal settings. Never infer it from git author, GitHub user, e-mail or files.

Tools do not share preferences: each one (Claude, Codex, Cursor) is configured separately by the owner.

## Output rule
Every visible chat reply to the owner (progress, question, failure, final) contains the exact form of address, preferably as the first word.

## Storage rule
The value **never** goes to code, tests, fixtures, comments, UI strings, config, docs, ADRs, README, CHANGELOG, commits, PRs, issues, logs, screenshots or artifacts. Reviews check the diff for it without transcribing it. Do not write a placeholder as if it were the name.
