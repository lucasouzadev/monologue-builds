#!/usr/bin/env bash
# agent-kit: prints the active session state; Claude Code adds stdout to context.
# Read-only: no writes, no network. Keep output small (it costs tokens every session).
set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
event="${1:-startup}"
echo "[agent-kit] session ${event}. Rules: AGENTS.md (approval gate, caveman ≤15 lines, canary, evidence states)."
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "branch: $(git branch --show-current 2>/dev/null)  dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "last commits:"; git log --oneline -5 2>/dev/null | sed 's/^/  /'
fi
# Session state file: first match wins. Projects may list extra paths in .claude/handoff-paths (one per line).
candidates=()
[ -f .claude/handoff-paths ] && while IFS= read -r p; do [ -n "$p" ] && candidates+=("$p"); done < .claude/handoff-paths
candidates+=(HANDOFF.md docs/agents/HANDOFF.md docs/HANDOFF.md)
for f in "${candidates[@]}"; do
  if [ -d "$f" ]; then
    newest=$(ls -t "$f"/*.md 2>/dev/null | head -1)
    [ -n "$newest" ] && { echo "newest handoff: $newest (open only if it is this task's)"; break; }
  elif [ -f "$f" ]; then
    echo "--- $f (first 60 lines) ---"; head -60 "$f"; break
  fi
done
if [ "$event" = "compact" ]; then
  echo "[agent-kit] Context was compacted. Re-check approvals recorded in the handoff before writing anything."
fi
exit 0
