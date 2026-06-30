#!/usr/bin/env bash
# Refresh CocoaPods trunk/CDN specs and install iOS pods with --repo-update.
#
# Cordova runs plain `pod install` during build; without a prior --repo-update, a
# stale ~/.cocoapods cache (common in CI) can miss newly published pod versions.
#
# Usage (from a Cordova app directory, or pass the app path as $1):
#   /path/to/plugin/scripts/cordova-ios-pod-install.sh
#   /path/to/plugin/scripts/cordova-ios-pod-install.sh /path/to/cordova-app
#
# Env:
#   CORDOVA_IOS_POD_REPO_UPDATE  1 = run (default in GitHub Actions), 0 = skip

set -euo pipefail

should_repo_update() {
  local flag="${CORDOVA_IOS_POD_REPO_UPDATE:-}"
  if [[ -z "$flag" ]]; then
    [[ "${GITHUB_ACTIONS:-}" == "true" ]]
    return
  fi
  [[ "$flag" == "1" ]]
}

if ! should_repo_update; then
  echo "[cordova-ios-pod-install] skip (CORDOVA_IOS_POD_REPO_UPDATE=${CORDOVA_IOS_POD_REPO_UPDATE:-0})"
  exit 0
fi

PROJECT_DIR="$(cd "${1:-.}" && pwd)"
IOS_DIR="${PROJECT_DIR}/platforms/ios"

if [[ ! -d "$IOS_DIR" ]]; then
  echo "[cordova-ios-pod-install] skip: ${IOS_DIR} not found"
  exit 0
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "[cordova-ios-pod-install] skip: pod not in PATH"
  exit 0
fi

echo "[cordova-ios-pod-install] cordova prepare ios (refresh Podfile)"
(cd "$PROJECT_DIR" && cordova prepare ios --no-interactive)

if [[ -f "${IOS_DIR}/Podfile" ]]; then
  echo "[cordova-ios-pod-install] pod install --repo-update"
  (cd "$IOS_DIR" && pod install --repo-update)
else
  echo "[cordova-ios-pod-install] pod repo update (no Podfile yet)"
  pod repo update
fi
