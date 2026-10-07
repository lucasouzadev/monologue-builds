#!/usr/bin/env bash
# Helper for the manual workflows of lucasouzadev/monologue-builds. Uses only the GitHub REST API through `gh api`
# (GraphQL is blocked in Claude Code cloud sessions, so `gh workflow run` does NOT work there).
#
#   tools/ci.sh ota [android|ios|all] [source_ref] [message]   publish a JS/asset-only OTA to channel "development"
#   tools/ci.sh e2e-android [build_run_id]                      Maestro on an Android emulator (APK from a build.yml run)
#   tools/ci.sh e2e-ios [source_ref]                            Maestro on an iOS simulator (compiles/caches a SIMULATOR build)
#   tools/ci.sh status [workflow-file]                          last 5 runs
#   tools/ci.sh wait <run_id>                                   block until the run completes, print conclusion
#   tools/ci.sh results <run_id>                                print every "RESULT <flow>: PASS|FAIL" line of the run
#   tools/ci.sh shots android|ios [dir]                         download the screenshots published by the last E2E
#
# e2e-ios and every native build REQUIRE the owner's explicit permission (root AGENTS.md "Native builds require
# explicit user permission"). OTA does not.
set -euo pipefail

REPO="${BUILDS_REPO:-lucasouzadev/monologue-builds}"
BRANCH_DEFAULT="${SOURCE_REF:-claude/m1-native-009f1-liquid-morph-foundation}"
BASELINE="${NATIVE_BASELINE:-07}"
APK_BUILD_RUN="${APK_BUILD_RUN:-37483731148}" # build.yml run whose APK the Android E2E installs (old APK + OTA warm-up)

dispatch() { # workflow-file key=value...
  local wf="$1"; shift
  local args=(-f ref=main)
  for kv in "$@"; do args+=(-f "inputs[${kv%%=*}]=${kv#*=}"); done
  gh api -X POST "repos/$REPO/actions/workflows/$wf/dispatches" "${args[@]}"
  sleep 20
  gh api "repos/$REPO/actions/workflows/$wf/runs?per_page=1" --jq '.workflow_runs[0]|"run \(.id) \(.status) \(.html_url)"'
}

last_run_id() { gh api "repos/$REPO/actions/workflows/$1/runs?per_page=1" --jq '.workflow_runs[0].id'; }

wait_run() {
  until [ "$(gh api "repos/$REPO/actions/runs/$1" --jq .status)" = completed ]; do sleep 15; done
  gh api "repos/$REPO/actions/runs/$1" --jq .conclusion
}

results() {
  local job; job=$(gh api "repos/$REPO/actions/runs/$1/jobs" --jq '.jobs[0].id')
  gh api "repos/$REPO/actions/jobs/$job/logs" | grep -aE "RESULT |FATAL|AndroidRuntime" | cut -c30-140
}

cmd="${1:-}"; shift || true
case "$cmd" in
  ota)
    dispatch ota.yml "platform=${1:-android}" "channel=development" "source_ref=${2:-$BRANCH_DEFAULT}" \
      "native_baseline=$BASELINE" "message=${3:-OTA}" ;;
  e2e-android)
    dispatch e2e-android.yml "build_run_id=${1:-$APK_BUILD_RUN}" ;;
  e2e-ios)
    dispatch e2e-ios.yml "authorize_native_build=true" "source_ref=${1:-$BRANCH_DEFAULT}" "native_baseline=$BASELINE" ;;
  status)
    gh api "repos/$REPO/actions/${1:+workflows/$1/}runs?per_page=5" --jq '.workflow_runs[]|[.id,.name,.status,.conclusion,.created_at]|@tsv' ;;
  wait) wait_run "${1:?run id}" ;;
  results) results "${1:?run id}" ;;
  shots)
    platform="${1:?android|ios}"; dir="${2:-/tmp/shots-$platform}"
    tmp=$(mktemp -d); git clone -q --depth 1 --branch "screens-$platform" "https://github.com/$REPO.git" "$tmp"
    mkdir -p "$dir"; cp "$tmp"/*.png "$dir"/ ; rm -rf "$tmp"; ls "$dir" ;;
  *) sed -n 2,16p "$0"; exit 1 ;;
esac
