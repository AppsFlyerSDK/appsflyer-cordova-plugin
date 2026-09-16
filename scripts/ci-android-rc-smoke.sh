#!/usr/bin/env bash
# Android RC smoke — single script line for android-emulator-runner (bash, pipefail).
# Env: GITHUB_WORKSPACE, SMOKE_PLUGIN_VERSION, ENV_FILE (optional), CORDOVA_E2E_ANDROID_JAVA_HOME.

set -euo pipefail

cd "${GITHUB_WORKSPACE:?}"
chmod +x scripts/*.sh

./scripts/check-emulator-dns.sh

./scripts/af-scenario-runner.sh --platform android --plan .af-smoke/rc-test-plan.json --build --verbose \
  || ./scripts/dump-android-logs.sh
