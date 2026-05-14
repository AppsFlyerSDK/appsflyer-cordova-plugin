#!/usr/bin/env bash
# Bump Cordova plugin marketing version + native SDK pins (RC-prep).
# Used by .github/workflows/rc-release.yml prepare-branch.
#
# Usage (repo root):
#   ./scripts/rc-update-cordova-versions.sh <plugin_version> <ios_sdk_x.y.z> <android_sdk_x.y.z>
#
# Example:
#   ./scripts/rc-update-cordova-versions.sh 6.19.0-rc1 6.19.0 6.19.0
#
# Updates: package.json "version", plugin.xml (plugin version + AppsFlyerFramework pod spec),
# README.md "This plugin is built for" SDK lines, src/android/cordovaAF.gradle af-android-sdk.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export RC_PLUGIN_VERSION="${1:?usage: $0 <plugin_version> <ios_sdk> <android_sdk>}"
export RC_IOS_SDK="${2:?usage: $0 <plugin_version> <ios_sdk> <android_sdk>}"
export RC_ANDROID_SDK="${3:?usage: $0 <plugin_version> <ios_sdk> <android_sdk>}"

node <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.env.ROOT || process.cwd();
const pv = process.env.RC_PLUGIN_VERSION;
const ios = process.env.RC_IOS_SDK;
const and = process.env.RC_ANDROID_SDK;

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
  /com\.appsflyer:af-android-sdk:[^@]+@aar/,
  `com.appsflyer:af-android-sdk:${and}@aar`
);
fs.writeFileSync(path.join(root, 'src/android/cordovaAF.gradle'), gradle);

console.log('[rc-update-cordova-versions] updated package.json, plugin.xml, README.md, cordovaAF.gradle');
NODE
