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
VERSION="${SMOKE_PLUGIN_VERSION:-$(node -p "require('${ROOT}/package.json').version")}"

"$ROOT/scripts/sync-cordova-dir.sh" "${ROOT}/test-app" "$DEST" "$VERSION" --protect-env

echo "[sync-test-app-rc-smoke] ${ROOT}/test-app/ → ${DEST} (cordova-plugin-appsflyer-sdk@${VERSION} from npm)"
