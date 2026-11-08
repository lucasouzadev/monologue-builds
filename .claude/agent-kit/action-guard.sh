#!/usr/bin/env bash
# agent-kit PreToolUse(Bash) guard: turns the written approval gate into a prompt.
#   deny = catastrophic and never intended (rm -rf of / or ~, force-push to main, disk wipes)
#   ask  = needs the owner's yes for THIS action (push to main, deploys, store builds/releases,
#          workflow dispatch, publishing, destructive SQL/infra, secret reads, curl|sh)
# A seatbelt, not a sandbox: quoted text and heredoc bodies are ignored (commit messages), and a
# determined `bash -c` can still evade it. "ask" is not guaranteed in bypass/dontAsk modes.
# Project files (in .claude/agent-kit/): guard-allow = regexes for standing authorizations;
# guard-extra = lines "ask|regex|reason" or "deny|regex|reason". AGENT_KIT_GUARD=0 disables.
# Logs only the rule id (never the command). Offline, read-only.
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
ak_require_py
input=""; [ -t 0 ] || input="$(cat 2>/dev/null)"
[ "${AGENT_KIT_GUARD:-1}" = 0 ] && exit 0
printf '%s' "$input" | HERE="$here" "$PY" -c '
import json, os, re, subprocess, sys
try: d = json.load(sys.stdin) or {}
except Exception: sys.exit()
if d.get("tool_name") != "Bash": sys.exit()
raw = (d.get("tool_input") or {}).get("command", "") or ""
if not raw.strip(): sys.exit()
proj = os.environ.get("CLAUDE_PROJECT_DIR") or d.get("cwd") or "."
cfg = os.path.join(proj, ".claude", "agent-kit")

def strip(c):
    c = re.sub(r"<<-?\s*[\x27\"]?(\w+)[\x27\"]?[^\n]*\n.*?\n\s*\1\b", " ", c, flags=re.S)
    c = re.sub(r"\"(?:\\\\.|[^\"\\\\])*\"", "\"\"", c, flags=re.S)
    c = re.sub(r"\x27[^\x27]*\x27", "\x27\x27", c, flags=re.S)
    return re.sub(r"\s+", " ", c)

texts = [strip(raw)]
if re.search(r"\b(bash|sh|zsh)\s+-\w*c\b|\beval\b", raw):
    texts.append(re.sub(r"\s+", " ", raw))

def lines(name):
    p = os.path.join(cfg, name)
    if not os.path.exists(p): return []
    return [l.strip() for l in open(p).read().splitlines() if l.strip() and not l.startswith("#")]

BR = r"(\s|:|refs/heads/)(main|master)(\s|$|[\"\x27;&|])"
RULES = [
 ("rm-root-home", "deny", r"\brm\s+(-\w+\s+)*-\w*[rR]\w*\s+(-\w+\s+)*(/|~|\$HOME|\"?\$\{?HOME\}?\"?)/?(\s|$)", "recursive delete of / or the home folder"),
 ("force-push-main", "deny", r"\bgit\s+push\b.*(--force\b|\s-f\b|--force-with-lease).*" + BR, "force-push to the default branch"),
 ("disk-wipe", "deny", r"\b(mkfs\S*|dd\s+.*of=/dev/\S+)", "disk wipe"),
 ("force-push", "ask", r"\bgit\s+push\b.*(--force\b|\s-f\b|--force-with-lease)", "force-push rewrites shared history"),
 ("push-default-branch", "ask", r"\bgit\s+push\b.*" + BR, "push to the default branch"),
 ("git-destructive", "ask", r"\bgit\s+(reset\s+--hard|clean\s+-\w*f|checkout\s+--\s+\.|branch\s+-D\b|stash\s+(drop|clear))", "discards work that may not exist elsewhere"),
 ("native-build-release", "ask", r"\b(eas\s+(build|submit)|fastlane\s+(pilot|deliver|supply|release|beta)|xcrun\s+(altool|notarytool)\s+\S*(upload|submit)|bundle\s+exec\s+fastlane)\b", "real build/store release: needs the owner order for this execution"),
 ("workflow-dispatch", "ask", r"\bgh\s+(workflow\s+run|run\s+rerun|api\s+\S*dispatches|release\s+(create|delete|upload))\b", "dispatches CI or publishes a release"),
 ("publish", "ask", r"\b(npm|pnpm|yarn|bun)\s+publish\b|\bcargo\s+publish\b|\btwine\s+upload\b|\bdocker\s+push\b", "publishes a package or image"),
 ("deploy", "ask", r"\b(vercel\s+(deploy|--prod)|fly(ctl)?\s+deploy|netlify\s+deploy|wrangler\s+(deploy|publish)|firebase\s+deploy|supabase\s+(db\s+(push|reset)|functions\s+deploy|migration\s+up)|terraform\s+(apply|destroy)|kubectl\s+(delete|apply)|helm\s+(install|upgrade|uninstall))\b", "deploy, migration or infrastructure change"),
 ("destructive-sql", "ask", r"\b(drop|truncate)\s+(table|database|schema)\b", "destructive SQL"),
 ("secret-read", "ask", r"\bcat\s+\S*(\.env\b|\.p8\b|\.jks\b|\.pem\b|id_rsa|\.npmrc)|\b(echo|printf)\s+\S*\$\{?\w*(SECRET|TOKEN|PASSWORD|API_?KEY|PRIVATE)|\bprintenv\s+\w*(SECRET|TOKEN|PASSWORD|KEY)", "would print a secret"),
 ("pipe-to-shell", "ask", r"\b(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b", "runs downloaded code"),
 ("sudo-chmod", "ask", r"\bsudo\b|\bchmod\s+-R\s+7", "privileged or wide permission change"),
]
for l in lines("guard-extra"):
    parts = l.split("|", 2)
    if len(parts) == 3 and parts[0] in ("ask", "deny"):
        RULES.append(("project-rule", parts[0], parts[1], parts[2]))
allow = [re.compile(a) for a in lines("guard-allow")]
hit = None
for rid, dec, rx, why in RULES:
    if any(re.search(rx, t) for t in texts):
        if any(a.search(raw) for a in allow): continue
        if hit is None or (dec == "deny" and hit[1] != "deny"): hit = (rid, dec, why)
if not hit: sys.exit()
rid, dec, why = hit
try:
    subprocess.Popen([sys.executable, os.path.join(os.environ.get("HERE", "."), "metrics.py"), "log", "guard", "rule=" + rid, "decision=" + dec, "session=" + str(d.get("session_id", ""))], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception: pass
msg = ("agent-kit guard [" + rid + "]: " + why + ". " +
       ("Blocked. Ask the owner for an explicit instruction first." if dec == "deny" else "Needs the owner\x27s approval for this action; do not retry around it."))
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": dec, "permissionDecisionReason": msg}}))
'
exit 0
