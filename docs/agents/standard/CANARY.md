# CANARY — The owner's form of address, chat only

A weak signal that the agent loaded the rules. It proves nothing about tests, sources or correctness.

## Source
1. The owner states it **at the start of each session** (e.g. "call me X"). That is the only source.
2. It lives only in the conversation. The `PreCompact` instruction keeps it in the compaction summary, so it survives `/compact`.
3. Not given yet → the first reply asks for it once, in one short line; until it arrives, start replies with `CANARY NOT CONFIGURED`. Never infer it from git author, GitHub user, e-mail, files or earlier sessions.

## Choosing it
Pick a word that appears **nowhere** in the repositories, commits or docs (not your username, handle, app account or project name). If it is already in the repo, an agent can echo it from a file it happened to read, and the signal means nothing. When the owner gives a word, the agent may `git grep -qi` for it once (without printing matches); if it is found, say so in one line and suggest choosing another. Never store the result.

## Output rule
Every visible chat reply to the owner (progress, question, failure, final) contains the exact form of address, preferably as the first word.

## Storage rule
The value **never** goes to code, tests, fixtures, comments, UI strings, config, docs, handoffs, ADRs, README, CHANGELOG, commits, PRs, issues, logs, screenshots or artifacts. Reviews check the diff for it without transcribing it. Never write a placeholder as if it were the name.
