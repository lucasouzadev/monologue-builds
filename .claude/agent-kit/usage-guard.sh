#!/usr/bin/env bash
# agent-kit UserPromptSubmit hook: when plan usage is high, tells the agent (via context) to offer
# the owner a baton-pass prompt. Usage comes from the statusline cache (hooks get no usage data).
# Nudges once per session per level (AGENT_KIT_BATON_PCT, default 85; again at 95). Read-only except a marker.
input="$(cat)"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="${TMPDIR:-/tmp}/agent-kit-usage-$(printf '%s' "$PROJ" | cksum | cut -d' ' -f1).json"
[ -f "$CACHE" ] || exit 0
here="$(cd "$(dirname "$0")" && pwd)"
printf '%s' "$input" | HERE="$here" CACHE="$CACHE" T="${AGENT_KIT_BATON_PCT:-85}" python3 -c '
import json,sys,os,time
try: sid=(json.load(sys.stdin) or {}).get("session_id","nosession")
except Exception: sid="nosession"
try: c=json.load(open(os.environ["CACHE"]))
except Exception: sys.exit()
if time.time()-c.get("ts",0) > 6*3600: sys.exit()
t=float(os.environ["T"])
wk=(c.get("seven_day") or {}); fh=(c.get("five_hour") or {})
pick=None
for name,win in (("weekly",wk),("5-hour",fh)):
    u=win.get("used_percentage")
    if u is None: continue
    lim=t if name=="weekly" else max(t,90)
    if u>=lim: pick=(name,u,win.get("resets_at")); break
if not pick: sys.exit()
name,u,reset=pick
level=95 if u>=95 else int(lim)
marker=os.environ["CACHE"]+f".{sid}.{name}.{level}"
if os.path.exists(marker): sys.exit()
open(marker,"w").close()
import subprocess
subprocess.Popen(["python3",os.environ.get("HERE",".")+"/metrics.py","log","baton","window="+name,"pct=%d"%u,"session="+sid],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
when=time.strftime("%Y-%m-%d %H:%M", time.localtime(reset)) if reset else "unknown"
print(f"[agent-kit] The owner’s {name} plan usage is at {round(u)}% (resets {when}). After answering, add ONE short line offering a baton-pass prompt (skill baton-pass) so the work can continue in another tool or session. Do not stop working because of this.")
'
exit 0
