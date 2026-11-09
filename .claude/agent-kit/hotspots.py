#!/usr/bin/env python3
"""agent-kit: rework hotspots from git history (offline, read-only).

Usage: hotspots.py [PATH ...] [--top 10] [--since 180.days] [--min 3]
Counts commits whose message looks like a fix/regression per file. With PATHs, reports only those
files (exact path or directory prefix). Use before touching a file: a hotspot needs a regression
test and a look at the rework ledger (skill systematic-debug), not another quick patch.
"""
import argparse, collections, re, subprocess, sys

FIX = re.compile(r"\b(fix|fixes|fixed|hotfix|bug|regress|revert|corrig|conserta|arruma|repara|correg|arregl)", re.I)
SKIP = re.compile(r"(\.md$|\.lock$|lock\.json$|lockfile|HANDOFF|CHANGELOG|/docs?/|/locales?/|/i18n/|/localization/)", re.I)  # translations grow with every fix: noise


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("--since", default="180.days")
    ap.add_argument("--min", type=int, default=3)
    a = ap.parse_args()
    r = subprocess.run(["git", "log", "--no-merges", "--since=" + a.since, "--name-only", "--format=\x1e%s"],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit("not a git repository (or git missing)")
    sh = subprocess.run(["git", "rev-parse", "--is-shallow-repository"], capture_output=True, text=True).stdout.strip()
    if sh == "true":
        print("note: shallow clone, counts are partial (git fetch --unshallow for the full history)")
    count = collections.Counter()
    for block in r.stdout.split("\x1e")[1:]:
        lines = block.strip().splitlines()
        if not lines or not FIX.search(lines[0]):
            continue
        for f in set(l for l in lines[1:] if l and not SKIP.search(l)):
            count[f] += 1
    rows = [(n, f) for f, n in count.items() if n >= a.min]
    if a.paths:
        rows = [(n, f) for n, f in rows if any(f == p or f.startswith(p.rstrip("/") + "/") for p in a.paths)]
    rows.sort(reverse=True)
    if not rows:
        print("no hotspots (>= %d fix commits since %s)" % (a.min, a.since))
        return
    print("fix commits  file   (since %s)" % a.since)
    for n, f in rows[: a.top]:
        print("%11d  %s" % (n, f))
    print("hotspot = add a regression test and check the rework ledger before patching again")


if __name__ == "__main__":
    main()
