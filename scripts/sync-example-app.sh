#!/usr/bin/env bash
# Copy examples/<name>/ to a directory OUTSIDE the plugin tree (sibling of this repo by default)
# so Cordova can use a local-path plugin spec without ENAMETOOLONG.
#
# Usage (from plugin repo root):
#   ./scripts/sync-example-app.sh <name> <dest>
#     name  Subdirectory under examples/ (cordovatestapp | ionic-cordova)
#     dest  Absolute path to sync destination

set -euo pipefail

NAME="${1:?Usage: sync-example-app.sh <name> <dest>}"
DEST="${2:?Usage: sync-example-app.sh <name> <dest>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/examples/${NAME}"
test -d "$SRC" || { echo "Error: no such example: ${SRC}"; exit 1; }

SPEC="$(node -e "console.log(require('url').pathToFileURL(process.argv[1]).href)" "$ROOT")"

"$ROOT/scripts/sync-cordova-dir.sh" "$SRC" "$DEST" "$SPEC"
echo "[sync-example-app] ${SRC}/ → ${DEST}"
