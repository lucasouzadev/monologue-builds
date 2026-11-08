#!/usr/bin/env bash
input=""; [ -t 0 ] || input="$(cat 2>/dev/null)"
here="$(cd "$(dirname "$0")" && pwd)"
eval "$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: d={}
print("trig=%s sid=%s" % (d.get("trigger","?"), d.get("session_id","")))' 2>/dev/null)"
( python3 "$here/metrics.py" log precompact trigger="${trig:-?}" session="${sid:-}" >/dev/null 2>&1 & )
# agent-kit: stdout becomes instructions for the compaction summary. Read-only.
cat <<'TXT'
Compaction instructions (agent-kit): keep the ACTIVE STATE, not the chat history.
Preserve verbatim: the goal; every owner approval with date and exact scope; decisions and why;
files touched; commands run with their real results (PASS/FAIL/BLOCKED/NOT RUN); open risks;
pending owner decisions; the exact next step; branch/PR/SHA; the owner's form of
address given in this session (canary — conversation only, never written to files). Drop exploration dead-ends,
pasted file contents and long logs (keep only the failing lines). If the session state file
(HANDOFF) is stale, the first action after compaction is to replace it.
TXT
exit 0
