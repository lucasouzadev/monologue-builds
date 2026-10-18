#!/usr/bin/env bash
# Runs every flow in order and prints a pass/fail table. Usage: [FLOWS_DIR=dir] [SHOT_PREFIX=dark-] maestro/run.sh [device-id]
set -u
export PATH="$PATH:$HOME/.maestro/bin"
ROOT="$(cd "$(dirname "$0")" && pwd)"
case "${FLOW_ONLY:-}" in
  '@huge '*)
    # Targeted accessibility check before the long full-suite/audit gate.
    if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then
      xcrun simctl ui "$1" content_size accessibility-extra-extra-extra-large
    else
      adb shell settings put system font_scale 2.0
    fi
    mkdir -p "$ROOT/audit-huge"
    cp -R "$ROOT/flows/support" "$ROOT/audit-huge/"
    for targeted_file in "$ROOT"/flows/*.yaml; do
      sed 's/takeScreenshot: /takeScreenshot: huge-/' "$targeted_file" > "$ROOT/audit-huge/${targeted_file##*/}"
    done
    FLOW_ONLY="${FLOW_ONLY#@huge }"
    FLOWS_DIR="$ROOT/audit-huge"
    SHOT_PREFIX=huge-
    ;;
esac
cd "${FLOWS_DIR:-$ROOT/flows}"
PFX="${SHOT_PREFIX:-}"
status=0
if command -v timeout >/dev/null; then TMO="timeout ${FLOW_TIMEOUT:-360}"; T30="timeout 30"; elif command -v gtimeout >/dev/null; then TMO="gtimeout ${FLOW_TIMEOUT:-360}"; T30="gtimeout 30"; else TMO=""; T30=""; fi
SH="$ROOT/shots"; mkdir -p "$SH"
export MAESTRO_EXPECTED_UPDATE_ID="${EXPECTED_UPDATE_ID:-}"
for flow in *.yaml; do
  # FLOW_ONLY="00-warm-update 00b-build-stamp 28-sheet-visuals": a verification subset (the staging gate runs this first, then the full suite).
  if [ -n "${FLOW_ONLY:-}" ] && ! echo " $FLOW_ONLY " | grep -q " ${flow%.yaml} "; then continue; fi
  echo; echo "=== $flow ($(date +%H:%M:%S)) ==="
  flow_result=0
  $TMO maestro ${1:+--device "$1"} test --no-ansi -e "MAESTRO_EXPECTED_UPDATE_ID=$MAESTRO_EXPECTED_UPDATE_ID" "$flow" || flow_result=$?
  if [ "$flow" = "00b-build-stamp.yaml" ] && [ "$flow_result" -ne 0 ]; then
    # Before feature acceptance only: slow update downloads can need another
    # launch. Each bounded retry must still prove the exact expected OTA stamp.
    for bootstrap_attempt in 1 2; do
      echo "=== initial OTA source retry $bootstrap_attempt (no feature acceptance yet) ==="
      sleep 45
      if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then
        xcrun simctl terminate "$1" app.monologue.mobile >/dev/null 2>&1 || true
      elif command -v adb >/dev/null; then
        adb shell am force-stop app.monologue.mobile >/dev/null 2>&1 || true
      fi
      flow_result=0
      $TMO maestro ${1:+--device "$1"} test --no-ansi -e "MAESTRO_EXPECTED_UPDATE_ID=$MAESTRO_EXPECTED_UPDATE_ID" "$flow" || flow_result=$?
      [ "$flow_result" -eq 0 ] && break
    done
  fi
  if [ "$flow_result" -eq 0 ]; then echo "RESULT $flow: PASS"; else
    echo "RESULT $flow: FAIL"; status=1
    # A wrong/embedded OTA makes every later result invalid; publish the failure image and stop.
    if [ "$flow" = "00b-build-stamp.yaml" ]; then
      if command -v adb >/dev/null && [ -z "${1:-}" ]; then
        echo '=== startup diagnostics after OTA gate failure ==='
        timeout 20 adb logcat -d -b all 2>/dev/null | grep -E 'FATAL|AndroidRuntime|ReactNativeJS|JavascriptException|ExpoBlur|GaussianBlur|ErrorRecovery|Unable to load' | tail -100
        timeout 20 adb exec-out screencap -p > "$SH/${PFX}${flow%.yaml}-end.png" 2>/dev/null || true
        adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && adb pull /sdcard/ui.xml "$SH/${PFX}${flow%.yaml}-end.xml" >/dev/null 2>&1 || true
      fi
      # The app's recovery surface prints the caught error ("Name: message", testID recovery-detail). Only that one line is made public:
      # it is an exception from the code, not user content, and without it a release-binary launch failure cannot be diagnosed.
      if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then
        xcrun simctl io "$1" screenshot "$SH/${PFX}${flow%.yaml}-end.png" >/dev/null 2>&1 || true
        $T30 maestro --device "$1" hierarchy 2>/dev/null | python3 -c '
import json, sys
def walk(n):
    a = n.get("attributes", {}) if isinstance(n, dict) else {}
    if "recovery-detail" in a.values():
        print("RECOVERY " + (a.get("text") or a.get("accessibilityText") or "").strip()[:240])
    for c in (n.get("children") or []) if isinstance(n, dict) else []:
        walk(c)
try:
    walk(json.load(sys.stdin))
except Exception as e:
    print("RECOVERY (hierarchy unreadable: %s)" % type(e).__name__)
' || true
      fi
      exit "$status"
    fi
    # Android: what the app logged just now (the circular buffer rolls over within minutes, so it is read per failure).
    if command -v adb >/dev/null && [ -z "${1:-}" ]; then
      echo "--- logcat after $flow (app, JS, crashes) ---"
      timeout 20 adb logcat -d 2>/dev/null | grep -E "ReactNativeJS|FATAL|AndroidRuntime: |JavascriptException|FabricUIManager|windowRecomposer|IllegalStateException|handleHostException|ErrorRecovery|Unhandled" | grep -v "Maestro\|Tried to enqueue" | tail -30
      timeout 20 adb logcat -d 2>/dev/null | grep -m1 -A60 "IllegalStateException: Cannot locate" | grep -E "Cannot locate|expo|compose|Compose|morphlet|monologue|keyboardcontroller|swmansion|facebook.react.views|at androidx" | head -40
      echo "--- end logcat ---"
    fi
  fi
  if [ "$flow" = "00-warm-update.yaml" ]; then
    # A notVisible assertion on an absent node returns immediately; it never
    # waits for OTA. Keep this real download window outside the UI assertions.
    sleep 45
    if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then
      xcrun simctl terminate "$1" app.monologue.mobile >/dev/null 2>&1 || true
    elif command -v adb >/dev/null; then
      adb ${1:+-s "$1"} shell am force-stop app.monologue.mobile >/dev/null 2>&1 || true
    fi
  fi
  if command -v xcrun >/dev/null && [ -n "${1:-}" ]; then xcrun simctl io "$1" screenshot "$SH/${PFX}${flow%.yaml}-end.png" >/dev/null 2>&1 || true
  elif command -v adb >/dev/null; then
    $T30 adb ${1:+-s "$1"} exec-out screencap -p > "$SH/${PFX}${flow%.yaml}-end.png" 2>/dev/null || true
    adb ${1:+-s "$1"} shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && adb ${1:+-s "$1"} pull /sdcard/ui.xml "$SH/${PFX}${flow%.yaml}-end.xml" >/dev/null 2>&1 || true
  fi
# A feature flow may relaunch the app. Recheck its source after the capture.
if [ -n "${FLOW_ONLY:-}" ] && [ -n "${EXPECTED_UPDATE_ID:-}" ] && [ "$flow" != "00-warm-update.yaml" ] && [ "$flow" != "00b-build-stamp.yaml" ]; then
  echo '=== post-flow OTA stamp (after all relaunches) ==='
  if $TMO maestro ${1:+--device "$1"} test --no-ansi -e "MAESTRO_EXPECTED_UPDATE_ID=$MAESTRO_EXPECTED_UPDATE_ID" 00b-build-stamp.yaml; then
    echo 'RESULT post-flow OTA stamp: PASS'
  else
    echo 'RESULT post-flow OTA stamp: FAIL'
    # A driver/launch timeout needs evidence too; previously it exited before
    # saving the screen or crash buffer and could not be diagnosed.
    if command -v adb >/dev/null && [ -z "${1:-}" ]; then
      timeout 20 adb logcat -d -b all 2>/dev/null | grep -E 'FATAL|AndroidRuntime|ANR in|JavascriptException|ErrorRecovery|Unable to load' | tail -80
      timeout 10 adb exec-out screencap -p > "$SH/${PFX}post-source-failure.png" 2>/dev/null || true
      timeout 10 adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && adb pull /sdcard/ui.xml "$SH/${PFX}post-source-failure.xml" >/dev/null 2>&1 || true
    elif command -v xcrun >/dev/null && [ -n "${1:-}" ]; then
      xcrun simctl io "$1" screenshot "$SH/${PFX}post-source-failure.png" >/dev/null 2>&1 || true
    fi
    exit 1
  fi
fi
done

exit $status
