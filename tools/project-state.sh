#!/usr/bin/env bash
# Project state BEFORE starting a round (owner 2026-10-20): what is on main, which branches moved recently, and what the builds repo has, so work starts from the
# newest state instead of a stale one. Read-only, git only (the gh CLI token is not valid in cloud sessions). Usage: tools/project-state.sh [app-checkout] [hours]
set -euo pipefail
APP="${1:-/home/user/monologue}"; HOURS="${2:-24}"
BUILDS="$(cd "$(dirname "$0")/.." && pwd)"
for repo in "$APP" "$BUILDS"; do
  [ -d "$repo/.git" ] || { echo "skip $repo (not a checkout)"; continue; }
  echo "== $(basename "$repo")"
  git -C "$repo" fetch -q origin 2>&1 | tail -1 || true
  echo "main: $(git -C "$repo" log -1 --format='%h %cI %s' origin/main | cut -c1-110)"
  echo "current branch: $(git -C "$repo" branch --show-current) | ahead/behind main: $(git -C "$repo" rev-list --left-right --count HEAD...origin/main | tr '\t' '/')"
  echo "branches that moved in the last ${HOURS}h:"
  git -C "$repo" for-each-ref --sort=-committerdate --format='%(committerdate:iso8601) %(refname:short) %(subject)' refs/remotes/origin \
    | awk -v since="$(date -u -d "-${HOURS} hours" +%Y-%m-%dT%H:%M 2>/dev/null || date -u -v-${HOURS}H +%Y-%m-%dT%H:%M)" '{ if ($1"T"substr($2,1,5) >= since) print "  " $0 }' | cut -c1-150 | head -8
done
echo "Also check the latest OTA runs (which SHA is on preview/testers) and E2E runs in Actions before dispatching anything."
