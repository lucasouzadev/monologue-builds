#!/usr/bin/env bash
# Installs the APK, runs every flow, then prints the crash buffer (FATAL blocks) so a native stop is explained in the log.
set -u
cd "$(dirname "$0")/.."
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1
sleep 25  # let the system finish booting; a loaded emulator ANRs the launcher otherwise
adb install -r Monologue.apk | tail -1
# (Media fixtures disabled: pushing/scanning large images killed the emulator in CI. The Photos flow runs against the permission-granted, possibly empty gallery.)
for perm in READ_MEDIA_IMAGES READ_MEDIA_VISUAL_USER_SELECTED READ_EXTERNAL_STORAGE; do adb shell pm grant app.monologue.mobile android.permission.$perm >/dev/null 2>&1 || true; done
adb logcat -c
bash maestro/run.sh
code=$?
echo; echo "=== logcat crash buffer ==="
timeout 30 adb logcat -d -b crash | tail -80
echo; echo "=== app errors (ReactNativeJS / FATAL) ==="
timeout 30 adb logcat -d | grep -E "FATAL EXCEPTION|ReactNativeJS.*(Error|error|Exception)|signal 11|Fatal signal|has died|Force finishing" | tail -60
exit $code
