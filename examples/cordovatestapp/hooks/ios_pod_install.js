#!/usr/bin/env node
"use strict";

/**
 * Cordova after_prepare hook that runs `pod install` in platforms/ios.
 * This ensures CocoaPods dependencies are installed after prepare/build.
 */
var path = require("path");
var fs = require("fs");
var { execSync } = require("child_process");

module.exports = function (ctx) {
  var iosPath = path.join(ctx.opts.projectRoot, "platforms", "ios");
  var podfilePath = path.join(iosPath, "Podfile");

  if (!fs.existsSync(podfilePath)) {
    return;
  }

  try {
    execSync("pod install", { cwd: iosPath, stdio: "inherit" });
  } catch (err) {
    console.warn("Warning: pod install failed. You may need to run it manually in platforms/ios");
    throw err;
  }
};
