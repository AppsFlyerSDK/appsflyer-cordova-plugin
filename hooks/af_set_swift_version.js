"use strict";
// This plugin ships Swift source (AppsFlyerPlugin.swift, AppsFlyerAttribution.swift). cordova-ios
// never sets SWIFT_VERSION on a freshly generated project that had no Swift files of its own --
// Xcode then refuses to build at all ("SWIFT_VERSION '' is unsupported"). There's no config.xml
// preference for this in cordova-ios; setting the build setting directly is the only fix.
// Skipped entirely if the host app's own project already sets SWIFT_VERSION (don't override a
// deliberate choice, e.g. an app that already ships Swift and pinned a specific version).
const fs = require("fs");
const path = require("path");

const COMMENT_KEY = /_comment$/;
function nonComments(obj) {
  return Object.fromEntries(
    Object.entries(obj).filter(([key]) => !COMMENT_KEY.test(key))
  );
}

module.exports = function (ctx) {
  const cordovaConfigPath = path.join(ctx.opts.projectRoot, "config.xml");
  const configContent = fs.readFileSync(cordovaConfigPath, "utf-8");
  const nameMatch = /<name[^>]*>([\s\S]*)<\/name>/mi.exec(configContent);
  if (!nameMatch) {
    return;
  }
  const projectName = nameMatch[1].trim();
  const xcodeProjectPath = path.join(
    ctx.opts.projectRoot,
    "platforms",
    "ios",
    `${projectName}.xcodeproj`,
    "project.pbxproj"
  );
  if (!fs.existsSync(xcodeProjectPath)) {
    // iOS platform not added (e.g. an Android-only prepare run) -- nothing to patch.
    return;
  }

  const xcode = require("xcode");
  const xcodeProject = xcode.project(xcodeProjectPath);
  xcodeProject.parseSync();

  const configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
  for (const config of Object.keys(configurations)) {
    const buildSettings = configurations[config].buildSettings;
    if (!buildSettings.SWIFT_VERSION) {
      buildSettings.SWIFT_VERSION = "5.0";
    }
  }

  fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), "utf-8");
};
