#!/usr/bin/env bash
# UI/UX audit passes (owner request 2026-10-08): the same screens under the conditions that change how they look, so design and
# responsiveness are judged from images instead of hunted item by item. Usage: audit-passes.sh android|ios [simulator-udid]
#   dark   : dark appearance, normal text
#   large  : light, large text (Android 130 %, iOS extra-extra-large)
#   huge   : light, the largest accessibility text (Android 200 %, iOS accessibility-extra-extra-extra-large)
# Screenshots are prefixed "dark-", "large-", "huge-" and published with the others (screens-android / screens-ios).
set -u
PLATFORM="${1:?android|ios}"; UDID="${2:-}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/.."
DARK_FLOWS="02-home-controls 03-conversation-tools 05-composer-plus-menu 06-photos-panel 07-home-list 08-message-actions 09-profile 10-rename-pin 12-editor-select 13-merge-search 15-conversation-panel 19-search-marks 21-fonts 22-activity 25-camera-scanner 26-favorites-timeline"
SCALE_FLOWS="02-home-controls 03-conversation-tools 05-composer-plus-menu 07-home-list 08-message-actions 09-profile 15-conversation-panel 19-search-marks 22-activity 25-camera-scanner 26-favorites-timeline"

appearance() { # light|dark
  if [ "$PLATFORM" = android ]; then adb shell cmd uimode night "$([ "$1" = dark ] && echo yes || echo no)" >/dev/null 2>&1
  else xcrun simctl ui "$UDID" appearance "$1" >/dev/null 2>&1; fi
}
text_size() { # normal|large|huge
  if [ "$PLATFORM" = android ]; then
    case "$1" in normal) v=1.0;; large) v=1.3;; huge) v=2.0;; esac; adb shell settings put system font_scale "$v" >/dev/null 2>&1
  else
    case "$1" in normal) v=large;; large) v=extra-extra-large;; huge) v=accessibility-extra-extra-extra-large;; esac; xcrun simctl ui "$UDID" content_size "$v" >/dev/null 2>&1
  fi
}
run_dir() { # dir prefix
  FLOWS_DIR="$ROOT/../$1" SHOT_PREFIX="$2" bash "$ROOT/run.sh" ${UDID:+"$UDID"} || true
}
reseed() { # the deleting flows (11, 23, 24) remove the "Ola" conversation: flow 01 creates it again
  rm -rf maestro/audit-seed; mkdir -p maestro/audit-seed; cp maestro/flows/01-create-open-send.yaml maestro/audit-seed/
  run_dir maestro/audit-seed seed-
}
make_pass() { # name flows...
  local name="$1"; shift; local dir="maestro/audit-$name"
  rm -rf "$dir"; mkdir -p "$dir"
  for f in "$@"; do [ -f "maestro/flows/$f.yaml" ] && sed "s/takeScreenshot: /takeScreenshot: $name-/" "maestro/flows/$f.yaml" > "$dir/$f.yaml"; done
}

reseed
appearance dark;  text_size normal; make_pass dark  $DARK_FLOWS;  run_dir maestro/audit-dark  dark-
appearance light; text_size large;  make_pass large $SCALE_FLOWS; run_dir maestro/audit-large large-
text_size huge;                     make_pass huge  $SCALE_FLOWS; run_dir maestro/audit-huge  huge-
appearance light; text_size normal
