#!/usr/bin/env bash
# Synchronize a Cordova app template directory to an external destination,
# excluding build artifacts, and update package.json + config.xml to point
# at the target plugin spec (file: URL or npm semver).

set -euo pipefail

SRC="${1:?Usage: $0 <src_dir> <dest_dir> <plugin_spec> [--protect-env]}"
DEST="${2:?Usage: $0 <src_dir> <dest_dir> <plugin_spec> [--protect-env]}"
SPEC="${3:?Usage: $0 <src_dir> <dest_dir> <plugin_spec> [--protect-env]}"
PROTECT_ENV="${4:-}"

mkdir -p "$DEST"

RSYNC_ENV_FILTERS=()
if [[ "$PROTECT_ENV" == "--protect-env" ]]; then
  RSYNC_ENV_FILTERS=(
    --filter='protect .env'
    --filter='protect .env.local'
    --exclude .env
    --exclude .env.local
  )
fi

rsync -a --delete \
  ${RSYNC_ENV_FILTERS[@]+"${RSYNC_ENV_FILTERS[@]}"} \
  --exclude node_modules \
  --exclude platforms \
  --exclude plugins \
  --exclude package-lock.json \
  --exclude .DS_Store \
  "${SRC}/" "${DEST}/"

export DEST SPEC
node <<'NODE'
const fs = require('fs');
const path = require('path');

const dest = process.env.DEST;
const spec = process.env.SPEC;

const pjsonPath = path.join(dest, 'package.json');
if (fs.existsSync(pjsonPath)) {
  const pj = JSON.parse(fs.readFileSync(pjsonPath, 'utf8'));
  let updated = false;
  for (const depKind of ['dependencies', 'devDependencies']) {
    if (pj[depKind] && pj[depKind]['cordova-plugin-appsflyer-sdk']) {
      pj[depKind]['cordova-plugin-appsflyer-sdk'] = spec;
      updated = true;
    }
  }
  if (!updated) {
    pj.devDependencies = pj.devDependencies || {};
    pj.devDependencies['cordova-plugin-appsflyer-sdk'] = spec;
  }
  fs.writeFileSync(pjsonPath, JSON.stringify(pj, null, 2) + '\n');
}

const configXmlPath = path.join(dest, 'config.xml');
if (fs.existsSync(configXmlPath)) {
  let xml = fs.readFileSync(configXmlPath, 'utf8');
  xml = xml.replace(
    /<plugin\s+name="cordova-plugin-appsflyer-sdk"[^/]*\/>/,
    `<plugin name="cordova-plugin-appsflyer-sdk" spec="${spec}" />`
  );
  fs.writeFileSync(configXmlPath, xml);
}
NODE
