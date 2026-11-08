#!/usr/bin/env python3
"""agent-kit update notice (stdlib only).

  update.py check [--quiet] [--if-stale]   fetch the latest kit VERSION (network, explicit) and cache it
  update.py notice                          offline: print one line if a newer version is cached (max 1/day)

Nothing is installed automatically. To update: clone the kit, run its installer with --dry-run, read the
diff, then run it for real (it never overwrites files you edited).
Env: AGENT_KIT_LATEST_URL (default: raw VERSION on the kit's main branch; file:// works), AGENT_KIT_STATE.
The SessionStart hook runs `notice` (offline). `check` runs from the hook only if AGENT_KIT_AUTOCHECK=1 (weekly).
"""
import json, os, sys, time, urllib.request
from pathlib import Path

URL = os.environ.get("AGENT_KIT_LATEST_URL") or "https://raw.githubusercontent.com/lucasouzadev/agent-kit-skill/main/skills/agent-kit/VERSION"
REPO = "https://github.com/lucasouzadev/agent-kit-skill"
STATE = Path(os.environ.get("AGENT_KIT_STATE") or Path.home() / ".local/state/agent-kit")
CACHE = STATE / "latest.json"
PROJ = Path(os.environ.get("CLAUDE_PROJECT_DIR") or ".")


def ver(s):
    out = []
    for p in str(s).strip().split("."):
        digits = "".join(ch for ch in p if ch.isdigit())
        out.append(int(digits or 0))
    return tuple(out)


def installed():
    try:
        return json.loads((PROJ / ".claude/agent-kit/manifest.json").read_text()).get("version")
    except Exception:
        return None


def load():
    try:
        return json.loads(CACHE.read_text())
    except Exception:
        return {}


def save(d):
    try:
        STATE.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(d))
    except OSError:
        pass


def check(quiet, if_stale):
    c = load()
    if if_stale and time.time() - c.get("checked", 0) < 7 * 86400:
        return 0
    try:
        with urllib.request.urlopen(URL, timeout=5) as r:
            latest = r.read(64).decode().strip()
    except Exception as e:
        if not quiet:
            print(f"could not reach {URL}: {e}")
        return 1
    c.update({"latest": latest, "checked": int(time.time())})
    save(c)
    cur = installed()
    if not quiet:
        if cur and ver(latest) > ver(cur):
            print(f"agent-kit {cur} -> {latest} available.")
            print(f"  git clone --depth 1 {REPO} && python3 agent-kit-skill/skills/agent-kit/scripts/install.py {PROJ} --dry-run")
            print("  read the plan, then run it again without --dry-run")
        else:
            print(f"agent-kit is up to date ({cur or 'not installed'}; latest {latest}).")
    return 0


def notice():
    c, cur = load(), installed()
    latest = c.get("latest")
    if not cur or not latest or ver(latest) <= ver(cur):
        return 0
    if time.time() - c.get("nagged", 0) < 86400:
        return 0
    c["nagged"] = int(time.time())
    save(c)
    print(f"[agent-kit] Update available: {cur} -> {latest}. Tell the owner once, briefly; run `python3 .claude/agent-kit/update.py check` for the steps (nothing installs by itself).")
    return 0


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["check"]:
        sys.exit(check("--quiet" in a, "--if-stale" in a))
    elif a[:1] == ["notice"]:
        sys.exit(notice())
    else:
        print(__doc__)
