@AGENTS.md

# Claude Code notes

- Project config in `.claude/`: output style `caveman` (terse replies), hooks that re-inject the session state after compaction, earlier auto-compaction, and skills in `.claude/skills/` (loaded on demand).
- Long context: write the active state to the handoff file before it fills; after `/compact` the hook re-reads it. Use `/compact <focus>` to steer a manual compaction.
- Sub-agents inherit every rule in `AGENTS.md`, including the approval gate and the build rule. Brief them with paths and acceptance criteria (`docs/agents/standard/ORCHESTRATION.md`), and read their diff, not their summary.
