#!/usr/bin/env python3
"""agent-kit PR quality check (stdlib only). Checks the *honesty and structure* of a PR, not whether the code is right.

  pr_quality.py --body-file PR.md [--git-base origin/main]            local lint before opening a PR
  pr_quality.py --body-env PR_BODY --gh OWNER/REPO NUMBER             in CI (needs GH_TOKEN with pull-requests: read)
  options: --config .github/pr-quality.json  --files-json FILE (tests)  --draft  --summary-file FILE

FAIL (exit 1): required sections missing, unfilled evidence rows, PASS without evidence, N/A / BLOCKED / NOT RUN without a
reason, delivery channel left as the whole legend, placeholders left, a rule's forbidden pattern added (e.g. a secret).
WARN (never fails): risk areas touched, source changed without tests, big PR, unchecked boxes, draft PR.
A passing check means the PR is well-formed and honest-looking, not that it is correct: review is still human.
"""
import argparse, fnmatch, json, os, re, subprocess, sys

DEFAULT = {
    "required_sections": [["summary", "resumo", "scope", "task"], ["quality-g1", r"\bg1\b"], ["quality-g2", r"\bg2\b"]],
    "evidence_sections": ["quality-g2", r"\bg2\b"],
    "states": ["PASS", "FAIL", "BLOCKED", "NOT RUN", "N/A", "PASSOU", "FALHOU", "BLOQUEADO", "NÃO EXECUTADO", "NAO EXECUTADO", "NÃO APLICÁVEL", "NAO APLICAVEL"],
    "needs_reason": ["BLOCKED", "NOT RUN", "N/A", "BLOQUEADO", "NÃO EXECUTADO", "NAO EXECUTADO", "NÃO APLICÁVEL", "NAO APLICAVEL"],
    "needs_evidence": ["PASS", "PASSOU"],
    "delivery": {"labels": ["delivery", "entrega"], "options": ["OTA", "build", "server", "servidor", "N/A"], "required": False},
    "min_body_chars": 200,
    "placeholders": [r"\bTODO\b", r"\bTBD\b", r"<fill[^>]*>", r"\bXXX\b", r"lorem ipsum"],
    "skip_authors": ["dependabot[bot]", "renovate[bot]"],
    "big_pr_lines": 800,
    "rules": [
        {"id": "secret-in-diff", "severity": "fail", "paths": ["*"], "message": "possible secret added",
         "forbid_added": ["-----BEGIN [A-Z ]*PRIVATE KEY-----", r"\bghp_[A-Za-z0-9]{30,}", r"\bgithub_pat_[A-Za-z0-9_]{30,}",
                          r"\bAKIA[0-9A-Z]{16}\b", r"\bxox[abp]-[A-Za-z0-9-]{10,}", r"\bsk_live_[A-Za-z0-9]{16,}"]},
        {"id": "pull-request-target", "severity": "fail", "paths": [".github/workflows/*"],
         "message": "pull_request_target runs with secrets on untrusted code", "forbid_added": [r"^\s*pull_request_target\s*:"]},
    ],
    "areas": [
        {"name": "CI workflows", "paths": [".github/workflows/*"], "remind": "Read the whole diff for secrets and triggers; anything that builds or deploys stays dispatch-only."},
        {"name": "Agent hooks / config", "paths": [".claude/*", "AGENTS.md", "CLAUDE.md", ".cursor/*"], "remind": "Runs on every agent session: review like code."},
        {"name": "Migrations / database", "paths": ["*migrations/*", "*.sql"], "remind": "Rollback plan; compatible with clients already in the field; cross-user denial test."},
        {"name": "Dependencies", "paths": ["package.json", "*lock*", "Gemfile*", "Podfile*", "*build.gradle*", "requirements*.txt", "go.mod", "Cargo.toml"], "remind": "Vulnerability scan, licence, install scripts; lockfile committed."},
        {"name": "Native shell", "paths": ["ios/*", "android/*", "*.entitlements", "*Info.plist", "*AndroidManifest.xml", "capacitor.config.*", "app.config.*"], "remind": "Needs a new native build, not an OTA."},
        {"name": "Generated / synced files", "paths": ["*/public/assets/*", "ios/App/App/public/*", "android/app/src/main/assets/public/*", "*/Pods/*", "dist/*", "build/*", "*.xcuserstate", "*xcuserdata*", "*.tsbuildinfo", "*/.expo/*", "*/DerivedData/*"], "remind": "Usually produced by a build or native sync, not by the change itself; confirm each file belongs in this PR (stray sync files are a common cause of reverts)."},
        {"name": "Auth / security", "paths": ["*auth*", "*security*", "*rls*", "*policy*", "*permission*"], "remind": "Authorization test: user A cannot reach user B."},
    ],
    "tests_expected": {"source": ["src/*", "*/src/*", "apps/*", "packages/*", "services/*", "lib/*", "app/*"], "tests": ["*test*", "*spec*", "*__tests__*", "*e2e*", "*maestro*"]},
}


def load_config(path):
    cfg = json.loads(json.dumps(DEFAULT))
    if path and os.path.exists(path):
        with open(path) as fh:
            user = json.load(fh)
        for k, v in user.items():
            if k == "rules_extend":
                cfg["rules"] += v
            elif k == "areas_extend":
                cfg["areas"] += v
            else:
                cfg[k] = v
    return cfg


def sections(body):
    out, cur, buf = [], None, []
    for line in body.splitlines():
        m = re.match(r"^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$", line)
        if m:
            if cur is not None:
                out.append((cur, "\n".join(buf)))
            cur, buf = m.group(1), []
        elif cur is not None:
            buf.append(line)
    if cur is not None:
        out.append((cur, "\n".join(buf)))
    return out


def has_heading(secs, alts):
    return any(re.search(a, h, re.I) for h, _ in secs for a in alts)


def norm_state(cell):
    c = re.sub(r"[*_`]", "", cell).strip()
    return c


def evaluate(body, files, cfg, draft=False, author=""):
    fails, warns, notes = [], [], []
    if author and author in cfg["skip_authors"]:
        return [], [], [f"skipped: automated author {author}"]
    b = body or ""
    if len(b.strip()) < cfg["min_body_chars"]:
        fails.append(f"PR description too short ({len(b.strip())} < {cfg['min_body_chars']} chars): fill the template")
    secs = sections(b)
    for alts in cfg["required_sections"]:
        if not has_heading(secs, alts):
            fails.append(f"missing section: one of {alts}")
    for pat in cfg["placeholders"]:
        if re.search(pat, b, re.I):
            fails.append(f"placeholder left in the description: /{pat}/")
    # evidence tables
    states = sorted(cfg["states"], key=len, reverse=True)
    st_rx = re.compile(r"^(" + "|".join(re.escape(s) for s in states) + r")\b[\s:;,\-–—]*(.*)$", re.I)
    unfilled = 0
    for h, text in secs:
        if not any(re.search(a, h, re.I) for a in cfg["evidence_sections"]):
            continue
        tl = text.splitlines()
        sep = lambda l: bool(re.match(r"^\s*\|?[\s:\-|]+\|?\s*$", l)) and "-" in l
        for idx, line in enumerate(tl):
            if "|" not in line or sep(line) or (idx + 1 < len(tl) and sep(tl[idx + 1]) and "|" in tl[idx + 1]):
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) < 2:
                continue
            label, state = cells[0], norm_state(cells[1])
            if re.search(r"^(evidence|prova|proof|check)\b", label, re.I) and re.search(r"PASS|state|estado", state, re.I):
                continue  # header row with the legend
            if not state or re.search(r"(PASS|PASSOU)\s*/\s*(FAIL|FALHOU)", state, re.I):
                unfilled += 1
                continue
            m = st_rx.match(state)
            if not m:
                fails.append(f"evidence row '{label[:50]}': state must start with one of PASS/FAIL/BLOCKED/NOT RUN/N/A (got '{state[:30]}')")
                continue
            st, reason = m.group(1).upper(), m.group(2).strip()
            evidence = cells[2].strip() if len(cells) > 2 else ""
            if st in [s.upper() for s in cfg["needs_reason"]] and len(reason) < 3 and len(evidence) < 3:
                fails.append(f"evidence row '{label[:50]}': {st} needs a reason")
            if st in [s.upper() for s in cfg["needs_evidence"]] and (len(evidence) < 3 or evidence in ("-", "—", "n/a", "N/A")):
                fails.append(f"evidence row '{label[:50]}': PASS without evidence (command, SHA, run or link)")
    if unfilled:
        fails.append(f"{unfilled} evidence row(s) still unfilled: write PASS/FAIL/BLOCKED/NOT RUN/N/A + evidence or reason")
    # delivery channel
    d = cfg.get("delivery") or {}
    if d.get("labels"):
        line = next((l for l in b.splitlines() if any(re.search(r"\b" + re.escape(lab) + r"\b\s*\**\s*:", l, re.I) for lab in d["labels"])), None)
        if line is None:
            if d.get("required"):
                fails.append("delivery channel not declared")
        else:
            tail = line.split(":", 1)[1]
            found = [o for o in d["options"] if re.search(r"(?<![\w])" + re.escape(o) + r"(?![\w])", tail, re.I)]
            if len(found) > 1 and re.search(r"\s/\s", tail):
                fails.append("delivery channel left as the whole legend: keep only the one that applies")
    # files
    adds = {f["filename"]: [l[1:] for l in (f.get("patch") or "").splitlines() if l.startswith("+") and not l.startswith("+++")] for f in files}
    for r in cfg["rules"]:
        for fn, lines in adds.items():
            if not any(fnmatch.fnmatch(fn, p) for p in r["paths"]):
                continue
            for pat in r["forbid_added"]:
                if any(re.search(pat, l) for l in lines):
                    (fails if r.get("severity", "fail") == "fail" else warns).append(f"{r['id']}: {r['message']} ({fn})")
                    break
    hit = {}
    for f in files:
        for a in cfg["areas"]:
            if any(fnmatch.fnmatch(f["filename"], p) for p in a["paths"]):
                hit.setdefault(a["name"], [a["remind"], []])[1].append(f["filename"])
    for name, (remind, fl) in hit.items():
        warns.append(f"area touched — {name} ({len(fl)} file(s), e.g. {fl[0]}): {remind}")
    te = cfg.get("tests_expected")
    if te and files:
        src = [f["filename"] for f in files if any(fnmatch.fnmatch(f["filename"], p) for p in te["source"]) and not any(fnmatch.fnmatch(f["filename"], t) for t in te["tests"])]
        tests = [f["filename"] for f in files if any(fnmatch.fnmatch(f["filename"], t) for t in te["tests"])]
        if src and not tests:
            warns.append(f"{len(src)} source file(s) changed and no test/E2E file changed: say why in the description")
    lines = sum(int(f.get("additions", 0)) + int(f.get("deletions", 0)) for f in files)
    if lines > cfg["big_pr_lines"]:
        warns.append(f"big PR ({lines} changed lines): consider splitting")
    unchecked = len(re.findall(r"^\s*[-*]\s+\[ \]", b, re.M))
    if unchecked:
        warns.append(f"{unchecked} unchecked box(es): tick them or explain why not")
    if draft:
        notes.append("draft PR: failures are reported as warnings until it is ready for review")
        warns += [f"(draft) {f}" for f in fails]
        fails = []
    return fails, warns, notes


def files_from_git(base):
    out = subprocess.run(["git", "diff", "-U0", "--no-color", f"{base}...HEAD"], capture_output=True, text=True).stdout
    files, cur = [], None
    for line in out.splitlines():
        if line.startswith("diff --git "):
            cur = {"filename": line.split(" b/", 1)[-1], "patch": "", "additions": 0, "deletions": 0}
            files.append(cur)
        elif cur is not None and (line.startswith("+") or line.startswith("-")) and not line.startswith(("+++", "---")):
            cur["patch"] += line + "\n"
            cur["additions" if line[0] == "+" else "deletions"] += 1
    return files


def files_from_gh(repo, number):
    out = subprocess.run(["gh", "api", f"repos/{repo}/pulls/{number}/files", "--paginate", "--jq",
                          ".[] | {filename,additions,deletions,patch}"], capture_output=True, text=True)
    if out.returncode != 0:
        print("::warning::could not list PR files:", out.stderr.strip()[:200])
        return []
    return [json.loads(l) for l in out.stdout.splitlines() if l.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--body-file"); ap.add_argument("--body-env"); ap.add_argument("--config", default=".github/pr-quality.json")
    ap.add_argument("--git-base"); ap.add_argument("--gh", nargs=2, metavar=("OWNER/REPO", "NUMBER")); ap.add_argument("--files-json")
    ap.add_argument("--draft", action="store_true"); ap.add_argument("--summary-file")
    a = ap.parse_args()
    if a.body_file:
        with open(a.body_file) as fh:
            body = fh.read()
    else:
        body = os.environ.get(a.body_env or "", "")
    if a.files_json:
        with open(a.files_json) as fh:
            files = json.load(fh)
    else:
        files = files_from_git(a.git_base) if a.git_base else files_from_gh(*a.gh) if a.gh else []
    draft = a.draft or os.environ.get("PR_DRAFT") == "true"
    fails, warns, notes = evaluate(body, files, load_config(a.config), draft, os.environ.get("PR_AUTHOR", ""))
    lines = ["## PR quality", ""]
    lines += [f"- ❌ {f}" for f in fails] + [f"- ⚠️ {w}" for w in warns] + [f"- ℹ️ {n}" for n in notes]
    if not fails:
        lines.append("- ✅ structure and evidence statements look well-formed (this does not prove the change is correct)")
    text = "\n".join(lines)
    print(text)
    for f in fails:
        print(f"::error title=PR quality::{f}")
    s = a.summary_file or os.environ.get("GITHUB_STEP_SUMMARY")
    if s:
        with open(s, "a") as fh:
            fh.write(text + "\n")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
