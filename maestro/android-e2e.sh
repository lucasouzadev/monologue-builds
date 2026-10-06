#!/usr/bin/env bash
# Installs the APK, runs every flow, then prints the crash buffer (FATAL blocks) so a native stop is explained in the log.
set -u
cd "$(dirname "$0")/.."
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1
sleep 25  # let the system finish booting; a loaded emulator ANRs the launcher otherwise
adb install -r Monologue.apk | tail -1
adb logcat -c
bash maestro/run.sh
code=$?
echo; echo "=== logcat crash buffer ==="
adb logcat -d -b crash | tail -80
echo; echo "=== app errors (ReactNativeJS / FATAL) ==="
adb logcat -d | grep -E "FATAL EXCEPTION|ReactNativeJS.*(Error|error|Exception)|signal 11|Fatal signal|has died|Force finishing" | tail -60
exit $code
