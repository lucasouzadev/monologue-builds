#!/usr/bin/env bash
# Installs the decrypted APK on the emulator and walks the core flow: launch, create a conversation, open it. Reads like a log.
set -u
exec 2>&1
T() { timeout "${1}" "${@:2}"; }
now() { date +%H:%M:%S; }
cd "$(dirname "$0")"
PKG=app.monologue.mobile
UI="python3 ui.py"
stage() { echo; echo "== $1 == ($(now))"; }
alive() { if [ -n "$(T 10 adb shell pidof $PKG)" ]; then echo "  process: alive"; else echo "  process: NOT RUNNING"; fi; }

echo "boot: $(now)"; T 120 adb install -r ../../Monologue.apk | tail -1
adb logcat -c
(adb logcat -v time > /tmp/full.log 2>&1 &)
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 30
stage "1 after launch"; alive; $UI show

stage "2 create conversation"
$UI tap "New conversation" "Create conversation" || true
sleep 4; alive; $UI show
T 10 adb shell input text "Teste"
sleep 1
$UI tap "Create conversation" || true
sleep 5; stage "3 home after create"; alive; $UI show

stage "4 open the conversation"
$UI tap "Teste" || true
sleep 10; alive; $UI show

stage "5 type and send a message"
T 10 adb shell input text "Ola"
sleep 1; $UI show
$UI tap "Send" || true
sleep 3; alive; $UI show

stage "logcat: crash buffer"
T 30 adb logcat -d -b crash | tail -60
stage "logcat: errors"
grep -E "AndroidRuntime|FATAL|ReactNativeJS|ReactNative|Hermes|monologue|Monologue|ANR" /tmp/full.log | tail -150
