#!/usr/bin/env bash
# Bump Cordova plugin marketing version + native SDK pins (RC-prep).
# Used by .github/workflows/rc-release.yml prepare-branch.
#
# Usage (repo root):
#   ./scripts/rc-update-cordova-versions.sh <plugin_version> <ios_sdk_x.y.z> <android_sdk_x.y.z> [appsflyer_rpc_version]
#
# Example:
#   ./scripts/rc-update-cordova-versions.sh 7.0.1 7.0.1 7.0.1 7.0.1
#
# Updates: package.json "version", plugin.xml (plugin version + iOS pods),
# README.md "This plugin is built for" SDK lines, src/android/cordovaAF.gradle BOM,
# AppsFlyerConstants.java PLUGIN_VERSION, AppsFlyerPlugin.swift cordovaPluginVersion.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export RC_PLUGIN_VERSION="${1:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> [appsflyer_rpc_version]}"
export RC_IOS_SDK="${2:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> [appsflyer_rpc_version]}"
export RC_ANDROID_SDK="${3:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> [appsflyer_rpc_version]}"
export RC_APPSFLYER_RPC_VERSION="${4:-$RC_IOS_SDK}"

node <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.env.ROOT || process.cwd();
const pv = process.env.RC_PLUGIN_VERSION;
const ios = process.env.RC_IOS_SDK;
const and = process.env.RC_ANDROID_SDK;
const rpc = process.env.RC_APPSFLYER_RPC_VERSION;

const pjPath = path.join(root, 'package.json');
const pj = JSON.parse(fs.readFileSync(pjPath, 'utf8'));
pj.version = pv;
fs.writeFileSync(pjPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(root, 'plugin.xml'), 'utf8');
xml = xml.replace(/version="[^"]+"/, `version="${pv}"`);
xml = xml.replace(
  /<pod name="AppsFlyerFramework" spec="[^"]*"\/>/,
  `<pod name="AppsFlyerFramework" spec="${ios}"/>`
);
xml = xml.replace(
  /<pod name="AppsFlyerRPC" spec="[^"]*"\/>/,
  `<pod name="AppsFlyerRPC" spec="${rpc}"/>`
);
fs.writeFileSync(path.join(root, 'plugin.xml'), xml);

let readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
readme = readme.replace(
  /iOS AppsFlyerSDK \*\*v[0-9.]+\*\*/,
  `iOS AppsFlyerSDK **v${ios}**`
);
readme = readme.replace(
  /Android AppsFlyerSDK \*\*v[0-9.]+\*\*/,
  `Android AppsFlyerSDK **v${and}**`
);
fs.writeFileSync(path.join(root, 'README.md'), readme);

let gradle = fs.readFileSync(path.join(root, 'src/android/cordovaAF.gradle'), 'utf8');
gradle = gradle.replace(
  /com\.appsflyer:af-android-sdk-bom(-beta)?:[^"]+/,
  `com.appsflyer:af-android-sdk-bom:${and}`
);
fs.writeFileSync(path.join(root, 'src/android/cordovaAF.gradle'), gradle);

const constantsPath = path.join(root, 'src/android/com/appsflyer/cordova/plugin/AppsFlyerConstants.java');
let constants = fs.readFileSync(constantsPath, 'utf8');
constants = constants.replace(
  /PLUGIN_VERSION = "[^"]+"/,
  `PLUGIN_VERSION = "${pv}"`
);
fs.writeFileSync(constantsPath, constants);

const swiftPath = path.join(root, 'src/ios/AppsFlyerPlugin.swift');
let swift = fs.readFileSync(swiftPath, 'utf8');
swift = swift.replace(
  /cordovaPluginVersion = "[^"]+"/,
  `cordovaPluginVersion = "${pv}"`
);
fs.writeFileSync(swiftPath, swift);

console.log('[rc-update-cordova-versions] updated package.json, plugin.xml, README.md, cordovaAF.gradle, AppsFlyerConstants.java, AppsFlyerPlugin.swift');
NODE
