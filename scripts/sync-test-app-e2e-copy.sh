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

mkdir -p "$DEST"

rsync -a --delete \
  --filter='protect .env' \
  --filter='protect .env.local' \
  --exclude node_modules \
  --exclude platforms \
  --exclude plugins \
  --exclude .env \
  --exclude .env.local \
  --exclude package-lock.json \
  --exclude .DS_Store \
  "${ROOT}/test-app/" "${DEST}/"

export DEST PLUGIN_ROOT
node <<'NODE'
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

const dest = process.env.DEST;
const pluginRoot = process.env.PLUGIN_ROOT;
const fileUrl = pathToFileURL(pluginRoot).href;

const pjsonPath = path.join(dest, 'package.json');
const pj = JSON.parse(fs.readFileSync(pjsonPath, 'utf8'));
pj.devDependencies = pj.devDependencies || {};
pj.devDependencies['cordova-plugin-appsflyer-sdk'] = fileUrl;
fs.writeFileSync(pjsonPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(dest, 'config.xml'), 'utf8');
xml = xml.replace(
  /<plugin\s+name="cordova-plugin-appsflyer-sdk"[^/]*\/>/,
  `<plugin name="cordova-plugin-appsflyer-sdk" spec="${fileUrl}" />`
);
fs.writeFileSync(path.join(dest, 'config.xml'), xml);
NODE

mkdir -p "${ROOT}/.af-e2e"
echo "${DEST}" > "${ROOT}/.af-e2e/e2e_copy_dest.txt"

echo "[sync-test-app-e2e-copy] ${ROOT}/test-app/ → ${DEST}"
if [[ ! -f "${DEST}/.env" ]]; then
  echo "[sync-test-app-e2e-copy] hint: no ${DEST}/.env yet — run ./scripts/e2e-cordova-build.sh (writes .env like Flutter), or ./scripts/bootstrap-e2e-env.sh for a template-only sibling .env."
fi
