# ─── AppsFlyer Cordova Plugin — E2E Runner ──────────────────────────────────
#
# Thin wrapper around scripts/af-scenario-runner.sh (same runner CI uses via
# .github/workflows/ios-e2e.yml / android-e2e.yml) that also makes sure a
# simulator/emulator is actually up before the runner needs one — the runner
# itself just errors out if none is booted. Mirrors appsflyer-capacitor-plugin's
# Makefile of the same name.
#
# The runner's own --build drives scripts/e2e-cordova-build.sh (sync + npm
# install + `cordova build`), then does its own uninstall/install/launch via
# simctl/adb directly -- unlike `cordova run`, that's idempotent across repeat
# invocations (no stale data container left behind, no "simulator already
# running" error), so this is the wrapper to use over the old `cordova run`
# path for anything you want real pass/fail signal from.
#
# Usage:
#   make e2e-ios          Boot a simulator if needed, build, run E2E
#   make e2e-android      Boot an emulator if needed, build, run E2E
#   make e2e-all          Both platforms
#   make e2e-ios PHASE=phase_1 VERBOSE=1   Single phase, verbose
#   make report           Show latest report
#   make clean            Remove build artifacts and reports

SHELL := /bin/bash
RUNNER := scripts/af-scenario-runner.sh
PLAN := .af-e2e/test-plan.json
E2E_DIR := $(or $(TEST_APP_E2E_COPY_DEST),$(shell cat .af-e2e/e2e_copy_dest.txt 2>/dev/null),../appsflyer-cordova-plugin-e2e)

PHASE ?=
VERBOSE ?=
_PHASE_FLAG := $(if $(PHASE),--phase $(PHASE),)
_VERBOSE_FLAG := $(if $(VERBOSE),--verbose,)

# ─── iOS ────────────────────────────────────────────────────────────────────

.PHONY: ensure-ios-sim
ensure-ios-sim:
	@if xcrun simctl list devices booted -j | jq -e '.devices | to_entries[] | .value[] | select(.state=="Booted")' >/dev/null 2>&1; then \
		echo "iOS simulator already booted."; \
	else \
		echo "No booted iOS simulator, booting one..."; \
		UDID=$$(xcrun simctl list devices available -j | jq -r \
			'.devices | to_entries[] | select(.key | test("iOS-(1[7-9]|[2-9][0-9])")) | .value[] | select(.name | test("iPhone")) | .udid' | head -1); \
		test -n "$$UDID" || { echo "Error: no available iPhone simulator found."; exit 1; }; \
		xcrun simctl boot "$$UDID"; \
		open -a Simulator --args -CurrentDeviceUDID "$$UDID"; \
		xcrun simctl bootstatus "$$UDID" -b; \
	fi

.PHONY: e2e-ios
e2e-ios: ensure-ios-sim
	$(RUNNER) --platform ios --plan $(PLAN) --build $(_PHASE_FLAG) $(_VERBOSE_FLAG)

# ─── Android ────────────────────────────────────────────────────────────────

# ANDROID_HOME/ANDROID_SDK_ROOT are frequently unset in interactive shells
# even when Android Studio and the SDK are installed (they're normally only
# exported from .zshrc, which `make` doesn't source). Fall back to the
# default install locations so this works out of the box.
ANDROID_SDK := $(or $(ANDROID_HOME),$(ANDROID_SDK_ROOT),$(HOME)/Library/Android/sdk)
ADB := $(ANDROID_SDK)/platform-tools/adb
EMULATOR := $(ANDROID_SDK)/emulator/emulator
# Gradle (invoked by af-scenario-runner.sh's build_cmd, via scripts/e2e-cordova-build.sh) needs
# ANDROID_HOME in its own environment, not just as a Make variable — export it to children.
# JDK selection is left to e2e-cordova-build.sh's own pick_java_home_for_android (Cordova
# Android/cordova-android 13 builds fine on JDK 17, unlike Capacitor's Android module).
export ANDROID_HOME := $(ANDROID_SDK)

.PHONY: ensure-android-emu
ensure-android-emu:
	@test -x "$(ADB)" || { echo "Error: adb not found at $(ADB). Set ANDROID_HOME or install the SDK."; exit 1; }
	@if "$(ADB)" devices | awk 'NR>1 && $$2=="device"{found=1} END{exit !found}'; then \
		echo "Android emulator/device already running."; \
	else \
		echo "No running Android device, booting an emulator..."; \
		test -x "$(EMULATOR)" || { echo "Error: emulator not found at $(EMULATOR). Set ANDROID_HOME or install the SDK."; exit 1; }; \
		AVD=$$("$(EMULATOR)" -list-avds | head -1); \
		test -n "$$AVD" || { echo "Error: no AVD found. Create one first (Android Studio > Device Manager)."; exit 1; }; \
		echo "Booting AVD: $$AVD"; \
		nohup "$(EMULATOR)" -avd "$$AVD" -no-snapshot -netdelay none -netspeed full >/tmp/af-emulator.log 2>&1 & \
		"$(ADB)" wait-for-device; \
		until [ "$$("$(ADB)" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done; \
	fi

.PHONY: e2e-android
e2e-android: ensure-android-emu
	$(RUNNER) --platform android --plan $(PLAN) --build $(_PHASE_FLAG) $(_VERBOSE_FLAG)

# ─── Both ───────────────────────────────────────────────────────────────────

.PHONY: e2e-all
e2e-all: e2e-ios e2e-android

# ─── Utilities ──────────────────────────────────────────────────────────────

.PHONY: report
report:
	@latest=$$(ls -t .af-e2e/reports/*.json 2>/dev/null | head -1); \
	test -n "$$latest" || { echo "No reports found."; exit 1; }; \
	echo "Latest report: $$latest"; \
	python3 -m json.tool "$$latest" | head -40

.PHONY: clean
clean:
	rm -rf .af-e2e/reports/*
	rm -rf "$(E2E_DIR)/platforms/ios/build"
	cd "$(E2E_DIR)/platforms/android" && ./gradlew clean -q 2>/dev/null || true
	@echo "Cleaned build artifacts and reports."

.PHONY: help
help:
	@echo "make e2e-ios      Boot simulator if needed, build, run iOS E2E"
	@echo "make e2e-android  Boot emulator if needed, build, run Android E2E"
	@echo "make e2e-all      Both platforms"
	@echo "make report       Show latest report"
	@echo "make clean        Remove build artifacts and reports"
