# agent-kit hooks: shared helpers (sourced; never run directly).
# Finds a working Python 3 (python3, python). Hooks fail OPEN when it is missing, but the session
# banner says so, because without Python the approval-gate hook and the brief reminder are inactive.
PY=""
for _c in python3 python; do
  if command -v "$_c" >/dev/null 2>&1 && "$_c" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then PY="$_c"; break; fi
done
unset _c
ak_require_py() {
  [ -n "$PY" ] && return 0
  [ -t 0 ] || cat >/dev/null 2>&1
  echo "[agent-kit] Python 3 not found: this hook is inactive (install Python 3; on Windows use Git Bash or WSL)." >&2
  exit 0
}
