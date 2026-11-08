#!/usr/bin/env bash
# agent-kit: prints the active session state; Claude Code adds stdout to context.
# Read-only: no writes, no network. Keep output small (it costs tokens every session).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
event="${1:-startup}"
sid=""; [ -t 0 ] || sid="$(cat 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")' 2>/dev/null)"
( python3 "$here/metrics.py" log session kind="$event" session="$sid" >/dev/null 2>&1 & )
if [ "$event" = startup ] && [ -f "$here/verify.py" ]; then
  changed="$(python3 "$here/verify.py" 2>/dev/null | head -5)"
  [ -n "$changed" ] && { echo "[agent-kit] WARNING: kit files differ from the install manifest (hooks run on every session; review before trusting):"; echo "$changed" | sed 's/^/  /'; }
fi
echo "[agent-kit] session ${event}. Rules: AGENTS.md (approval gate, caveman ≤15 lines, evidence states)."
[ "$event" = startup ] && echo "[agent-kit] Canary: use the form of address the owner gives in this session; if none yet, ask once."
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "branch: $(git branch --show-current 2>/dev/null)  dirty files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "last commits:"; git log --oneline -5 2>/dev/null | sed 's/^/  /'
fi
# Session state file: first match wins. Projects may list extra paths in .claude/handoff-paths (one per line).
candidates=()
for cfg in .claude/agent-kit/handoff-paths .claude/handoff-paths; do
  [ -f "$cfg" ] && while IFS= read -r p; do [ -n "$p" ] && candidates+=("$p"); done < "$cfg"
done
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
