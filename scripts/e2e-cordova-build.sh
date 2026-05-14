#!/usr/bin/env bash
# Sync reference test-app/ to the E2E sibling copy, then npm install + cordova build (or run).
# Used by .af-e2e/test-plan.json build_cmd (CI + local) — default is **build** only, same as before.
#
# Usage (from plugin repo root):
#   ./scripts/e2e-cordova-build.sh android          # build APK only
#   ./scripts/e2e-cordova-build.sh android run      # build + install/launch on emulator
#   ./scripts/e2e-cordova-build.sh ios              # build .app for simulator only
#   ./scripts/e2e-cordova-build.sh ios run          # build + install/launch on simulator
#
# Env:
#   ENV_FILE                 Multiline `.env` body (DEV_KEY=, APP_ID=). CI: set from GitHub secret on
#                            this script’s environment (CI: GitHub secrets.ENV_FILE). Local: optional
#                            if `.af-e2e/.env.local` or `test-app/.env` exists — see scripts/write-e2e-env-to-dir.sh.
#   TEST_APP_E2E_COPY_DEST  Same as sync-test-app-e2e-copy.sh (must match .af-e2e paths if non-default)
#   CORDOVA_E2E_ANDROID_JAVA_HOME  If set, used as JAVA_HOME for Android builds only (overrides auto-pick).
#   CORDOVA_E2E_RESPECT_JAVA_HOME  If set to 1, do not change JAVA_HOME for Android (Gradle may still use
#                                  ~/.gradle/gradle.properties org.gradle.java.home unless you set GRADLE_OPTS).
#   CORDOVA_E2E_IOS_BUILDCONFIG    Optional path to Cordova build.json for iOS (default: build.json in E2E app root if present).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM="${1:?usage: $0 android|ios [build|run]}"
ACTION="${2:-build}"
if [[ "$ACTION" != build && "$ACTION" != run ]]; then
  echo "usage: $0 android|ios [build|run]  (default: build)" >&2
  exit 1
fi

# Cordova Android + default Gradle often break on the newest JDK (e.g. Java 25 → "Unsupported class file major version 69").
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
    echo "[e2e-cordova-build] JAVA_HOME from CORDOVA_E2E_ANDROID_JAVA_HOME=$JAVA_HOME"
    return
  fi
  if [[ "${CORDOVA_E2E_RESPECT_JAVA_HOME:-0}" == "1" ]]; then
    echo "[e2e-cordova-build] CORDOVA_E2E_RESPECT_JAVA_HOME=1 — leaving JAVA_HOME unchanged"
    return
  fi
  # macOS: always prefer a stable JDK for Cordova/AGP. Shell `java` can be 17 while Gradle still uses
  # org.gradle.java.home from ~/.gradle/gradle.properties (e.g. JDK 25) — we override that via GRADLE_OPTS below.
  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    local v new_home
    for v in 17 21; do
      if new_home="$(/usr/libexec/java_home -v "$v" 2>/dev/null)"; then
        export JAVA_HOME="$new_home"
        echo "[e2e-cordova-build] Using JAVA_HOME=$JAVA_HOME (macOS JDK $v) for Android"
        return
      fi
    done
  fi
  # Non-mac: keep JAVA_HOME / PATH; caller should set CORDOVA_E2E_ANDROID_JAVA_HOME in CI if needed.
  local cur_bin="java"
  [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]] && cur_bin="${JAVA_HOME}/bin/java"
  local cur_major
  cur_major="$(java_major "$cur_bin" || echo 0)"
  [[ -z "$cur_major" ]] && cur_major=0
  if [[ "$cur_major" -ge 23 ]]; then
    echo "[e2e-cordova-build] WARN: java reports major version $cur_major; set CORDOVA_E2E_ANDROID_JAVA_HOME to JDK 17 (Cordova Android + Gradle may fail on very new JDKs)." >&2
  fi
}

# Gradle daemon JVM can come from ~/.gradle/gradle.properties (org.gradle.java.home), ignoring PATH java.
apply_gradle_java_home_override() {
  [[ "$PLATFORM" == android ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  export GRADLE_OPTS="${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.java.home=${JAVA_HOME}"
  echo "[e2e-cordova-build] GRADLE_OPTS includes -Dorg.gradle.java.home=${JAVA_HOME}"
}

stop_android_gradle_daemon_if_present() {
  [[ "$PLATFORM" == android ]] || return 0
  local gw="${DEST}/platforms/android/tools/gradlew"
  [[ -x "$gw" ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  (cd "${DEST}/platforms/android/tools" && ./gradlew --stop 2>/dev/null) || true
}

"${ROOT}/scripts/sync-test-app-e2e-copy.sh"

if [[ -n "${TEST_APP_E2E_COPY_DEST:-}" ]]; then
  DEST="$TEST_APP_E2E_COPY_DEST"
else
  DEST="$(cat "${ROOT}/.af-e2e/e2e_copy_dest.txt")"
fi

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
    echo "[e2e-cordova-build] ios run (build + simulator; same build.json as build when present)"
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
    echo "[e2e-cordova-build] android run (build + emulator)"
    cordova run android --debug --emulator
  else
    cordova build android --debug
  fi
fi
