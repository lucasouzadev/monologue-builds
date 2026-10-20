#!/usr/bin/env bash
# Hands the app a plain-text share the way another Android app would (a SEND intent). Runs right before flow 96-share-text-android.
# Its output goes to the (encrypted) Maestro log so a failure shows whether the intent resolved to the app.
adb shell am force-stop app.monologue.mobile >/dev/null 2>&1
sleep 2
echo "[hook 96] activities that handle SEND text/plain for the app:"
adb shell pm query-activities --brief -a android.intent.action.SEND -t text/plain app.monologue.mobile 2>&1 | head -8
echo "[hook 96] am start:"
adb shell am start -W -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "texto compartilhado pelo teste" app.monologue.mobile 2>&1 | head -12
sleep 3
echo "[hook 96] resumed activity after the intent:"
adb shell dumpsys activity activities 2>&1 | grep -m2 -E 'topResumedActivity|mResumedActivity'
