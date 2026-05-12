#!/usr/bin/env bash
# Invoked as a SINGLE command from .github/workflows/android-e2e.yml inside
# reactivecircus/android-emulator-runner (that action runs each *line* of `script:`
# as a separate `sh -c` invocation — multi-line if/fi in YAML breaks).
#
# Env: GITHUB_WORKSPACE (required), SCENARIO_PHASE (optional).

set -euo pipefail

cd "${GITHUB_WORKSPACE:?}"
chmod +x scripts/*.sh
nslookup appsflyersdk.com || true
adb devices

if [[ -n "${SCENARIO_PHASE:-}" ]]; then
  ./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --verbose --phase "${SCENARIO_PHASE}" \
    || ./scripts/dump-android-logs.sh
else
  ./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --verbose \
    || ./scripts/dump-android-logs.sh
fi
