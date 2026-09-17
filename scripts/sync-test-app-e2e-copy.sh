#!/usr/bin/env bash
# Copy repo test-app/ to a directory OUTSIDE the plugin tree (sibling of this repo by default)
# so Cordova can use file:/path-to-plugin without ENAMETOOLONG (no test-app inside the copied plugin tree).
#
# Source of truth:  <repo>/test-app/   (reference only; safe to run Cordova only after copy)
# Default dest:     <parent>/<repo-basename>-e2e   e.g. ../appsflyer-cordova-plugin-e2e
#
# Usage (from plugin repo root):
#   ./scripts/sync-test-app-e2e-copy.sh
#
# Env:
#   TEST_APP_E2E_COPY_DEST  Absolute path to sync destination (overrides default sibling path)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_ROOT="$ROOT"
BASENAME="$(basename "$PLUGIN_ROOT")"
DEFAULT_DEST="$(dirname "$PLUGIN_ROOT")/${BASENAME}-e2e"
DEST="${TEST_APP_E2E_COPY_DEST:-$DEFAULT_DEST}"
SPEC="$(node -e "console.log(require('url').pathToFileURL(process.argv[1]).href)" "$ROOT")"

"$ROOT/scripts/sync-cordova-dir.sh" "${ROOT}/test-app" "$DEST" "$SPEC" --protect-env

mkdir -p "${ROOT}/.af-e2e"
echo "${DEST}" > "${ROOT}/.af-e2e/e2e_copy_dest.txt"

echo "[sync-test-app-e2e-copy] ${ROOT}/test-app/ → ${DEST}"
if [[ ! -f "${DEST}/.env" ]]; then
  echo "[sync-test-app-e2e-copy] hint: no ${DEST}/.env yet — run ./scripts/e2e-cordova-build.sh (writes .env via write-e2e-env-to-dir), or ./scripts/bootstrap-e2e-env.sh for a template-only sibling .env."
fi
