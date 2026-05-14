#!/usr/bin/env bash
# Android RC smoke — single script line for android-emulator-runner (bash, pipefail).
# Env: GITHUB_WORKSPACE, SMOKE_PLUGIN_VERSION, ENV_FILE (optional), CORDOVA_E2E_ANDROID_JAVA_HOME.

set -euo pipefail

cd "${GITHUB_WORKSPACE:?}"
chmod +x scripts/*.sh

adb shell 'getprop net.dns1; getprop net.dns2' || true
adb shell 'nslookup oyoxfj.conversions.appsflyersdk.com 2>&1 | head -5' || {
  sleep 10
  adb shell 'nslookup oyoxfj.conversions.appsflyersdk.com 2>&1 | head -5'
} || {
  echo "::error::Emulator DNS cannot resolve AppsFlyer hosts"
  exit 1
}

./scripts/af-scenario-runner.sh --platform android --plan .af-smoke/rc-test-plan.json --build --verbose \
  || ./scripts/dump-android-logs.sh
