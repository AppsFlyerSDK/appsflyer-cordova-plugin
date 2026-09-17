#!/usr/bin/env bash
# RC smoke entry point: scripts/cordova-build.sh in `smoke` mode (test-app_rc_smoke/, npm-pinned plugin).
# Usage: ./scripts/smoke-cordova-build.sh android|ios [build|run]  — see cordova-build.sh for env vars.
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/cordova-build.sh" smoke "$@"
