# ─── AppsFlyer Cordova Plugin — manual test app (Angular + Ionic) ──────────
#
# Simple build+run helper for manual UI smoke testing of the plugin's Cordova
# integration. Not a substitute for the root Makefile's `make e2e-ios` /
# `make e2e-android` (automated, assertion-driven) -- this just gets the app
# on a device/simulator/emulator so you can click through it by hand.
#
# This app lives inside the plugin repo (examples/ionic-cordova), so a local
# plugin spec pointed at the repo root would copy the repo into a
# subdirectory of itself (ENAMETOOLONG) -- scripts/sync-example-app.sh mirrors
# test-app's own e2e fix for the same problem: sync out to a sibling
# directory first, then run every npm/Cordova command there.
#
# No `ionic` CLI dependency here (none in package.json, none needed) -- `ng
# build` (angular.json outputPath: "www") is what populates www/, which
# config.xml's <content src="index.html"> already points at; `cordova run`
# alone won't regenerate it from Angular sources the way it does for a plain
# Cordova app, so the Angular build always runs first.
#
# Usage:
#   make ios       Sync out, build the Angular app, add the iOS platform if
#                  missing, run
#   make android   Sync out, build the Angular app, boot an emulator if none
#                  is running, add the Android platform if missing, run
#   make clean     Remove the synced-out copy

SHELL := /bin/bash
PLUGIN_ROOT := $(abspath ../..)
DEST := $(dir $(PLUGIN_ROOT))$(notdir $(PLUGIN_ROOT))-example-ionic-cordova

.PHONY: sync
sync:
	"$(PLUGIN_ROOT)/scripts/sync-example-app.sh" ionic-cordova "$(DEST)"

.PHONY: install
install: sync
	cd "$(DEST)" && npm install
	# cordova-plugin-ionic-webview@5.0.1 (last published version)'s plugin.xml
	# unconditionally injects <preference name="deployment-target" value="11.0"/> --
	# not even a valid Xcode 26 target -- which config.xml's own 13.0 preference
	# loses to (Cordova's config merge takes the *last* matching <preference>, and
	# the plugin's is injected after ours). Patch the vendored plugin.xml in place;
	# no newer release exists to pick this up from upstream.
	sed -i '' 's/deployment-target" value="11.0"/deployment-target" value="13.0"/' \
		"$(DEST)/node_modules/cordova-plugin-ionic-webview/plugin.xml"

.PHONY: build
build: install
	cd "$(DEST)" && npm run build

.PHONY: ios
ios: build
	# cordova-ios's ios-sim wrapper throws "Simulator already running" as an unhandled
	# error if Simulator.app already has a booted device -- shut it down first so
	# `cordova run ios` can boot it cleanly itself.
	@xcrun simctl shutdown all 2>/dev/null || true
	@killall Simulator 2>/dev/null || true
	cd "$(DEST)" && (test -d platforms/ios || cordova platform add ios) && cordova run ios

# ─── Android ────────────────────────────────────────────────────────────────

# ANDROID_HOME/ANDROID_SDK_ROOT are frequently unset in interactive shells even
# when the SDK is installed (usually only exported from .zshrc, which `make`
# doesn't source) -- fall back to the default install location.
ANDROID_SDK := $(or $(ANDROID_HOME),$(ANDROID_SDK_ROOT),$(HOME)/Library/Android/sdk)
ADB := $(ANDROID_SDK)/platform-tools/adb
EMULATOR := $(ANDROID_SDK)/emulator/emulator
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
		nohup "$(EMULATOR)" -avd "$$AVD" -no-snapshot -netdelay none -netspeed full >/tmp/af-ionic-cordova-emulator.log 2>&1 & \
		"$(ADB)" wait-for-device; \
		until [ "$$("$(ADB)" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done; \
	fi

.PHONY: android
android: build ensure-android-emu
	cd "$(DEST)" && (test -d platforms/android || cordova platform add android) && cordova run android

.PHONY: clean
clean:
	rm -rf "$(DEST)"

.PHONY: help
help:
	@echo "make ios       Sync out, build, add iOS platform if needed, run"
	@echo "make android   Sync out, build, boot emulator if needed, add Android platform if needed, run"
	@echo "make clean     Remove the synced-out copy ($(DEST))"
