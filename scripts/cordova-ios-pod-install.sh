#!/usr/bin/env bash
# Refresh CocoaPods trunk/CDN specs and install iOS pods with --repo-update.
#
# Cordova runs plain `pod install` during `platform add` / plugin install / build.
# Without a prior spec refresh, a stale ~/.cocoapods cache (common in CI) can miss
# newly published pod versions (e.g. AppsFlyerFramework 6.18.1).
#
# Usage:
#   ./scripts/cordova-ios-pod-install.sh --update-specs
#     Refresh CDN/trunk specs only (no Cordova project required). Call this
#     before `cordova platform add ios` so plugin pod install can resolve.
#
#   ./scripts/cordova-ios-pod-install.sh [cordova_project_dir]
#     --update-specs, then cordova prepare ios + pod install --repo-update when
#     platforms/ios exists.
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

update_pod_specs() {
  if ! should_repo_update; then
    echo "[cordova-ios-pod-install] skip specs update (CORDOVA_IOS_POD_REPO_UPDATE=${CORDOVA_IOS_POD_REPO_UPDATE:-0})"
    return 0
  fi
  if ! command -v pod >/dev/null 2>&1; then
    echo "[cordova-ios-pod-install] skip specs update: pod not in PATH"
    return 0
  fi

  # Restored ~/.cocoapods cache (ios-e2e) can include all_pods_versions_* indexes that
  # predate a new AppsFlyerFramework release. CDN skips remote checks for those files
  # unless they are removed before repo update.
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    local trunk_dir="${HOME}/.cocoapods/repos/trunk"
    if [[ -d "$trunk_dir" ]]; then
      echo "[cordova-ios-pod-install] clearing stale CocoaPods trunk version indexes (CI)"
      find "$trunk_dir" -maxdepth 1 -name 'all_pods_versions_*.txt' -delete 2>/dev/null || true
    fi
  fi

  echo "[cordova-ios-pod-install] pod repo update (refresh CDN/trunk specs)"
  pod repo update
}

install_ios_pods() {
  local project_dir="$1"
  local ios_dir="${project_dir}/platforms/ios"

  if [[ ! -d "$ios_dir" ]]; then
    echo "[cordova-ios-pod-install] skip install: ${ios_dir} not found"
    return 0
  fi
  if ! should_repo_update; then
    return 0
  fi
  if ! command -v pod >/dev/null 2>&1; then
    echo "[cordova-ios-pod-install] skip install: pod not in PATH"
    return 0
  fi

  echo "[cordova-ios-pod-install] cordova prepare ios (refresh Podfile)"
  (cd "$project_dir" && cordova prepare ios --no-interactive)

  if [[ -f "${ios_dir}/Podfile" ]]; then
    echo "[cordova-ios-pod-install] pod install --repo-update"
    (cd "$ios_dir" && pod install --repo-update)
  fi
}

case "${1:-}" in
  --update-specs)
    update_pod_specs
    ;;
  "")
    update_pod_specs
    ;;
  *)
    update_pod_specs
    install_ios_pods "$(cd "$1" && pwd)"
    ;;
esac
