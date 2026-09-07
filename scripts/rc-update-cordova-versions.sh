#!/usr/bin/env bash
# Bump Cordova plugin marketing version + native SDK pins (RC-prep).
# Used by .github/workflows/rc-release.yml prepare-branch.
#
# Usage (repo root):
#   ./scripts/rc-update-cordova-versions.sh <plugin_version> <ios_sdk_x.y.z> <android_sdk_x.y.z> \
#       <ios_framework_x.y.z> <android_plugin_bridge_x.y.z>
#
# Example:
#   ./scripts/rc-update-cordova-versions.sh 7.0.0-rc1 7.0.13 7.0.1 7.0.2 7.0.12
#
# ios_sdk = AppsFlyerRPC pod version. ios_framework = AppsFlyerFramework it depends on
# transitively (CocoaPods resolves this automatically — no explicit second pod in plugin.xml;
# tracked here only so package.json records what's actually running). android_sdk =
# af-android-sdk-bom/af-android-sdk. android_plugin_bridge = af-android-plugin-bridge, pinned
# explicitly because the BOM doesn't carry it yet.
#
# Updates: package.json (version + all 4 native version fields), plugin.xml (plugin version +
# AppsFlyerRPC pod spec), README.md "This plugin is built for" SDK lines,
# src/android/cordovaAF.gradle (af-android-sdk-bom + af-android-plugin-bridge).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export RC_PLUGIN_VERSION="${1:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> <ios_framework> <android_plugin_bridge>}"
export RC_IOS_SDK="${2:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> <ios_framework> <android_plugin_bridge>}"
export RC_ANDROID_SDK="${3:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> <ios_framework> <android_plugin_bridge>}"
export RC_IOS_FRAMEWORK="${4:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> <ios_framework> <android_plugin_bridge>}"
export RC_ANDROID_PLUGIN_BRIDGE="${5:?usage: $0 <plugin_version> <ios_sdk> <android_sdk> <ios_framework> <android_plugin_bridge>}"

"$ROOT/scripts/check-native-version-pairs.sh" "$RC_IOS_SDK" "$RC_IOS_FRAMEWORK" "$RC_ANDROID_SDK" "$RC_ANDROID_PLUGIN_BRIDGE"

node <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.env.ROOT || process.cwd();
const pv = process.env.RC_PLUGIN_VERSION;
const ios = process.env.RC_IOS_SDK;
const and = process.env.RC_ANDROID_SDK;
const iosFramework = process.env.RC_IOS_FRAMEWORK;
const androidPluginBridge = process.env.RC_ANDROID_PLUGIN_BRIDGE;

const pjPath = path.join(root, 'package.json');
const pj = JSON.parse(fs.readFileSync(pjPath, 'utf8'));
pj.version = pv;
pj.iosSdkVersion = ios;
pj.iosFrameworkVersion = iosFramework;
pj.androidSdkVersion = and;
pj.androidPluginBridgeVersion = androidPluginBridge;
fs.writeFileSync(pjPath, JSON.stringify(pj, null, 2) + '\n');

let xml = fs.readFileSync(path.join(root, 'plugin.xml'), 'utf8');
// Anchored to the <plugin> tag's own version attribute — a bare /version="[^"]+"/ matches the
// XML declaration's version="1.0" first (it appears earlier in the file) and corrupts it instead.
xml = xml.replace(/(<plugin\b[^>]*?\sversion=")[^"]+(")/, `$1${pv}$2`);
xml = xml.replace(
  /<pod name="AppsFlyerRPC" spec="[^"]*"\/>/,
  `<pod name="AppsFlyerRPC" spec="${ios}"/>`
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
  /com\.appsflyer:af-android-sdk-bom:[^']+/,
  `com.appsflyer:af-android-sdk-bom:${and}`
);
gradle = gradle.replace(
  /com\.appsflyer:af-android-plugin-bridge:[^']+/,
  `com.appsflyer:af-android-plugin-bridge:${androidPluginBridge}`
);
fs.writeFileSync(path.join(root, 'src/android/cordovaAF.gradle'), gradle);

console.log('[rc-update-cordova-versions] updated package.json, plugin.xml, README.md, cordovaAF.gradle');
NODE
