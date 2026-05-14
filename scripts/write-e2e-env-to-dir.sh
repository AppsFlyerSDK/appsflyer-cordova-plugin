#!/usr/bin/env bash
# Write Cordova project-root `.env` before `cordova prepare` / `cordova build` (CI uses
# secrets.ENV_FILE the same way). Called from e2e-cordova-build.sh and
# smoke-cordova-build.sh.
#
# Usage:
#   ./scripts/write-e2e-env-to-dir.sh <dest_dir> <plugin_repo_root>
#
# Precedence (first match wins):
#   1) ENV_FILE — multiline string (GitHub Actions: pass secrets.ENV_FILE on the build step env).
#   2) <plugin_root>/.af-e2e/.env.local — gitignored local mirror of ENV_FILE.
#   3) <plugin_root>/test-app/.env — gitignored per-dev file.
# Else: leave existing <dest_dir>/.env untouched; if missing, print a notice only.

set -euo pipefail

DEST="${1:?usage: $0 <dest_dir> <plugin_repo_root>}"
ROOT="${2:?usage: $0 <dest_dir> <plugin_repo_root>}"
mkdir -p "$DEST"

if [[ -n "${ENV_FILE:-}" ]]; then
  printf '%s\n' "${ENV_FILE}" > "${DEST}/.env"
  echo "[write-e2e-env-to-dir] wrote ${DEST}/.env from ENV_FILE"
elif [[ -f "${ROOT}/.af-e2e/.env.local" ]]; then
  cp "${ROOT}/.af-e2e/.env.local" "${DEST}/.env"
  echo "[write-e2e-env-to-dir] copied ${ROOT}/.af-e2e/.env.local → ${DEST}/.env"
elif [[ -f "${ROOT}/test-app/.env" ]]; then
  cp "${ROOT}/test-app/.env" "${DEST}/.env"
  echo "[write-e2e-env-to-dir] copied ${ROOT}/test-app/.env → ${DEST}/.env"
else
  if [[ -f "${DEST}/.env" ]]; then
    echo "[write-e2e-env-to-dir] leaving existing ${DEST}/.env (no ENV_FILE / .af-e2e/.env.local / test-app/.env)"
  else
    echo "[write-e2e-env-to-dir] notice: no ENV_FILE, ${ROOT}/.af-e2e/.env.local, or ${ROOT}/test-app/.env — ${DEST}/.env missing (Cordova hook will emit empty DEV_KEY)" >&2
  fi
fi
