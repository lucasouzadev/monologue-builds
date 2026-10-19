#!/usr/bin/env bash
# Hands the app a plain-text share the way another Android app would (a SEND intent). Runs right before flow 96-share-text-android.
adb shell am force-stop app.monologue.mobile >/dev/null 2>&1
sleep 2
adb shell am start -W -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "texto compartilhado pelo teste" app.monologue.mobile >/dev/null 2>&1
