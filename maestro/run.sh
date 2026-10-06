#!/usr/bin/env bash
# Runs every flow in order and prints a pass/fail table. Usage: maestro/run.sh [device-id]
set -u
export PATH="$PATH:$HOME/.maestro/bin"
cd "$(dirname "$0")/flows"
status=0
for flow in *.yaml; do
  echo; echo "=== $flow ($(date +%H:%M:%S)) ==="
  if timeout 600 maestro ${1:+--device "$1"} test --no-ansi "$flow"; then echo "RESULT $flow: PASS"; else echo "RESULT $flow: FAIL"; status=1; fi
done
exit $status
