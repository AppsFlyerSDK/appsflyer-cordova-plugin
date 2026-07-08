#!/usr/bin/env bash
# Dump Android diagnostics when the Cordova E2E/smoke runner step fails.
# Intended for use as: ./scripts/af-scenario-runner.sh ... || ./scripts/dump-android-logs.sh

#
# Default package matches D5 (.af-e2e / .af-smoke plans): com.appsflyer.qa.cordova
# Override per job: PACKAGE_NAME=com.example.app ./scripts/dump-android-logs.sh
#
# Always exits 1 so the CI step stays failed after dumping.

set +e

PKG="${PACKAGE_NAME:-com.appsflyer.qa.cordova}"

echo "::group::Package / process (${PKG})"
adb shell "pm path ${PKG}" 2>&1
adb shell "ps -A | grep -E '${PKG}|chromium|Cordova' || true" 2>&1
echo "::endgroup::"

echo "::group::run-as sandbox (debuggable builds only)"
adb shell "run-as ${PKG} ls -la" 2>&1
adb shell "run-as ${PKG} ls -la files" 2>&1 || true
echo "::endgroup::"

echo "::group::adb logcat dump (last 500 lines, unfiltered)"
adb logcat -d -t 500
echo "::endgroup::"

echo "::group::AndroidRuntime + chromium (tail)"
adb logcat -d -b crash 2>/dev/null | tail -200
adb logcat -d AndroidRuntime:E chromium:I '*:S' 2>/dev/null | tail -150
echo "::endgroup::"

exit 1
