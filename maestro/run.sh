#!/usr/bin/env bash
# Runs every flow in order and prints a pass/fail table. Usage: [FLOWS_DIR=dir] [SHOT_PREFIX=dark-] maestro/run.sh [device-id]
set -u
export PATH="$PATH:$HOME/.maestro/bin"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${FLOWS_DIR:-$ROOT/flows}"
PFX="${SHOT_PREFIX:-}"
status=0
if command -v timeout >/dev/null; then TMO="timeout ${FLOW_TIMEOUT:-360}"; T30="timeout 30"; elif command -v gtimeout >/dev/null; then TMO="gtimeout ${FLOW_TIMEOUT:-360}"; T30="gtimeout 30"; else TMO=""; T30=""; fi
SH="$ROOT/shots"; mkdir -p "$SH"
for flow in *.yaml; do
  echo; echo "=== $flow ($(date +%H:%M:%S)) ==="
  if $TMO maestro ${1:+--device "$1"} test --no-ansi "$flow"; then echo "RESULT $flow: PASS"; else
    echo "RESULT $flow: FAIL"; status=1
    # Android: what the app logged just now (the circular buffer rolls over within minutes, so it is read per failure).
    if command -v adb >/dev/null && [ -z "${1:-}" ]; then
      echo "--- logcat after $flow (app, JS, crashes) ---"
      timeout 20 adb logcat -d 2>/dev/null | grep -E "ReactNativeJS|FATAL|AndroidRuntime: |JavascriptException|FabricUIManager|windowRecomposer|IllegalStateException|handleHostException|ErrorRecovery|Unhandled" | grep -v "Maestro\|Tried to enqueue" | tail -30
      timeout 20 adb logcat -d 2>/dev/null | grep -m1 -A60 "IllegalStateException: Cannot locate" | grep -E "Cannot locate|expo|compose|Compose|morphlet|monologue|keyboardcontroller|swmansion|facebook.react.views|at androidx" | head -40
      echo "--- end logcat ---"
    fi
  fi
  if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then xcrun simctl io "$1" screenshot "$SH/${PFX}${flow%.yaml}-end.png" >/dev/null 2>&1 || true
  elif command -v adb >/dev/null; then
    $T30 adb ${1:+-s "$1"} exec-out screencap -p > "$SH/${PFX}${flow%.yaml}-end.png" 2>/dev/null || true
    adb ${1:+-s "$1"} shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && adb ${1:+-s "$1"} pull /sdcard/ui.xml "$SH/${PFX}${flow%.yaml}-end.xml" >/dev/null 2>&1 || true
  fi
done
exit $status
