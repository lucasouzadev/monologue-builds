#!/usr/bin/env bash
# agent-kit: prints the active session state; Claude Code adds stdout to context.
# Read-only: no writes, no network. Keep output small (it costs tokens every session).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
event="${1:-startup}"
sid=""; [ -t 0 ] || sid="$(cat 2>/dev/null | "$PY" -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")' 2>/dev/null)"
[ -n "$PY" ] && ( "$PY" "$here/metrics.py" log session kind="$event" session="$sid" >/dev/null 2>&1 & ) || true
if [ -z "$PY" ]; then
  echo "[agent-kit] WARNING: Python 3 not found. Hooks action-guard (asks before risky commands), intent-brief, usage-guard, metrics and the integrity check are INACTIVE. The approval gate is text-only until Python 3 is installed (Windows: use Git Bash or WSL)."
fi
if [ "$event" = startup ] && [ -n "$PY" ] && [ -f "$here/verify.py" ]; then
  changed="$("$PY" "$here/verify.py" 2>/dev/null | head -5)"
  [ -n "$changed" ] && { echo "[agent-kit] WARNING: kit files differ from the install manifest (hooks run on every session; review before trusting):"; echo "$changed" | sed 's/^/  /'; }
fi
if [ "$event" = startup ] && [ -n "$PY" ] && [ -f "$here/update.py" ]; then
  note="$("$PY" "$here/update.py" notice 2>/dev/null)"; [ -n "$note" ] && echo "$note"
  # Opt-in only (AGENT_KIT_AUTOCHECK=1): the one place a hook may touch the network, at most weekly.
  if [ "${AGENT_KIT_AUTOCHECK:-0}" = 1 ]; then ( "$PY" "$here/update.py" check --quiet --if-stale >/dev/null 2>&1 & ) || true; fi
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
