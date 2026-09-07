"use strict";
// This plugin ships Swift source (AppsFlyerPlugin.swift, AppsFlyerAttribution.swift). cordova-ios
// never sets SWIFT_VERSION on a freshly generated project that had no Swift files of its own --
// Xcode then refuses to build at all ("SWIFT_VERSION '' is unsupported"). There's no config.xml
// preference for this in cordova-ios; setting the build setting directly is the only fix.
// Skipped entirely if the host app's own project already sets SWIFT_VERSION (don't override a
// deliberate choice, e.g. an app that already ships Swift and pinned a specific version).
var fs = require("fs");
var path = require("path");

var COMMENT_KEY = /_comment$/;
function nonComments(obj) {
  var newObj = {};
  Object.keys(obj).forEach(function (key) {
    if (!COMMENT_KEY.test(key)) {
      newObj[key] = obj[key];
    }
  });
  return newObj;
}

module.exports = function (ctx) {
  return new Promise(function (resolve, reject) {
    var cordovaConfigPath = path.join(ctx.opts.projectRoot, "config.xml");
    fs.readFile(cordovaConfigPath, { encoding: "utf-8" }, function (errConfigRead, configContent) {
      if (errConfigRead) {
        return reject(errConfigRead);
      }
      var projectName = /<name[^>]*>([\s\S]*)<\/name>/mi.exec(configContent)[1].trim();
      var xcodeProjectPath = path.join(ctx.opts.projectRoot, "platforms", "ios", projectName + ".xcodeproj", "project.pbxproj");
      if (!fs.existsSync(xcodeProjectPath)) {
        // iOS platform not added (e.g. an Android-only prepare run) -- nothing to patch.
        return resolve();
      }

      var xcode = require("xcode");
      var xcodeProject = xcode.project(xcodeProjectPath);
      xcodeProject.parse(function (parseError) {
        if (parseError) {
          return reject(parseError);
        }

        var configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
        Object.keys(configurations).forEach(function (config) {
          var buildSettings = configurations[config].buildSettings;
          if (!buildSettings.SWIFT_VERSION) {
            buildSettings.SWIFT_VERSION = "5.0";
          }
        });

        fs.writeFile(xcodeProjectPath, /*eslint-disable no-sync*/ xcodeProject.writeSync() /*eslint-enable*/, { encoding: "utf-8" }, function (projectWriteError) {
          if (projectWriteError) {
            return reject(projectWriteError);
          }
          resolve();
        });
      });
    });
  });
};
