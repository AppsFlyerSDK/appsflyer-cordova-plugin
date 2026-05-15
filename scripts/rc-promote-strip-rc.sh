#!/usr/bin/env bash
# Strip -rcN from package.json + plugin.xml version (promote-release gate).
# Native SDK pins (pod / gradle / README) are left unchanged.
#
# Usage (repo root):
#   ./scripts/rc-promote-strip-rc.sh <promoted_semver>
# If omitted, reads package.json and strips -rcN when present.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROMOTED="${1:-}"
if [[ -z "$PROMOTED" ]]; then
  CUR=$(node -p "require('./package.json').version")
  if [[ "$CUR" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-rc[0-9]+$ ]]; then
    PROMOTED="${BASH_REMATCH[1]}"
  else
    echo "[rc-promote-strip-rc] package.json version is '$CUR' (no -rcN); nothing to do"
    exit 0
  fi
fi

export RC_PROMOTED_VERSION="$PROMOTED"

node <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.cwd();
const pv = process.env.RC_PROMOTED_VERSION;

const pjPath = path.join(root, 'package.json');
const pj = JSON.parse(fs.readFileSync(pjPath, 'utf8'));
pj.version = pv;
fs.writeFileSync(pjPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(root, 'plugin.xml'), 'utf8');
xml = xml.replace(/version="[^"]+"/, `version="${pv}"`);
fs.writeFileSync(path.join(root, 'plugin.xml'), xml);

console.log('[rc-promote-strip-rc] set plugin version to', pv);
NODE
