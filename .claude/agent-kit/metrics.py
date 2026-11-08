#!/usr/bin/env python3
"""agent-kit local metrics (stdlib only). Never stores prompt text, code or secrets: only counts.

  metrics.py log <event> [key=value ...]   append one event (called by hooks; silent)
  metrics.py report [--days N]             summary for this project (default 7 days)

Log: ${AGENT_KIT_STATE:-~/.local/state/agent-kit}/<project-id>.jsonl  (outside the repo)
Disable: AGENT_KIT_METRICS=0
"""
import json, os, subprocess, sys, time, zlib
from collections import Counter
from pathlib import Path

PROJ = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
STATE = Path(os.environ.get("AGENT_KIT_STATE") or Path.home() / ".local/state/agent-kit")
LOG = STATE / f"{zlib.crc32(PROJ.encode()):08x}.jsonl"


def log(event, pairs):
    if os.environ.get("AGENT_KIT_METRICS") == "0":
        return
    rec = {"ts": int(time.time()), "event": event}
    for p in pairs:
        k, _, v = p.partition("=")
        rec[k] = int(v) if v.lstrip("-").isdigit() else v[:40]
    try:
        STATE.mkdir(parents=True, exist_ok=True)
        with LOG.open("a") as f:
            f.write(json.dumps(rec) + "\n")
    except OSError:
        pass


def pct(vals, q):
    if not vals:
        return 0
    vals = sorted(vals)
    return vals[min(len(vals) - 1, int(q * len(vals)))]


def report(days):
    since = time.time() - days * 86400
    recs = []
    if LOG.exists():
        for line in LOG.read_text().splitlines():
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("ts", 0) >= since:
                recs.append(r)
    ev = Counter(r["event"] for r in recs)
    sessions = {r.get("session") for r in recs if r.get("session")}
    starts = sum(1 for r in recs if r["event"] == "session" and r.get("kind") == "startup")
    comp = Counter(r.get("trigger", "?") for r in recs if r["event"] == "precompact")
    prompts = [r for r in recs if r["event"] == "prompt"]
    modes = Counter(r.get("mode", "?") for r in prompts)
    peak = {}
    for r in recs:
        if r["event"] == "ctx":
            s = r.get("session", "?")
            peak[s] = max(peak.get(s, 0), r.get("k", 0))
    peaks = list(peak.values())
    print(f"agent-kit report — last {days} days — {PROJ}")
    print(f"sessions: {len(sessions) or starts} · prompts: {len(prompts)} · prompts/session: {len(prompts) / max(1, len(sessions) or starts):.1f}")
    print(f"compactions: {sum(comp.values())} (auto {comp.get('auto', 0)}, manual {comp.get('manual', 0)}) · baton offers: {ev.get('baton', 0)}")
    print(f"peak context per session (k tokens): p50 {pct(peaks, .5)} · p90 {pct(peaks, .9)} · max {max(peaks or [0])}")
    print("modes: " + (", ".join(f"{m} {n}" for m, n in modes.most_common()) or "none"))
    # rework signal from git: files touched by >= 3 fix-like commits in the window
    try:
        out = subprocess.run(["git", "-C", PROJ, "log", f"--since={days * 2}.days", "--name-only",
                              "--pretty=format:@@%s"], capture_output=True, text=True, timeout=20).stdout
        fixes, cur = Counter(), False
        for line in out.splitlines():
            if line.startswith("@@"):
                s = line[2:].lower()
                cur = any(w in s for w in ("fix", "corrig", "retest", "round", "rodada", "hotfix", "revert"))
            elif line and cur:
                fixes[line] += 1
        hot = [(f, n) for f, n in fixes.most_common(5) if n >= 3]
        print(f"rework (files with ≥3 fix commits in {days * 2} days): " + (", ".join(f"{f} ×{n}" for f, n in hot) or "none"))
    except Exception:
        print("rework: git not available")
    if not recs:
        print("no events yet: hooks log as you work (AGENT_KIT_METRICS=0 disables).")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["log"] and len(a) >= 2:
        log(a[1], a[2:])
    elif a[:1] == ["report"]:
        report(int(a[a.index("--days") + 1]) if "--days" in a else 7)
    else:
        print(__doc__)
