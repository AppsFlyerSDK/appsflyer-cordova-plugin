"use strict";
var fs = require("fs");
var path = require("path");

var COMMENT_KEY = /_comment$/;
function nonComments(obj) {
  var newObj = {};
  Object.keys(obj).forEach(function(key) {
    if (!COMMENT_KEY.test(key)) {
      newObj[key] = obj[key];
    }
  });
  return newObj;
}

module.exports = function(ctx) {
  var GCC_PREPROCESSOR_DEFINITIONS = '"$(inherited) AFSDK_SHOULD_SWIZZLE=1"';

  var q = require("q");
  var deferred = q.defer();

  var cordovaConfigPath = path.join(ctx.opts.projectRoot, "config.xml");
  fs.readFile(cordovaConfigPath, {encoding: "utf-8"}, function(errConfigRead, configContent) {
    if (errConfigRead) {
      return deferred.reject(errConfigRead);
    }
    var projectName = /<name[^>]*>([\s\S]*)<\/name>/mi.exec(configContent)[1].trim();
    var xcodeProjectName = [projectName, ".xcodeproj"].join("");
    var xcodeProjectPath = path.join(ctx.opts.projectRoot, "platforms", "ios", xcodeProjectName, "project.pbxproj");
    var xcode = require("xcode");
    var xcodeProject = xcode.project(xcodeProjectPath);
    xcodeProject.parse(function(parseError) {
      if (parseError) {
        return deferred.reject(parseError);
      }

      var configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());

      Object.keys(configurations).forEach(function(config) {
        var buildSettings = configurations[config].buildSettings;
        buildSettings.GCC_PREPROCESSOR_DEFINITIONS = GCC_PREPROCESSOR_DEFINITIONS;
      });

      fs.writeFile(xcodeProjectPath, /*eslint-disable no-sync*/xcodeProject.writeSync()/*eslint-enable*/, {encoding: "utf-8"}, function(projectWriteError) {
        if (projectWriteError) {
          return deferred.reject(projectWriteError);
        }
        deferred.resolve();
      });
    });
  });
  return deferred.promise;
};
