#!/usr/bin/env bash
# Runs every flow in order and prints a pass/fail table. Usage: maestro/run.sh [device-id]
set -u
export PATH="$PATH:$HOME/.maestro/bin"
cd "$(dirname "$0")/flows"
status=0
if command -v timeout >/dev/null; then TMO="timeout 600"; elif command -v gtimeout >/dev/null; then TMO="gtimeout 600"; else TMO=""; fi
mkdir -p "$(dirname "$0")/shots" 2>/dev/null; SH="$(cd .. && pwd)/shots"; mkdir -p "$SH"
for flow in *.yaml; do
  echo; echo "=== $flow ($(date +%H:%M:%S)) ==="
  if $TMO maestro ${1:+--device "$1"} test --no-ansi "$flow"; then echo "RESULT $flow: PASS"; else echo "RESULT $flow: FAIL"; status=1; fi
  adb ${1:+-s "$1"} exec-out screencap -p > "$SH/${flow%.yaml}-end.png" 2>/dev/null || true
  adb ${1:+-s "$1"} shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && adb ${1:+-s "$1"} pull /sdcard/ui.xml "$SH/${flow%.yaml}-end.xml" >/dev/null 2>&1 || true
done
exit $status
