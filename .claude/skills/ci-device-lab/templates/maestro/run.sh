#!/usr/bin/env bash
# Run Maestro flows and keep only flow names + PASS/FAIL in the public summary.
# Usage: bash maestro/run.sh <android|ios>   Env: FLOWS (file/folder), E2E_EMAIL/E2E_PASSWORD (optional)
set -uo pipefail
platform="${1:?android|ios}"
FLOWS="${FLOWS:-maestro/flows}"
here="$(cd "$(dirname "$0")" && pwd)"
[ -e "$FLOWS" ] || FLOWS="$here/flows"
out="${RUNNER_TEMP:-/tmp}/maestro"; mkdir -p "$out"
tags=()
if [ -z "${E2E_EMAIL:-}" ]; then tags=(--exclude-tags login); echo "no test account: skipping flows tagged 'login'"; fi
env_args=(); [ -n "${E2E_EMAIL:-}" ] && env_args=(-e "E2E_EMAIL=$E2E_EMAIL" -e "E2E_PASSWORD=$E2E_PASSWORD")
[ -n "${APP_ID:-}" ] && env_args+=(-e "APP_ID=$APP_ID")
maestro test "$FLOWS" "${tags[@]}" "${env_args[@]}" \
  --format junit --output "$out/report.xml" --test-output-dir "$out/artifacts" > "$out/maestro.log" 2>&1
rc=$?
python3 - "$out/report.xml" "$platform" > "$out/summary.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
p, plat = sys.argv[1], sys.argv[2]
print(f"### Maestro {plat}")
try:
    for tc in ET.parse(p).getroot().iter("testcase"):
        bad = tc.find("failure") is not None or tc.find("error") is not None
        print(f"- {'FAIL' if bad else 'PASS'} {tc.get('name')}")
except Exception:
    print("- no report (see encrypted evidence)")
PY
# Scrub the test password from text files before they are packaged.
if [ -n "${E2E_PASSWORD:-}" ]; then
  grep -rlF -- "$E2E_PASSWORD" "$out" 2>/dev/null | while read -r f; do sed -i.bak "s|$(printf '%s' "$E2E_PASSWORD" | sed 's/[|&/\]/\\&/g')|***|g" "$f" && rm -f "$f.bak"; done
fi
cat "$out/summary.txt"
exit $rc
