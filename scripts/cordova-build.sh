#!/usr/bin/env bash
# Sync the reference test-app/ into the target app dir, then npm install + cordova build (or run).
# Two modes:
#   e2e    sibling copy via scripts/sync-test-app-e2e-copy.sh (plugin from file:..) — .af-e2e/test-plan.json
#   smoke  test-app_rc_smoke/ via scripts/sync-test-app-rc-smoke.sh (plugin pinned to npm version)
#          — .af-smoke/rc-test-plan.json
# Entry points scripts/e2e-cordova-build.sh and scripts/smoke-cordova-build.sh wrap this with the mode.
#
# Usage (from plugin repo root):
#   ./scripts/cordova-build.sh e2e android          # build APK only
#   ./scripts/cordova-build.sh e2e android run      # build + install/launch on emulator
#   ./scripts/cordova-build.sh e2e ios              # build .app for simulator only
#   ./scripts/cordova-build.sh smoke ios run        # build + install/launch on simulator
#
# Env:
#   ENV_FILE                 Multiline `.env` body (DEV_KEY=, APP_ID=). CI: set from GitHub secret on
#                            this script’s environment (CI: GitHub secrets.ENV_FILE). Local: optional
#                            if `.af-e2e/.env.local` or `test-app/.env` exists — see scripts/write-e2e-env-to-dir.sh.
#   TEST_APP_E2E_COPY_DEST  e2e only. Same as sync-test-app-e2e-copy.sh (must match .af-e2e paths if non-default)
#   SMOKE_PLUGIN_VERSION    smoke only. Passed to sync-test-app-rc-smoke.sh (default: root package.json version).
#   CORDOVA_E2E_ANDROID_JAVA_HOME  If set, used as JAVA_HOME for Android builds only (overrides auto-pick).
#   CORDOVA_E2E_RESPECT_JAVA_HOME  If set to 1, do not change JAVA_HOME for Android (Gradle may still use
#                                  ~/.gradle/gradle.properties org.gradle.java.home unless you set GRADLE_OPTS).
#   CORDOVA_E2E_IOS_BUILDCONFIG    Optional path to Cordova build.json for iOS (default: build.json in app root if present).
#   CORDOVA_IOS_POD_REPO_UPDATE    1 = refresh CocoaPods specs before iOS platform add/build (default: 1 in GitHub Actions, 0 locally).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:?usage: $0 e2e|smoke android|ios [build|run]}"
if [[ "$MODE" != e2e && "$MODE" != smoke ]]; then
  echo "usage: $0 e2e|smoke android|ios [build|run]" >&2
  exit 1
fi
PLATFORM="${2:?usage: $0 $MODE android|ios [build|run]}"
ACTION="${3:-build}"
if [[ "$ACTION" != build && "$ACTION" != run ]]; then
  echo "usage: $0 $MODE android|ios [build|run]  (default: build)" >&2
  exit 1
fi

LOG_PREFIX="[${MODE}-cordova-build]"

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
    echo "${LOG_PREFIX} JAVA_HOME from CORDOVA_E2E_ANDROID_JAVA_HOME=$JAVA_HOME"
    return
  fi
  if [[ "${CORDOVA_E2E_RESPECT_JAVA_HOME:-0}" == "1" ]]; then
    echo "${LOG_PREFIX} CORDOVA_E2E_RESPECT_JAVA_HOME=1 — leaving JAVA_HOME unchanged"
    return
  fi
  # macOS: always prefer a stable JDK for Cordova/AGP. Shell `java` can be 17 while Gradle still uses
  # org.gradle.java.home from ~/.gradle/gradle.properties (e.g. JDK 25) — we override that via GRADLE_OPTS below.
  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    local v new_home
    for v in 17 21; do
      if new_home="$(/usr/libexec/java_home -v "$v" 2>/dev/null)"; then
        export JAVA_HOME="$new_home"
        echo "${LOG_PREFIX} Using JAVA_HOME=$JAVA_HOME (macOS JDK $v) for Android"
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
    echo "${LOG_PREFIX} WARN: java reports major version $cur_major; set CORDOVA_E2E_ANDROID_JAVA_HOME to JDK 17 (Cordova Android + Gradle may fail on very new JDKs)." >&2
  fi
}

# Gradle daemon JVM can come from ~/.gradle/gradle.properties (org.gradle.java.home), ignoring PATH java.
apply_gradle_java_home_override() {
  [[ "$PLATFORM" == android ]] || return 0
  [[ "${CORDOVA_E2E_RESPECT_JAVA_HOME:-0}" != "1" ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  export GRADLE_OPTS="${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.java.home=${JAVA_HOME}"
  echo "${LOG_PREFIX} GRADLE_OPTS includes -Dorg.gradle.java.home=${JAVA_HOME}"
}

stop_android_gradle_daemon_if_present() {
  [[ "$PLATFORM" == android ]] || return 0
  local gw="${DEST}/platforms/android/tools/gradlew"
  [[ -x "$gw" ]] || return 0
  [[ -n "${JAVA_HOME:-}" ]] || return 0
  (cd "${DEST}/platforms/android/tools" && ./gradlew --stop 2>/dev/null) || true
}

if [[ "$MODE" == e2e ]]; then
  "${ROOT}/scripts/sync-test-app-e2e-copy.sh"
  if [[ -n "${TEST_APP_E2E_COPY_DEST:-}" ]]; then
    DEST="$TEST_APP_E2E_COPY_DEST"
  else
    DEST="$(cat "${ROOT}/.af-e2e/e2e_copy_dest.txt")"
  fi
else
  DEST="${ROOT}/test-app_rc_smoke"
  export SMOKE_PLUGIN_VERSION="${SMOKE_PLUGIN_VERSION:-}"
  "${ROOT}/scripts/sync-test-app-rc-smoke.sh"
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
  "${ROOT}/scripts/cordova-ios-pod-install.sh" --update-specs
  cordova platform add ios --no-interactive
elif [[ "$PLATFORM" == ios ]]; then
  "${ROOT}/scripts/cordova-ios-pod-install.sh" "$DEST"
fi

ios_bc="${CORDOVA_E2E_IOS_BUILDCONFIG:-}"
if [[ -z "$ios_bc" && -f "${PWD}/build.json" ]]; then
  ios_bc="${PWD}/build.json"
fi

if [[ "$PLATFORM" == ios ]]; then
  if [[ "$ACTION" == run ]]; then
    echo "${LOG_PREFIX} ios run (build + simulator; same build.json as build when present)"
    if [[ "$MODE" == e2e ]]; then
      # ios-sim errors out ("Simulator already running") instead of reusing a booted simulator from
      # a prior run -- shut down first so repeated `run`s are idempotent and each launch is a real
      # cold start (this matters for cold-launch vs. warm-resume OneLink testing, not just cleanliness).
      xcrun simctl shutdown all >/dev/null 2>&1 || true
      # Reinstalling over the same bundle id does NOT clear its old Data container, so containers
      # from earlier `run`s pile up across devices. af-scenario-runner.sh finds the QA log file by
      # `find ... -name af_qa_logs.txt | head -1`, with no ordering guarantee -- a stale container
      # from a previous run can win over the current one, silently feeding the runner old log
      # content. Uninstall this bundle id from every device first so at most one container exists.
      ios_bundle_id="$(sed -n 's/.*<widget[^>]*id="\([^"]*\)".*/\1/p' config.xml | head -1)"
      if [[ -n "$ios_bundle_id" ]]; then
        for udid in $(xcrun simctl list devices 2>/dev/null | grep -Eo '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}'); do
          xcrun simctl uninstall "$udid" "$ios_bundle_id" >/dev/null 2>&1 || true
        done
      fi
    fi
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
    echo "${LOG_PREFIX} android run (build + emulator)"
    cordova run android --debug --emulator
  else
    cordova build android --debug
  fi
fi
