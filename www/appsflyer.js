var exec = require('cordova/exec'),
	argscheck = require('cordova/argscheck'),
	AppsFlyerError = require('./AppsFlyerError');

var callbackMap = {};

if (!window.CustomEvent) {
	window.CustomEvent = function (type, config) {
		var e = document.createEvent('CustomEvent');
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
		argscheck.checkArgs('O', 'AppsFlyer.initSdk', arguments);
		if (!args) {
			if (errorCB) {
				errorCB(AppsFlyerError.INVALID_ARGUMENT_ERROR);
			}
		} else {
			if (args.appId !== undefined && typeof args.appId != 'string') {
				if (errorCB) {
					errorCB(AppsFlyerError.APPID_NOT_VALID);
				}
			} else if (args.devKey !== undefined && typeof args.devKey != 'string') {
				if (errorCB) {
					errorCB(AppsFlyerError.DEVKEY_NOT_VALID);
				}
			} else {
				exec(successCB, errorCB, 'AppsFlyerPlugin', 'initSdk', [args]);

				document.addEventListener('resume', this.onResume.bind(this), false);

				callbackMap.convSuc = successCB;
				callbackMap.convErr = errorCB;
			}
		}
	};

	/**
	 * onAppOpenAttributionSuccess: Success callback - called after receiving data on App Open Attribution.
	 * onAppOpenAttributionError: Error callback - called when error occurs.
	 */
	AppsFlyer.prototype.registerOnAppOpenAttribution = function (onAppOpenAttributionSuccess, onAppOpenAttributionError) {
		argscheck.checkArgs('FF', 'AppsFlyer.registerOnAppOpenAttribution', arguments);

		callbackMap.attrSuc = onAppOpenAttributionSuccess;
		callbackMap.attrErr = onAppOpenAttributionError;

		exec(onAppOpenAttributionSuccess, onAppOpenAttributionError, 'AppsFlyerPlugin', 'registerOnAppOpenAttribution', []);
	};

	AppsFlyer.prototype.onResume = function () {
		if (callbackMap.convSuc) {
			exec(callbackMap.convSuc, callbackMap.convErr, 'AppsFlyerPlugin', 'resumeSDK', []);
		}

		if (callbackMap.attrSuc) {
			exec(callbackMap.attrSuc, callbackMap.attrErr, 'AppsFlyerPlugin', 'registerOnAppOpenAttribution', []);
		}
	};

	/**
	 * currencyId: ISO 4217 Currency Codes
	 */
	AppsFlyer.prototype.setCurrencyCode = function (currencyId) {
		argscheck.checkArgs('S', 'AppsFlyer.setCurrencyCode', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'setCurrencyCode', [currencyId]);
	};

	/**
	 * Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs.
	 */
	AppsFlyer.prototype.setAppUserId = function (customerUserId) {
		argscheck.checkArgs('S', 'AppsFlyer.setAppUserId', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'setAppUserId', [customerUserId]);
	};

	/**
	 * Get Appsflyer ID
	 */
	AppsFlyer.prototype.getAppsFlyerUID = function (successCB) {
		argscheck.checkArgs('F', 'AppsFlyer.getAppsFlyerUID', arguments);
		exec(
			function (result) {
				successCB(result);
			},
			null,
			'AppsFlyerPlugin',
			'getAppsFlyerUID',
			[]
		);
	};

	/**
	 * End User Opt-Out from AppsFlyer analytics (Anonymize user data).
	 */
	AppsFlyer.prototype.anonymizeUser = function (isDisabled) {
		argscheck.checkArgs('*', 'AppsFlyer.anonymizeUser', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'anonymizeUser', [isDisabled]);
	};

	/**
	 * Shut down SDK
	 */
	AppsFlyer.prototype.Stop = function (isStop) {
		argscheck.checkArgs('*', 'AppsFlyer.Stop', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'Stop', [isStop]);
	};

	/**
	 * Log rich in-app events
	 * eventName: custom event name, is presented in your dashboard.
	 * eventValue: event details
	 * successCB: Success callback - called after event sent successful  .
	 * errorCB: Error callback - called when error occurs.
	 */
	AppsFlyer.prototype.logEvent = function (eventName, eventValue, successCB, errorCB) {
		argscheck.checkArgs('SO', 'AppsFlyer.logEvent', arguments);
		exec(successCB, errorCB, 'AppsFlyerPlugin', 'logEvent', [eventName, eventValue]);
	};

	/**
	 * (Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Uninstall log.
	 */
	AppsFlyer.prototype.updateServerUninstallToken = function (token) {
		argscheck.checkArgs('S', 'AppsFlyer.updateServerUninstallToken', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'updateServerUninstallToken', [token]);
	};

	/**
	 * Set AppsFlyer’s OneLink ID
	 * args: oneLinkID.
	 */
	AppsFlyer.prototype.setAppInviteOneLinkID = function (args) {
		argscheck.checkArgs('S', 'AppsFlyer.setAppInviteOneLinkID', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'setAppInviteOneLinkID', [args]);
	};

	/**
	 * Allowing your existing users to invite their friends and contacts as new users to your app
	 * args: Parameters for Invite link.
	 * successCB: Success callback (generated link).
	 * errorCB: Error callback.
	 */
	AppsFlyer.prototype.generateInviteLink = function (args, successCB, errorCB) {
		argscheck.checkArgs('O', 'AppsFlyer.generateInviteLink', arguments);
		exec(successCB, errorCB, 'AppsFlyerPlugin', 'generateInviteLink', [args]);
	};

	/**
	 * log cross promotion impression. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
	 * appId: Promoted Application ID
	 * campaign: Promoted Campaign
	 */
	AppsFlyer.prototype.logCrossPromotionImpression = function (appId, campaign) {
		argscheck.checkArgs('*', 'AppsFlyer.logCrossPromotionImpression', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'logCrossPromotionImpression', [appId, campaign]);
	};

	/**
	 * Launch the app store's app page (via Browser).
	 * appId: Promoted Application ID.
	 * campaign: Promoted Campaign.
	 * params: Additional Parameters to log.
	 */
	AppsFlyer.prototype.logCrossPromotionAndOpenStore = function (appId, campaign, params) {
		argscheck.checkArgs('*', 'AppsFlyer.logCrossPromotionAndOpenStore', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'logCrossPromotionAndOpenStore', [appId, campaign, params]);
	};

	/**
	 * Log deep linking
	 */
	AppsFlyer.prototype.handleOpenUrl = function (url) {
		argscheck.checkArgs('*', 'AppsFlyer.handleOpenUrl', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'handleOpenUrl', [url]);
	};

	/**
	 * (iOS) Allows to pass APN Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for log Uninstall.
	 * token: APN Token.
	 */
	AppsFlyer.prototype.registerUninstall = function (token) {
		argscheck.checkArgs('*', 'AppsFlyer.registerUninstall', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'registerUninstall', [token]);
	};

	/**
	 * Get the current SDK version
	 * successCB: Success callback that returns the SDK version
	 */
	AppsFlyer.prototype.getSdkVersion = function (successCB) {
		exec(successCB, null, 'AppsFlyerPlugin', 'getSdkVersion', []);
	};

	/**
	 * Used by advertisers to exclude specified networks/integrated partners from getting data
	 * networks Comma separated array of partners that need to be excluded
	 */
	AppsFlyer.prototype.setSharingFilter = function (networks) {
		exec(null, null, 'AppsFlyerPlugin', 'setSharingFilter', [networks]);
	};

	/**
	 * Used by advertisers to exclude all networks/integrated partners from getting data
	 */
	AppsFlyer.prototype.setSharingFilterForAllPartners = function () {
		argscheck.checkArgs('*', 'AppsFlyer.setSharingFilterForAllPartners', arguments);
		exec(null, null, 'AppsFlyerPlugin', 'setSharingFilterForAllPartners', []);
	};

	module.exports = new AppsFlyer();
})(window);
