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

.PHONY: ensure-android-emu
ensure-android-emu:
	$(MAKE) -C "$(PLUGIN_ROOT)" ensure-android-emu

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
