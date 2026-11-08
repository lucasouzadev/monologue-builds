#!/usr/bin/env bash
# agent-kit statusline: context usage against the agent-kit compaction window, plus branch.
# Reads Claude Code's statusline JSON on stdin. Read-only. Requires nothing beyond bash + python3 (falls back silently).
input="$(cat)"
WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-200000}"
out="$(printf '%s' "$input" | python3 -c '
import json,sys,os
try: d=json.load(sys.stdin)
except Exception: print(""); sys.exit()
cw=d.get("context_window") or {}
used=cw.get("total_input_tokens")
cu=cw.get("current_usage") or {}
if isinstance(cu,dict) and cu:
    used=sum(int(cu.get(k) or 0) for k in ("input_tokens","cache_creation_input_tokens","cache_read_input_tokens"))
w=int(os.environ.get("W","200000"))
if not used:
    pct=cw.get("used_percentage"); print(f"ctx {pct or 0}%"); sys.exit()
p=round(100*used/w)
tag=" → write handoff" if p>=70 else ""
print(f"ctx {used//1000}k/{w//1000}k ({p}%){tag}")
' W="$WINDOW" 2>/dev/null)"
branch="$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null)"
printf '%s%s\n' "${out:-ctx ?}" "${branch:+ · $branch}"
