#!/usr/bin/env bash
# agent-kit PreToolUse guard for pull requests: runs the repo's own PR quality checker on the PR body
# before an agent opens or edits a PR (GitHub MCP create/update_pull_request, or `gh pr create/edit
# --body-file F`). Blocks only on the checker's hard failures (empty evidence, missing sections,
# secrets in the diff...); warnings pass. Makes `--pr-quality local` enforced instead of advisory.
# No checker or config in the repo → allow. Offline (local git only); errors fail open.
# AGENT_KIT_PR_GATE=0 disables. Never prints the PR body.
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
ak_require_py
input=""; [ -t 0 ] || input="$(cat 2>/dev/null)"
[ "${AGENT_KIT_PR_GATE:-1}" = 0 ] && exit 0
printf '%s' "$input" | "$PY" -c '
import json, os, re, shlex, subprocess, sys
try: d = json.load(sys.stdin) or {}
except Exception: sys.exit()
tool = d.get("tool_name", ""); ti = d.get("tool_input") or {}
proj = os.environ.get("CLAUDE_PROJECT_DIR") or d.get("cwd") or "."
body = None; repo = ti.get("repo") or ""; base = ti.get("base") or ""; draft = bool(ti.get("draft"))
if re.search(r"create_pull_request$|update_pull_request$", tool):
    body = ti.get("body")
elif tool == "Bash":
    cmd = ti.get("command", "") or ""
    m = re.search(r"\bgh\s+pr\s+(create|edit)\b(.*)", cmd)
    if not m: sys.exit()
    try: args = shlex.split(m.group(2))
    except ValueError: sys.exit()
    for i, a in enumerate(args):
        if a in ("--body-file", "-F") and i + 1 < len(args):
            p = os.path.join(d.get("cwd") or proj, args[i + 1])
            try: body = open(p, encoding="utf-8").read()
            except OSError: sys.exit()
        if a in ("--base", "-B") and i + 1 < len(args): base = args[i + 1]
        if a in ("--draft", "-d"): draft = True
if not body: sys.exit()          # no body change (or inline --body): nothing to check here
roots = [os.path.join(proj, repo)] if repo else []
roots += [d.get("cwd") or "", proj]
root = next((r for r in roots if r and os.path.isfile(os.path.join(r, ".github/scripts/pr_quality.py"))), None)
if not root: sys.exit()
cfg = os.path.join(root, ".github/pr-quality.json")
cmd = [sys.executable, os.path.join(root, ".github/scripts/pr_quality.py"), "--body-env", "AK_PR_BODY", "--summary-file", os.devnull]
if os.path.isfile(cfg): cmd += ["--config", cfg]
if base and subprocess.run(["git", "-C", root, "rev-parse", "--verify", "-q", "origin/" + base], capture_output=True).returncode == 0:
    cmd += ["--git-base", "origin/" + base]
if draft: cmd.append("--draft")
env = dict(os.environ, AK_PR_BODY=body, GITHUB_STEP_SUMMARY="")
try: r = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=root, timeout=60)
except Exception: sys.exit()
if r.returncode == 0: sys.exit()
fails = [l[4:].strip() for l in r.stdout.splitlines() if l.startswith("- ❌")]
if not fails: sys.exit()
reason = "PR quality check failed (fix the PR body, then retry): " + " | ".join(fails[:6])
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
'
exit 0
