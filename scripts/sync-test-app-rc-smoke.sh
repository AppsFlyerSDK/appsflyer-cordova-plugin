#!/usr/bin/env bash
# Copy test-app/ -> test-app_rc_smoke/ (gitignored) and pin cordova-plugin-appsflyer-sdk to an npm semver
# (registry install), matching CI smoke synthesis (Phase 4 / .af-smoke).
#
# Usage (from plugin repo root):
#   ./scripts/sync-test-app-rc-smoke.sh
#
# Env:
#   SMOKE_PLUGIN_VERSION  Exact npm version for cordova-plugin-appsflyer-sdk (default: root package.json "version")

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/test-app_rc_smoke"

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

export SMOKE_PLUGIN_VERSION="${SMOKE_PLUGIN_VERSION:-}"
export DEST ROOT
node <<'NODE'
const fs = require('fs');
const path = require('path');

const root = process.env.ROOT;
const dest = process.env.DEST;
const rootPj = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const version = process.env.SMOKE_PLUGIN_VERSION || rootPj.version;

const pjsonPath = path.join(dest, 'package.json');
const pj = JSON.parse(fs.readFileSync(pjsonPath, 'utf8'));
pj.devDependencies = pj.devDependencies || {};
pj.devDependencies['cordova-plugin-appsflyer-sdk'] = version;
fs.writeFileSync(pjsonPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(dest, 'config.xml'), 'utf8');
xml = xml.replace(
  /<plugin\s+name="cordova-plugin-appsflyer-sdk"[^/]*\/>/,
  `<plugin name="cordova-plugin-appsflyer-sdk" spec="${version}" />`
);
fs.writeFileSync(path.join(dest, 'config.xml'), xml);

console.log(`[sync-test-app-rc-smoke] ${root}/test-app/ → ${dest} (cordova-plugin-appsflyer-sdk@${version} from npm)`);
NODE
