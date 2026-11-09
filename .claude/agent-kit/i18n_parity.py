#!/usr/bin/env python3
"""agent-kit: translation key parity across JSON locale files (offline, read-only).

Usage: i18n_parity.py [ROOT] [--base en]
Finds locale JSON files laid out as <dir>/<lang>/<ns>.json or <dir>/<lang>.json (lang like en, pt-BR,
es, en_US) and compares nested keys with the base language. Exit 1 when a locale misses or adds keys,
so it can run in CI or before a PR. Values are never printed.
"""
import argparse, json, os, re, sys

LANG = re.compile(r"^[a-z]{2}([-_][A-Za-z]{2,4})?$")
SKIP_DIRS = {"node_modules", ".git", "dist", "build", "Pods", ".next", "coverage", "vendor"}


def keys(obj, prefix=""):
    out = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            out |= keys(v, prefix + k + ".") if isinstance(v, dict) else {prefix + k}
    return out


def collect(root):
    groups = {}  # (dir, namespace) -> {lang: path}
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
        for f in files:
            if not f.endswith(".json"):
                continue
            stem, parent = f[:-5], os.path.basename(d)
            if LANG.match(parent):
                groups.setdefault((os.path.dirname(d), stem), {})[parent] = os.path.join(d, f)
            elif LANG.match(stem):
                groups.setdefault((d, "*"), {})[stem] = os.path.join(d, f)
    return {k: v for k, v in groups.items() if len(v) > 1}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", nargs="?", default=".")
    ap.add_argument("--base", default="en")
    a = ap.parse_args()
    groups = collect(a.root)
    if not groups:
        print("no locale JSON groups found")
        return 0
    bad = 0
    for (d, ns), langs in sorted(groups.items()):
        base = a.base if a.base in langs else sorted(langs)[0]
        try:
            ref = keys(json.load(open(langs[base], encoding="utf-8")))
        except Exception as e:
            print("FAIL %s: unreadable (%s)" % (langs[base], type(e).__name__)); bad += 1; continue
        for lang, path in sorted(langs.items()):
            if lang == base:
                continue
            try:
                ks = keys(json.load(open(path, encoding="utf-8")))
            except Exception as e:
                print("FAIL %s: unreadable (%s)" % (path, type(e).__name__)); bad += 1; continue
            miss, extra = sorted(ref - ks), sorted(ks - ref)
            if miss or extra:
                bad += 1
                print("FAIL %s vs %s: %d missing, %d extra" % (path, base, len(miss), len(extra)))
                for k in miss[:15]: print("  - missing " + k)
                for k in extra[:15]: print("  + extra   " + k)
    print("i18n parity: %s (%d group(s))" % ("OK" if not bad else "%d problem(s)" % bad, len(groups)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
