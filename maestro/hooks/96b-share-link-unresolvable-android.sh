#!/usr/bin/env bash
# Hands the app a link whose host does not exist (a SEND intent), the way another Android app would. The TLD is a real one so Android's WEB_URL pattern treats it as a link
# (".invalid" is not in that pattern's list and would arrive as plain text, which is the OTHER flow, 96). Output goes to the encrypted Maestro log.
adb shell am force-stop app.monologue.mobile >/dev/null 2>&1
sleep 2
adb shell "am start -W -a android.intent.action.SEND -t text/plain -p app.monologue.mobile --es android.intent.extra.TEXT 'https://monologue-qa-nonexistent-host-9f3a.com/page'" 2>&1 | head -8
sleep 3
adb shell dumpsys activity activities 2>&1 | grep -m1 -E 'topResumedActivity|mResumedActivity'
