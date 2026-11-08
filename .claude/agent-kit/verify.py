#!/usr/bin/env python3
"""Compare installed agent-kit files with the hashes in .claude/agent-kit/manifest.json.

Exit 0 = all match (or no manifest); 1 = some kit-owned file changed or is missing.
Used by the SessionStart hook (warning only) and by the optional CI guard.
A changed hook is code that runs on every session: review it before trusting it.
"""
import hashlib, json, os, sys
from pathlib import Path

root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or (sys.argv[1] if len(sys.argv) > 1 else "."))
m = root / ".claude/agent-kit/manifest.json"
if not m.exists():
    sys.exit(0)
files = json.loads(m.read_text()).get("files", {})
bad = []
for rel, h in files.items():
    if not rel.startswith(".claude/"):
        continue  # docs/templates may be edited by the project
    p = root / rel
    if not p.exists():
        bad.append(f"missing {rel}")
    elif hashlib.sha256(p.read_bytes()).hexdigest() != h:
        bad.append(f"changed {rel}")
for b in bad:
    print(b)
sys.exit(1 if bad else 0)
