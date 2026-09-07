#!/usr/bin/env bash
# Copy examples/<name>/ to a directory OUTSIDE the plugin tree (sibling of this repo by default)
# so Cordova can use a local-path plugin spec without ENAMETOOLONG (examples/<name> lives inside
# this repo, so pointing a plugin spec at the repo root from inside it copies the repo into its
# own subdirectory otherwise). Same fix as scripts/sync-test-app-e2e-copy.sh, generalized for the
# two example apps under examples/ instead of test-app/.
#
# Usage (from plugin repo root):
#   ./scripts/sync-example-app.sh <name> <dest>
#     name  Subdirectory under examples/ (cordovatestapp | ionic-cordova)
#     dest  Absolute path to sync destination

set -euo pipefail

NAME="${1:?Usage: sync-example-app.sh <name> <dest>}"
DEST="${2:?Usage: sync-example-app.sh <name> <dest>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_ROOT="$ROOT"
SRC="${ROOT}/examples/${NAME}"

test -d "$SRC" || { echo "Error: no such example: ${SRC}"; exit 1; }

mkdir -p "$DEST"

rsync -a --delete \
  --exclude node_modules \
  --exclude platforms \
  --exclude plugins \
  --exclude .DS_Store \
  "${SRC}/" "${DEST}/"

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
for (const depKind of ['dependencies', 'devDependencies']) {
  if (pj[depKind] && pj[depKind]['cordova-plugin-appsflyer-sdk']) {
    pj[depKind]['cordova-plugin-appsflyer-sdk'] = fileUrl;
  }
}
fs.writeFileSync(pjsonPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(dest, 'config.xml'), 'utf8');
xml = xml.replace(
  /<plugin\s+name="cordova-plugin-appsflyer-sdk"[^/]*\/>/,
  `<plugin name="cordova-plugin-appsflyer-sdk" spec="${fileUrl}" />`
);
fs.writeFileSync(path.join(dest, 'config.xml'), xml);
NODE

echo "[sync-example-app] ${SRC}/ → ${DEST}"
