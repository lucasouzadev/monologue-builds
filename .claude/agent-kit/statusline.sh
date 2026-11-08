#!/usr/bin/env bash
# agent-kit statusline: context use vs the compaction window, weekly/5h plan usage, branch.
# Also caches plan usage for the usage-guard hook (hooks do not receive usage data).
# Reads Claude Code's statusline JSON on stdin. No network. Only writes the small cache file.
input="$(cat)"
WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-200000}"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="${TMPDIR:-/tmp}/agent-kit-usage-$(printf '%s' "$PROJ" | cksum | cut -d' ' -f1).json"
here="$(cd "$(dirname "$0")" && pwd)"
out="$(printf '%s' "$input" | HERE="$here" W="$WINDOW" CACHE="$CACHE" python3 -c '
import json,sys,os,time
try: d=json.load(sys.stdin)
except Exception: print(""); sys.exit()
parts=[]
cw=d.get("context_window") or {}
cu=cw.get("current_usage") or {}
used=None
if isinstance(cu,dict) and cu:
    used=sum(int(cu.get(k) or 0) for k in ("input_tokens","cache_creation_input_tokens","cache_read_input_tokens"))
w=int(os.environ.get("W","200000"))
if used:
    sid=d.get("session_id",""); b=used//25000
    try:
        st=json.load(open(os.environ["CACHE"]+".ctx")) if os.path.exists(os.environ["CACHE"]+".ctx") else {}
    except Exception: st={}
    if st.get(sid,-1) < b:
        st[sid]=b; json.dump(st,open(os.environ["CACHE"]+".ctx","w"))
        import subprocess; subprocess.Popen(["python3",os.environ["HERE"]+"/metrics.py","log","ctx","k=%d"%(used//1000),"session="+sid],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    p=round(100*used/w); parts.append(f"ctx {used//1000}k/{w//1000}k ({p}%)" + (" → handoff" if p>=70 else ""))
elif cw.get("used_percentage") is not None:
    up=cw.get("used_percentage"); parts.append(f"ctx {up}%")
rl=d.get("rate_limits") or {}
wk=(rl.get("seven_day") or {}).get("used_percentage")
fh=(rl.get("five_hour") or {}).get("used_percentage")
if wk is not None: parts.append(f"wk {round(wk)}%" + (" → baton" if wk>=85 else ""))
if fh is not None and fh>=80: parts.append(f"5h {round(fh)}%")
if rl:
    try:
        json.dump({"ts":int(time.time()),"seven_day":rl.get("seven_day"),"five_hour":rl.get("five_hour")}, open(os.environ["CACHE"],"w"))
    except Exception: pass
print(" · ".join(parts))
' 2>/dev/null)"
branch="$(git -C "$PROJ" branch --show-current 2>/dev/null)"
printf '%s%s\n' "${out:-ctx ?}" "${branch:+ · $branch}"
