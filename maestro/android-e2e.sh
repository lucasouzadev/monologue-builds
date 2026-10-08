#!/usr/bin/env bash
# Installs the APK, runs every flow, then prints the crash buffer (FATAL blocks) so a native stop is explained in the log.
set -u
cd "$(dirname "$0")/.."
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1
sleep 25  # let the system finish booting; a loaded emulator ANRs the launcher otherwise
adb install -r Monologue.apk | tail -1
# (Media fixtures disabled: pushing/scanning large images killed the emulator in CI. The Photos flow runs against the permission-granted, possibly empty gallery.)
# Tiny PNG fixtures for the Photos panel (large pushes/screencaps are what killed the emulator before).
python3 - <<'PY'
import zlib, struct
def png(path, rgb, size=96):
    raw = b''.join(b'\x00' + bytes(rgb) * size for _ in range(size))
    def chunk(t, d): c = struct.pack('>I', len(d)) + t + d; return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
for i, c in enumerate([(200, 40, 30), (30, 120, 200), (60, 160, 80), (230, 180, 40)], 1): png(f'/tmp/fx{i}.png', c)
PY
for i in 1 2 3 4; do adb push /tmp/fx$i.png /sdcard/Pictures/fx$i.png >/dev/null 2>&1; adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/fx$i.png >/dev/null 2>&1; done
sleep 3
for perm in READ_MEDIA_IMAGES READ_MEDIA_VISUAL_USER_SELECTED READ_EXTERNAL_STORAGE; do adb shell pm grant app.monologue.mobile android.permission.$perm >/dev/null 2>&1 || true; done
adb logcat -c
if [ -f maestro/quick.txt ]; then
  # Quick diagnosis: only the flows listed in maestro/quick.txt, then the app's log.
  rm -rf maestro/flows-quick; mkdir -p maestro/flows-quick
  while read -r f; do [ -n "$f" ] && cp "maestro/flows/$f.yaml" maestro/flows-quick/; done < maestro/quick.txt
  FLOWS_DIR="$PWD/maestro/flows-quick" bash maestro/run.sh; code=$?
  echo "=== quick: app state ==="
  echo "pid: $(adb shell pidof app.monologue.mobile)"; adb shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -3
  echo "=== quick: app log (pid) ==="; PID=$(adb shell pidof app.monologue.mobile | tr -d '\r'); [ -n "$PID" ] && timeout 30 adb logcat -d --pid="$PID" | grep -v "Tried to enqueue runnable" | grep -E "ReactNativeJS|FATAL|Exception|Error|error|expo|Expo|Hermes|JS " | head -120
  echo "=== quick: events ==="; timeout 30 adb logcat -d -b events | grep -E "am_crash|am_anr|am_proc_died|am_proc_start|app.monologue" | tail -40
  exit $code
fi
bash maestro/run.sh
code=$?
echo "=== light pass: crash / JS errors from logcat ==="
adb logcat -d -b all 2>/dev/null | grep -E "FATAL EXCEPTION|AndroidRuntime|ReactNativeJS|Process: app.monologue|Force finishing|died|ANR in" | grep -v "Choreographer" | tail -60
# Re-seed: the light pass ends with deleted/renamed conversations (flows 11, 23, 24), and the later passes look for the "Ola" row. Flow 01 creates it again.
reseed() { rm -rf maestro/flows-seed; mkdir -p maestro/flows-seed; cp maestro/flows/01-create-open-send.yaml maestro/flows-seed/; FLOWS_DIR="$PWD/maestro/flows-seed" SHOT_PREFIX=seed- bash maestro/run.sh || true; }
# Dark pass: the same key flows with the system in dark mode, screenshots prefixed "dark-".
adb shell cmd uimode night yes >/dev/null 2>&1
reseed
rm -rf maestro/flows-dark; mkdir -p maestro/flows-dark
for f in 02-home-controls 07-home-list 08-message-actions 09-profile 05-composer-plus-menu 03-conversation-tools 10-rename-pin 12-editor-select 13-merge-search; do sed 's/takeScreenshot: /takeScreenshot: dark-/' maestro/flows/$f.yaml > maestro/flows-dark/$f.yaml; done
FLOWS_DIR="$PWD/maestro/flows-dark" SHOT_PREFIX=dark- bash maestro/run.sh || true
adb shell cmd uimode night no >/dev/null 2>&1
# Font-scale pass (Material 3 phase 6): home, home list, conversation tools and profile at 200 % system font size, screenshots
# prefixed "big-". Informational (never fails the run): the look is judged from the images.
adb shell settings put system font_scale 2.0 >/dev/null 2>&1
rm -rf maestro/flows-big; mkdir -p maestro/flows-big
for f in 02-home-controls 07-home-list 09-profile; do sed 's/takeScreenshot: /takeScreenshot: big-/' maestro/flows/$f.yaml > maestro/flows-big/$f.yaml; done
FLOWS_DIR="$PWD/maestro/flows-big" SHOT_PREFIX=big- bash maestro/run.sh || true
adb shell settings put system font_scale 1.0 >/dev/null 2>&1
# Stress pass (owner request: performance on both platforms): burst sends and limit-sized messages through the real conversation
# screen (the lab opens on the development update channel), then Reply Focus and a fast history scroll. Informational.
adb shell am force-stop app.monologue.mobile >/dev/null 2>&1
adb shell am start -W -a android.intent.action.VIEW -d "monologue://__diagnostics/stress" app.monologue.mobile >/dev/null 2>&1
sleep 8
FLOWS_DIR="$PWD/maestro/stress-android" SHOT_PREFIX=stress- FLOW_TIMEOUT=420 bash maestro/run.sh || true
echo; echo "=== logcat crash buffer ==="
timeout 30 adb logcat -d -b crash | tail -80
echo; echo "=== app errors (ReactNativeJS / FATAL) ==="
timeout 30 adb logcat -d | grep -E "FATAL EXCEPTION|ReactNativeJS.*(Error|error|Exception)|signal 11|Fatal signal|has died|Force finishing" | tail -60
exit $code
