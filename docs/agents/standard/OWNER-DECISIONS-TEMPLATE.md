# OWNER_DECISIONS — template

Dated log of the owner's standing instructions. Keeps `AGENTS.md` short: the entry point holds the *current rule* in one line; this file holds the quote, date and scope. Copy to `docs/agents/OWNER_DECISIONS.md`.

Rules
- Newest first. Quote the owner when wording matters. Never delete an entry: mark it `SUPERSEDED by <date>`.
- A decision that changes behaviour also updates the one-line rule in `AGENTS.md` (same commit).
- Never store secrets, personal data or the canary value here.

```markdown
## <YYYY-MM-DD> — <topic>
Quote: "<owner words>"
Rule: <what agents must do / must not do>
Scope: <platforms, actions, until when>
Supersedes: <date or none>
```
