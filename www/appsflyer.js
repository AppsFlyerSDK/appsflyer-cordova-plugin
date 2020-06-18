var exec = require("cordova/exec"),
  argscheck = require("cordova/argscheck"),
  AppsFlyerError = require("./AppsFlyerError");

var callbackMap = {};

if (!window.CustomEvent) {
  window.CustomEvent = function (type, config) {
    var e = document.createEvent("CustomEvent");
    e.initCustomEvent(type, true, true, config.detail);
    return e;
  };
}

(function (global) {
  var AppsFlyer = function () {};

  /**
   * initialize the SDK.
   * args: SDK configuration
   * successCB: Success callback - called after successful SDK initialization.
   * errorCB: Error callback - called when error occurs during initialization.
   */
  AppsFlyer.prototype.initSdk = function (args, successCB, errorCB) {
    argscheck.checkArgs("O", "AppsFlyer.initSdk", arguments);
    if (!args) {
      if (errorCB) {
        errorCB(AppsFlyerError.INVALID_ARGUMENT_ERROR);
      }
    } else {
      if (args.appId !== undefined && typeof args.appId != "string") {
        if (errorCB) {
          errorCB(AppsFlyerError.APPID_NOT_VALID);
        }
      } else if (args.devKey !== undefined && typeof args.devKey != "string") {
        if (errorCB) {
          errorCB(AppsFlyerError.DEVKEY_NOT_VALID);
        }
      } else {
        exec(successCB, errorCB, "AppsFlyerPlugin", "initSdk", [args]);

        document.addEventListener("resume", this.onResume.bind(this), false);

        callbackMap.convSuc = successCB;
        callbackMap.convErr = errorCB;
      }
    }
  };

  /**
   * onAppOpenAttributionSuccess: Success callback - called after receiving data on App Open Attribution.
   * onAppOpenAttributionError: Error callback - called when error occurs.
   */
  AppsFlyer.prototype.registerOnAppOpenAttribution = function (
    onAppOpenAttributionSuccess,
    onAppOpenAttributionError
  ) {
    argscheck.checkArgs(
      "FF",
      "AppsFlyer.registerOnAppOpenAttribution",
      arguments
    );

    callbackMap.attrSuc = onAppOpenAttributionSuccess;
    callbackMap.attrErr = onAppOpenAttributionError;

    exec(
      onAppOpenAttributionSuccess,
      onAppOpenAttributionError,
      "AppsFlyerPlugin",
      "registerOnAppOpenAttribution",
      []
    );
  };

  AppsFlyer.prototype.onResume = function () {
    if (callbackMap.convSuc) {
      exec(
        callbackMap.convSuc,
        callbackMap.convErr,
        "AppsFlyerPlugin",
        "resumeSDK",
        []
      );
    }

    if (callbackMap.attrSuc) {
      exec(
        callbackMap.attrSuc,
        callbackMap.attrErr,
        "AppsFlyerPlugin",
        "registerOnAppOpenAttribution",
        []
      );
    }
  };

  /**
   * currencyId: ISO 4217 Currency Codes
   */
  AppsFlyer.prototype.setCurrencyCode = function (currencyId) {
    argscheck.checkArgs("S", "AppsFlyer.setCurrencyCode", arguments);
    exec(null, null, "AppsFlyerPlugin", "setCurrencyCode", [currencyId]);
  };

  /**
   * Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs.
   */
  AppsFlyer.prototype.setAppUserId = function (customerUserId) {
    argscheck.checkArgs("S", "AppsFlyer.setAppUserId", arguments);
    exec(null, null, "AppsFlyerPlugin", "setAppUserId", [customerUserId]);
  };

  /**
   * Set your GCM project number.
   */
  AppsFlyer.prototype.setGCMProjectNumber = function (gcmProjectNumber) {
    argscheck.checkArgs("S", "AppsFlyer.setGCMProjectNumber", arguments);
    exec(null, null, "AppsFlyerPlugin", "setGCMProjectNumber", [
      gcmProjectNumber,
    ]);
  };

  /**
   * Get Appsflyer ID
   */
  AppsFlyer.prototype.getAppsFlyerUID = function (successCB) {
    argscheck.checkArgs("F", "AppsFlyer.getAppsFlyerUID", arguments);
    exec(
      function (result) {
        successCB(result);
      },
      null,
      "AppsFlyerPlugin",
      "getAppsFlyerUID",
      []
    );
  };

  /**
   * End User Opt-Out from AppsFlyer analytics (Anonymize user data).
   */
  AppsFlyer.prototype.setDeviceTrackingDisabled = function (isDisabled) {
    argscheck.checkArgs("*", "AppsFlyer.setDeviceTrackingDisabled", arguments);
    exec(null, null, "AppsFlyerPlugin", "setDeviceTrackingDisabled", [
      isDisabled,
    ]);
  };

  /**
   * Shut down all SDK tracking
   */
  AppsFlyer.prototype.stopTracking = function (isStopTracking) {
    argscheck.checkArgs("*", "AppsFlyer.stopTracking", arguments);
    exec(null, null, "AppsFlyerPlugin", "stopTracking", [isStopTracking]);
  };

  /**
   * Track rich in-app events
   * eventName: custom event name, is presented in your dashboard.
   * eventValue: event details
   * successCB: Success callback - called after successful event tracking.
   * errorCB: Error callback - called when error occurs.
   */
  AppsFlyer.prototype.trackEvent = function (
    eventName,
    eventValue,
    successCB,
    errorCB
  ) {
    argscheck.checkArgs("SO", "AppsFlyer.trackEvent", arguments);
    exec(successCB, errorCB, "AppsFlyerPlugin", "trackEvent", [
      eventName,
      eventValue,
    ]);
  };

  /**
   * (Android) Enables app uninstall tracking
   * gcmProjectNumber: GCM/FCM ProjectNumber
   * successCB: Success callback - called after successful register uninstall.
   * errorCB: Error callback - called when error occurs.
   */
  AppsFlyer.prototype.enableUninstallTracking = function (
    gcmProjectNumber,
    successCB,
    errorCB
  ) {
    argscheck.checkArgs("S", "AppsFlyer.enableUninstallTracking", arguments);
    exec(successCB, errorCB, "AppsFlyerPlugin", "enableUninstallTracking", [
      gcmProjectNumber,
    ]);
  };

  /**
   * (Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Uninstall Tracking.
   */
  AppsFlyer.prototype.updateServerUninstallToken = function (token) {
    argscheck.checkArgs("S", "AppsFlyer.updateServerUninstallToken", arguments);
    exec(null, null, "AppsFlyerPlugin", "updateServerUninstallToken", [token]);
  };

  /**
   * Set AppsFlyer’s OneLink ID
   * args: oneLinkID.
   */
  AppsFlyer.prototype.setAppInviteOneLinkID = function (args) {
    argscheck.checkArgs("S", "AppsFlyer.setAppInviteOneLinkID", arguments);
    exec(null, null, "AppsFlyerPlugin", "setAppInviteOneLinkID", [args]);
  };

  /**
   * Allowing your existing users to invite their friends and contacts as new users to your app
   * args: Parameters for Invite link.
   * successCB: Success callback (generated link).
   * errorCB: Error callback.
   */
  AppsFlyer.prototype.generateInviteLink = function (args, successCB, errorCB) {
    argscheck.checkArgs("O", "AppsFlyer.generateInviteLink", arguments);
    exec(successCB, errorCB, "AppsFlyerPlugin", "generateInviteLink", [args]);
  };

  /**
   * Track cross promotion impression. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
   * appId: Promoted Application ID
   * campaign: Promoted Campaign
   */
  AppsFlyer.prototype.trackCrossPromotionImpression = function (
    appId,
    campaign
  ) {
    argscheck.checkArgs(
      "*",
      "AppsFlyer.trackCrossPromotionImpression",
      arguments
    );
    exec(null, null, "AppsFlyerPlugin", "trackCrossPromotionImpression", [
      appId,
      campaign,
    ]);
  };

  /**
   * Launch the app store's app page (via Browser).
   * appId: Promoted Application ID.
   * campaign: Promoted Campaign.
   * params: Additional Parameters to track.
   */
  AppsFlyer.prototype.trackAndOpenStore = function (appId, campaign, params) {
    argscheck.checkArgs("*", "AppsFlyer.trackAndOpenStore", arguments);
    exec(null, null, "AppsFlyerPlugin", "trackAndOpenStore", [
      appId,
      campaign,
      params,
    ]);
  };

  /**
   * Deep linking tracking
   */
  AppsFlyer.prototype.handleOpenUrl = function (url) {
    argscheck.checkArgs("*", "AppsFlyer.handleOpenUrl", arguments);
    exec(null, null, "AppsFlyerPlugin", "handleOpenUrl", [url]);
  };

  /**
   * (iOS) Allows to pass APN Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Uninstall Tracking.
   * token: APN Token.
   */
  AppsFlyer.prototype.registerUninstall = function (token) {
    argscheck.checkArgs("*", "AppsFlyer.registerUninstall", arguments);
    exec(null, null, "AppsFlyerPlugin", "registerUninstall", [token]);
  };

  /**
   * Get the current SDK version
   * successCB: Success callback that returns the SDK version
   */
  AppsFlyer.prototype.getSdkVersion = function (successCB) {
    exec(successCB, null, "AppsFlyerPlugin", "getSdkVersion", []);
  };

  module.exports = new AppsFlyer();
})(window);
