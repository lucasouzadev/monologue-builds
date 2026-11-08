#!/usr/bin/env bash
# Install JS dependencies with the lockfile's package manager (reproducible install).
set -euo pipefail
cd "${1:-.}"
if   [ -f pnpm-lock.yaml ];    then corepack enable && pnpm install --frozen-lockfile
elif [ -f yarn.lock ];         then corepack enable && yarn install --immutable 2>/dev/null || yarn install --frozen-lockfile
elif [ -f bun.lockb ] || [ -f bun.lock ]; then npm i -g bun@1 >/dev/null && bun install --frozen-lockfile
elif [ -f package-lock.json ]; then npm ci
elif [ -f package.json ];      then echo "::warning::no lockfile; installs are not reproducible"; npm install
else echo "no package.json; skipping JS install"; fi
