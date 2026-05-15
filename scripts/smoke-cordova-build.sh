#!/usr/bin/env bash
# RC smoke: sync test-app/ -> test-app_rc_smoke/ (npm-pinned plugin), then cordova build (or run).
# Used by .af-smoke/rc-test-plan.json build_cmd (CI + local). Paths in that plan are under test-app_rc_smoke/.
#
# Usage (from plugin repo root):
#   ./scripts/smoke-cordova-build.sh android
#   ./scripts/smoke-cordova-build.sh ios
#   ./scripts/smoke-cordova-build.sh android run
#   ./scripts/smoke-cordova-build.sh ios run
#
# Env:
#   ENV_FILE                       Same as e2e-cordova-build.sh — written to test-app_rc_smoke/.env before build.
#   SMOKE_PLUGIN_VERSION           Passed to sync-test-app-rc-smoke.sh (default: root package.json version).
#   CORDOVA_E2E_ANDROID_JAVA_HOME  Android: same semantics as e2e-cordova-build.sh (optional JDK pin).
#   CORDOVA_E2E_RESPECT_JAVA_HOME  Android: same as e2e script.
#   CORDOVA_E2E_IOS_BUILDCONFIG    iOS: optional build.json path (default: build.json in smoke app dir).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM="${1:?usage: $0 android|ios [build|run]}"
ACTION="${2:-build}"
if [[ "$ACTION" != build && "$ACTION" != run ]]; then
  echo "usage: $0 android|ios [build|run]  (default: build)" >&2
  exit 1
fi

DEST="${ROOT}/test-app_rc_smoke"

java_major() {
  local java_bin="${1:-java}"
  local line
  line="$("$java_bin" -version 2>&1 | head -n1)" || return 1
  if [[ "$line" =~ version\ \"1\. ]]; then
    echo 8
    return
  fi
  if [[ "$line" =~ version\ \"([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  return 1
}

pick_java_home_for_android() {
  if [[ -n "${CORDOVA_E2E_ANDROID_JAVA_HOME:-}" ]]; then
    export JAVA_HOME="${CORDOVA_E2E_ANDROID_JAVA_HOME}"
    echo "[smoke-cordova-build] JAVA_HOME from CORDOVA_E2E_ANDROID_JAVA_HOME=$JAVA_HOME"
    return
  fi
  if [[ "${CORDOVA_E2E_RESPECT_JAVA_HOME:-0}" == "1" ]]; then
    echo "[smoke-cordova-build] CORDOVA_E2E_RESPECT_JAVA_HOME=1 — leaving JAVA_HOME unchanged"
    return
  fi
  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    local v new_home
    for v in 17 21; do
      if new_home="$(/usr/libexec/java_home -v "$v" 2>/dev/null)"; then
        export JAVA_HOME="$new_home"
        echo "[smoke-cordova-build] Using JAVA_HOME=$JAVA_HOME (macOS JDK $v) for Android"
        return
      fi
    done
  fi
  local cur_bin="java"
  [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]] && cur_bin="${JAVA_HOME}/bin/java"
  local cur_major
  cur_major="$(java_major "$cur_bin" || echo 0)"
  [[ -z "$cur_major" ]] && cur_major=0
  if [[ "$cur_major" -ge 23 ]]; then
    echo "[smoke-cordova-build] WARN: java major $cur_major; set CORDOVA_E2E_ANDROID_JAVA_HOME to JDK 17 if Gradle fails." >&2
  fi
}

apply_gradle_java_home_override() {
  [[ "$PLATFORM" == android ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  export GRADLE_OPTS="${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.java.home=${JAVA_HOME}"
  echo "[smoke-cordova-build] GRADLE_OPTS includes -Dorg.gradle.java.home=${JAVA_HOME}"
}

stop_android_gradle_daemon_if_present() {
  [[ "$PLATFORM" == android ]] || return 0
  local gw="${DEST}/platforms/android/tools/gradlew"
  [[ -x "$gw" ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  (cd "${DEST}/platforms/android/tools" && ./gradlew --stop 2>/dev/null) || true
}

export SMOKE_PLUGIN_VERSION="${SMOKE_PLUGIN_VERSION:-}"
"${ROOT}/scripts/sync-test-app-rc-smoke.sh"

"${ROOT}/scripts/write-e2e-env-to-dir.sh" "$DEST" "$ROOT"

cd "$DEST"
npm install

if [[ "$PLATFORM" == android ]]; then
  pick_java_home_for_android
  apply_gradle_java_home_override
  stop_android_gradle_daemon_if_present
fi

if [[ "$PLATFORM" == android ]] && [[ ! -d platforms/android ]]; then
  cordova platform add android --no-interactive
fi
if [[ "$PLATFORM" == ios ]] && [[ ! -d platforms/ios ]]; then
  cordova platform add ios --no-interactive
fi

ios_bc="${CORDOVA_E2E_IOS_BUILDCONFIG:-}"
if [[ -z "$ios_bc" && -f "${PWD}/build.json" ]]; then
  ios_bc="${PWD}/build.json"
fi

if [[ "$PLATFORM" == ios ]]; then
  if [[ "$ACTION" == run ]]; then
    echo "[smoke-cordova-build] ios run"
    if [[ -n "$ios_bc" ]]; then
      cordova run ios --debug --emulator --buildConfig="$ios_bc"
    else
      cordova run ios --debug --emulator
    fi
  else
    if [[ -n "$ios_bc" ]]; then
      cordova build ios --debug --buildConfig="$ios_bc"
    else
      cordova build ios --debug
    fi
  fi
else
  if [[ "$ACTION" == run ]]; then
    echo "[smoke-cordova-build] android run"
    cordova run android --debug --emulator
  else
    cordova build android --debug
  fi
fi
