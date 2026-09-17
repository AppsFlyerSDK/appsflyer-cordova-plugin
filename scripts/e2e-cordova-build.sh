#!/usr/bin/env bash
# E2E entry point: scripts/cordova-build.sh in `e2e` mode (sibling copy, plugin from file:..).
# Usage: ./scripts/e2e-cordova-build.sh android|ios [build|run]   — see cordova-build.sh for env vars.
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/cordova-build.sh" e2e "$@"
