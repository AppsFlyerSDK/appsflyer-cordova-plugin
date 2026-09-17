# ─── AppsFlyer Cordova Plugin — manual test app (plain Cordova) ────────────
#
# Simple build+run helper for manual UI smoke testing of the plugin's Cordova
# integration. Not a substitute for the root Makefile's `make e2e-ios` /
# `make e2e-android` (automated, assertion-driven) -- this just gets the app
# on a device/simulator/emulator so you can click through it by hand.
#
# This app lives inside the plugin repo (examples/cordovatestapp), so a local
# plugin spec pointed at the repo root would copy the repo into a
# subdirectory of itself (ENAMETOOLONG) -- scripts/sync-example-app.sh mirrors
# test-app's own e2e fix for the same problem: sync out to a sibling
# directory first, then run every Cordova command there.
#
# Usage:
#   make ios       Sync out, add the iOS platform if missing, build, run
#   make android   Sync out, boot an emulator if none is running, add the
#                  Android platform if missing, build, run
#   make clean     Remove the synced-out copy

SHELL := /bin/bash
PLUGIN_ROOT := $(abspath ../..)
DEST := $(dir $(PLUGIN_ROOT))$(notdir $(PLUGIN_ROOT))-example-cordovatestapp

.PHONY: sync
sync:
	"$(PLUGIN_ROOT)/scripts/sync-example-app.sh" cordovatestapp "$(DEST)"

.PHONY: install
install: sync
	cd "$(DEST)" && npm install

.PHONY: ios
ios: install
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
android: install ensure-android-emu
	cd "$(DEST)" && (test -d platforms/android || cordova platform add android) && cordova run android

.PHONY: clean
clean:
	rm -rf "$(DEST)"

.PHONY: help
help:
	@echo "make ios       Sync out, add iOS platform if needed, build, run"
	@echo "make android   Sync out, boot emulator if needed, add Android platform if needed, build, run"
	@echo "make clean     Remove the synced-out copy ($(DEST))"
