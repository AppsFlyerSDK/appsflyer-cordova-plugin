"use strict";

const fs = require("fs");
const path = require("path");
const child_process = require("child_process");

function isStrictModeEnabled(configXmlContent) {
  if (!configXmlContent) return false;
  const match =
    /<preference\s+[^>]*name=["']appsflyerstrictmode["'][^>]*value=["']([^"']+)["']/i.exec(configXmlContent) ||
    /<preference\s+[^>]*value=["']([^"']+)["'][^>]*name=["']appsflyerstrictmode["']/i.exec(configXmlContent);
  return match ? match[1].trim().toLowerCase() === "true" : false;
}

function updatePodfile(content, isStrictMode) {
  if (!content) return content;
  if (isStrictMode) {
    return content.replace(/(pod\s+['"])AppsFlyerRPC(?!\/Strict)(['",\s])/g, "$1AppsFlyerRPC/Strict$2");
  } else {
    return content.replace(/(pod\s+['"])AppsFlyerRPC\/Strict(['",\s])/g, "$1AppsFlyerRPC$2");
  }
}

function updateAndroidManifest(content, isStrictMode) {
  if (!content) return content;
  if (isStrictMode) {
    const adIdRegex = /\s*<uses-permission\s+android:name=["']com\.google\.android\.gms\.permission\.AD_ID["']\s*\/?>/g;
    return content.replace(adIdRegex, "");
  }
  return content;
}

function runPodInstall(iosPlatformPath) {
  try {
    console.log("[AppsFlyer] Podfile updated for strict mode. Running 'pod install'...");
    const res = child_process.spawnSync("pod", ["install"], {
      cwd: iosPlatformPath,
      stdio: "inherit",
    });
    if (res.error || res.status !== 0) {
      console.warn("[AppsFlyer] Note: 'pod install' did not complete automatically. Run 'pod install' inside platforms/ios.");
    }
  } catch {
    console.warn("[AppsFlyer] Note: Run 'pod install' inside platforms/ios to apply CocoaPods changes.");
  }
}

function handleIos(projectRoot, isStrictMode) {
  const iosPlatformPath = path.join(projectRoot, "platforms", "ios");
  if (!fs.existsSync(iosPlatformPath)) {
    return;
  }

  const podfilePath = path.join(iosPlatformPath, "Podfile");
  if (fs.existsSync(podfilePath)) {
    const currentPodfile = fs.readFileSync(podfilePath, "utf-8");
    const updatedPodfile = updatePodfile(currentPodfile, isStrictMode);
    if (updatedPodfile !== currentPodfile) {
      fs.writeFileSync(podfilePath, updatedPodfile, "utf-8");
      runPodInstall(iosPlatformPath);
    }
  }
}

function handleAndroid(projectRoot, isStrictMode) {
  if (!isStrictMode) return;

  const androidPlatformPath = path.join(projectRoot, "platforms", "android");
  if (!fs.existsSync(androidPlatformPath)) {
    return;
  }

  const manifestPaths = [
    path.join(androidPlatformPath, "app", "src", "main", "AndroidManifest.xml"),
    path.join(androidPlatformPath, "AndroidManifest.xml"),
  ];

  for (const manifestPath of manifestPaths) {
    if (fs.existsSync(manifestPath)) {
      const current = fs.readFileSync(manifestPath, "utf-8");
      const updated = updateAndroidManifest(current, isStrictMode);
      if (updated !== current) {
        fs.writeFileSync(manifestPath, updated, "utf-8");
        console.log("[AppsFlyer] Removed AD_ID permission from AndroidManifest.xml for strict mode.");
      }
    }
  }
}

module.exports = function (ctx) {
  const cordovaConfigPath = path.join(ctx.opts.projectRoot, "config.xml");
  if (!fs.existsSync(cordovaConfigPath)) {
    return;
  }

  const configContent = fs.readFileSync(cordovaConfigPath, "utf-8");
  const isStrictMode = isStrictModeEnabled(configContent);

  handleIos(ctx.opts.projectRoot, isStrictMode);
  handleAndroid(ctx.opts.projectRoot, isStrictMode);
};

module.exports.isStrictModeEnabled = isStrictModeEnabled;
module.exports.updatePodfile = updatePodfile;
module.exports.updateAndroidManifest = updateAndroidManifest;
