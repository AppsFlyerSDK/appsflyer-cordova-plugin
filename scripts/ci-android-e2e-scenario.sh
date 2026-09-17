#!/usr/bin/env bash
# Invoked as a SINGLE command from .github/workflows/android-e2e.yml inside
# reactivecircus/android-emulator-runner (that action runs each *line* of `script:`
# as a separate `sh -c` invocation — multi-line if/fi in YAML breaks; dash does not
# support `set -o pipefail`, so this file uses bash).
#
# Env: GITHUB_WORKSPACE (required), SCENARIO_PHASE (optional).
#
# DNS precheck uses UDP nslookup through the emulator (not ICMP ping), which matches
# how slirp-backed emulators behave on hosted runners.

set -euo pipefail

cd "${GITHUB_WORKSPACE:?}"
chmod +x scripts/*.sh

./scripts/check-emulator-dns.sh

adb devices

if [[ -n "${SCENARIO_PHASE:-}" ]]; then
  ./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --phase "${SCENARIO_PHASE}" \
    || ./scripts/dump-android-logs.sh
else
  ./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json \
    || ./scripts/dump-android-logs.sh
fi
