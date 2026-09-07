#!/usr/bin/env bash
# Gate: two version-pin pairs are each two logically-linked native dependencies that aren't
# published in lockstep — an untested combination can compile and still break at runtime, or
# (iOS) just ship wrong metadata since CocoaPods resolves the framework transitively regardless of
# what package.json claims. Fails closed: an untested pair is a hard failure, not a warning.
#
# Usage: ./scripts/check-native-version-pairs.sh <ios_sdk_version> <ios_framework_version> \
#                                                 <android_sdk_version> <android_plugin_bridge_version>

set -euo pipefail

ios_sdk="${1:?usage: $0 <ios_sdk_version> <ios_framework_version> <android_sdk_version> <android_plugin_bridge_version>}"
ios_framework="${2:?usage: $0 <ios_sdk_version> <ios_framework_version> <android_sdk_version> <android_plugin_bridge_version>}"
android_sdk="${3:?usage: $0 <ios_sdk_version> <ios_framework_version> <android_sdk_version> <android_plugin_bridge_version>}"
plugin_bridge="${4:?usage: $0 <ios_sdk_version> <ios_framework_version> <android_sdk_version> <android_plugin_bridge_version>}"

# Known-good pairs, verified against the reference migration (appsflyer-capacitor-plugin PR #203).
IOS_KNOWN_GOOD_PAIRS=(
  "7.0.13:7.0.2"
)
ANDROID_KNOWN_GOOD_PAIRS=(
  "7.0.1:7.0.12"
)

check_pair() {
  local label="$1" a="$2" b="$3"
  shift 3
  local pair
  for pair in "$@"; do
    if [[ "$pair" == "${a}:${b}" ]]; then
      echo "[check-native-version-pairs] OK — ${label} ${a} + ${b} is a known-good pair"
      return 0
    fi
  done
  echo "::error::${label} ${a} + ${b} is not a known-good pair. Add it to check-native-version-pairs.sh only after verifying it against a real build/test run."
  return 1
}

status=0
check_pair "AppsFlyerRPC + AppsFlyerFramework" "$ios_sdk" "$ios_framework" "${IOS_KNOWN_GOOD_PAIRS[@]}" || status=1
check_pair "af-android-sdk-bom + af-android-plugin-bridge" "$android_sdk" "$plugin_bridge" "${ANDROID_KNOWN_GOOD_PAIRS[@]}" || status=1
exit $status
