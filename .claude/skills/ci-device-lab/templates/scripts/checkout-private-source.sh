#!/usr/bin/env bash
# Clone a PRIVATE app repository read-only into $DEST (Layout B: public CI repo).
# Accepts an SSH deploy key (text or base64 of the file) or a fine-grained token
# (github_pat_...). Repairs common paste damage (CRLF, missing final newline)
# and explains failures by the SHAPE of the value, never printing it.
# Env: DEPLOY_KEY (required) · REPO=owner/name (required) · REF (default main) · DEST (default src)
set -euo pipefail
: "${DEPLOY_KEY:?DEPLOY_KEY is empty: create the SOURCE_DEPLOY_KEY secret (see secrets.md)}"
: "${REPO:?REPO is empty: set the SOURCE_REPO variable (owner/name)}"
REF="${REF:-main}"; DEST="${DEST:-src}"
fail() { echo "::error title=Private checkout::$*"; exit 1; }
[[ "$REF" =~ ^[A-Za-z0-9._/-]+$ ]] || fail "ref has characters a branch/tag/sha never has"
[[ "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || fail "REPO must be owner/name"

key="$(printf '%s' "$DEPLOY_KEY" | tr -d '\r')"
if [[ "$key" == github_pat_* ]]; then
  echo "::add-mask::$key"
  auth="Authorization: Basic $(printf 'x-access-token:%s' "$key" | base64 -w0)"
  echo "::add-mask::$auth"
  git -c http.extraHeader="$auth" clone --quiet --depth 1 --branch "$REF" "https://github.com/$REPO.git" "$DEST" 2>/dev/null \
  || { git -c http.extraHeader="$auth" clone --quiet "https://github.com/$REPO.git" "$DEST" && git -C "$DEST" checkout --quiet "$REF"; } \
  || fail "clone refused: token must be fine-grained, this repo only, Contents: read-only"
elif [[ "$key" == ghp_* || "$key" == gho_* ]]; then
  fail "classic/OAuth tokens are refused: use an SSH deploy key or a fine-grained token (Contents: read-only, this repo only)"
else
  [[ "$key" == *"BEGIN"* ]] || key="$(printf '%s' "$key" | base64 -d 2>/dev/null || true)"
  [[ "$key" == *"PRIVATE KEY"* ]] || fail "value is not a private key (public key pasted? incomplete file?)"
  [[ "$key" == *"ENCRYPTED"* ]] && fail "key has a passphrase: generate it with -N \"\""
  kf="$(mktemp)"; trap 'rm -f "$kf"' EXIT
  printf '%s\n' "$key" > "$kf"; chmod 600 "$kf"
  echo "key fingerprint: $(ssh-keygen -lf "$kf" | awk '{print $2}') (compare with the repo's Deploy keys page)"
  export GIT_SSH_COMMAND="ssh -i $kf -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  git clone --quiet --depth 1 --branch "$REF" "git@github.com:$REPO.git" "$DEST" 2>/dev/null \
  || { git clone --quiet "git@github.com:$REPO.git" "$DEST" && git -C "$DEST" checkout --quiet "$REF"; } \
  || fail "clone refused: is the public key in the private repo's Deploy keys?"
fi
[ -n "$(git -C "$DEST" rev-parse HEAD 2>/dev/null)" ] || fail "clone produced no commit"
sha="$(git -C "$DEST" rev-parse HEAD)"
echo "checked out $REPO@${sha:0:12}"
[ -n "${GITHUB_OUTPUT:-}" ] && { echo "sha=$sha"; echo "short=${sha:0:12}"; } >> "$GITHUB_OUTPUT"
exit 0
