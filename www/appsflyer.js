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

    // Enum definition for MediationNetwork
    global.MediationNetwork = Object.freeze({
        IRONSOURCE: "ironsource",
        APPLOVIN_MAX: "applovinmax",
        GOOGLE_ADMOB: "googleadmob",
        FYBER: "fyber",
        APPODEAL: "appodeal",
        ADMOST: "Admost",
        TOPON: "Topon",
        TRADPLUS: "Tradplus",
        YANDEX: "Yandex",
        CHARTBOOST: "chartboost",
        UNITY: "Unity",
        TOPON_PTE: "toponpte",
        CUSTOM_MEDIATION: "customMediation",
        DIRECT_MONETIZATION_NETWORK: "directMonetizationNetwork"
    });


    var AppsFlyer = function () {
    };

    // Expose AppsFlyerConsent to the global scope
    /**
     * @class AppsFlyerConsent
     * @constructor
     * @param {boolean|null} isUserSubjectToGDPR - Indicates if the user is subject to GDPR.
     * @param {boolean|null} hasConsentForDataUsage - User's consent for data usage.
     * @param {boolean|null} hasConsentForAdsPersonalization - User's consent for ads personalization.
     * @param {boolean|null} hasConsentForAdStorage - User's consent for ad storage.
     */
    function AppsFlyerConsent(isUserSubjectToGDPR, hasConsentForDataUsage, hasConsentForAdsPersonalization, hasConsentForAdStorage) {
        this.isUserSubjectToGDPR = isUserSubjectToGDPR;
        this.hasConsentForDataUsage = hasConsentForDataUsage;
        this.hasConsentForAdsPersonalization = hasConsentForAdsPersonalization;
        this.hasConsentForAdStorage = hasConsentForAdStorage;
    }

    /**
     * @deprecated Use the constructor directly with four parameters instead.
     * Factory method for GDPR user.
     */
    AppsFlyerConsent.forGDPRUser = function (hasConsentForDataUsage, hasConsentForAdsPersonalization) {
        window.console.warn("[DEPRECATED] 'forGDPRUser' is deprecated. Use 'new AppsFlyerConsent' instead.");
        return new AppsFlyerConsent(true, hasConsentForDataUsage, hasConsentForAdsPersonalization, null);
    };

    /**
     * @deprecated Use the constructor directly with four parameters instead.
     * Factory method for non-GDPR user.
     */
    AppsFlyerConsent.forNonGDPRUser = function () {
        window.console.warn("[DEPRECATED] 'forNonGDPRUser' is deprecated. Use 'new AppsFlyerConsent' instead.");
        return new AppsFlyerConsent(false, null, null, null);
    };

    // Expose AppsFlyerConsent to the global scope
    global.AppsFlyerConsent = AppsFlyerConsent;


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
            if (args.appId !== undefined && (typeof args.appId != 'string' || args.appId === "")) {
                if (errorCB) {
                    errorCB(AppsFlyerError.APPID_NOT_VALID);
                }
            } else if (args.devKey !== undefined && typeof args.devKey != 'string') {
                if (errorCB) {
                    errorCB(AppsFlyerError.DEVKEY_NOT_VALID);
                }
            } else if (args.devKey === undefined || args.devKey === "") {
                if (errorCB) {
                    errorCB(AppsFlyerError.NO_DEVKEY_FOUND);
                }
            } else {
                exec(successCB, errorCB, 'AppsFlyerPlugin', 'initSdk', [args]);

                callbackMap.convSuc = successCB;
                callbackMap.convErr = errorCB;
            }
        }
    };

    /**
     * starts the SDK.
     *
     */
    AppsFlyer.prototype.startSdk = function () {
        exec(null, null, 'AppsFlyerPlugin', 'startSdk', []);
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

    /**
     * Register Unified deep link listener
     * @param onDeepLinkListener: ddl callback triggered when deep linked has been clicked and onDeepLinkListener = true;
     */
    AppsFlyer.prototype.registerDeepLink = function (onDeepLinkListener) {
        callbackMap.ddlSuc = onDeepLinkListener;
        exec(onDeepLinkListener, null, 'AppsFlyerPlugin', 'registerDeepLink', []);
    };

    /**
     * currencyId: ISO 4217 Currency Codes
     */
    AppsFlyer.prototype.setCurrencyCode = function (currencyId) {
        argscheck.checkArgs('S', 'AppsFlyer.setCurrencyCode', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'setCurrencyCode', [currencyId]);
    };

    /**
     * Public API - logAdRevenue function
     */
    AppsFlyer.prototype.logAdRevenue = function(afAdRevenueData, additionalParameters) {
        argscheck.checkArgs('OO', 'AppsFlyer.logAdRevenue', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'logAdRevenue', [afAdRevenueData, additionalParameters]);
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
     *
     */
    AppsFlyer.prototype.setSharingFilterForPartners = function (networks) {
        exec(null, null, 'AppsFlyerPlugin', 'setSharingFilterForPartners', [networks]);
    };

    /**
     * Used by advertisers to exclude specified networks/integrated partners from getting data
     * networks Comma separated array of partners that need to be excluded
     *  @deprecated deprecated since 6.4.0. Use setSharingFilterForPartners instead
     */
    AppsFlyer.prototype.setSharingFilter = function (networks) {
        exec(null, null, 'AppsFlyerPlugin', 'setSharingFilter', [networks]);
    };

    /**
     * Used by advertisers to exclude all networks/integrated partners from getting data
     *  @deprecated deprecated since 6.4.0. Use setSharingFilterForPartners instead
     */
    AppsFlyer.prototype.setSharingFilterForAllPartners = function () {
        argscheck.checkArgs('*', 'AppsFlyer.setSharingFilterForAllPartners', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'setSharingFilterForAllPartners', []);
    };

    /**
     * Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
     * Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases
     * @param purchaseInfo json includes: String publicKey, String signature, String purchaseData, String price, String currency, JSONObject additionalParameters.
     * @param successC Success callback
     * @param errorC Error callback
     */
    AppsFlyer.prototype.validateAndLogInAppPurchase = function (purchaseInfo, successC, errorC) {
        exec(successC, errorC, 'AppsFlyerPlugin', 'validateAndLogInAppPurchase', [purchaseInfo]);
    };

    /**
     * When testing purchase validation in the Sandbox environment, please make sure to set true.
     * @param isSandbox boolean value
     * @param successC Success callback
     * @param errorC Error callback
     */
    AppsFlyer.prototype.setUseReceiptValidationSandbox = function (isSandbox, successC, errorC) {
        exec(successC, errorC, 'AppsFlyerPlugin', 'setUseReceiptValidationSandbox', [isSandbox]);
    };

    /**
     * AppsFlyer SDK dynamically loads the Apple iAd.framework. This framework is required to record and measure the performance of Apple Search Ads in your app.
     * If you don't want AppsFlyer to dynamically load this framework, set this property to true.
     * @param collectASA
     * @param successC
     */
    AppsFlyer.prototype.disableCollectASA = function (collectASA, successC) {
        exec(successC, null, 'AppsFlyerPlugin', 'disableCollectASA', [collectASA]);
    };
    /**
     * AppsFlyer SDK dynamically loads the Apple adSupport.framework. This framework is required to collect IDFA for attribution purposes.
     * If you don't want AppsFlyer to dynamically load this framework, set this property to true.
     * @param disableAdvertisingIdentifier - true OR false
     * @param successC - callback function
     */
    AppsFlyer.prototype.setDisableAdvertisingIdentifier = function (disableAdvertisingIdentifier, successC) {
        exec(successC, null, 'AppsFlyerPlugin', 'setDisableAdvertisingIdentifier', [disableAdvertisingIdentifier]);
    };

    /**
     * Set Onelink custom/branded domains
     * Use this API during the SDK Initialization to indicate branded domains.
     * For more information please refer to https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links
     * @param domains array of strings
     * @param successC success callback
     * @param errorC error callback
     */
    AppsFlyer.prototype.setOneLinkCustomDomains = function (domains, successC, errorC) {
        exec(successC, errorC, 'AppsFlyerPlugin', 'setOneLinkCustomDomains', [domains]);
    };

    /**
     * use this api If you need deep linking data from Facebook, deferred deep linking, Dynamic Product Ads, or reasons that
     * unrelated to attribution such as authentication, ad monetization, social sharing, user invites, etc.
     * More information here: https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration
     * @param args: boolean value
     * @return
     */
    AppsFlyer.prototype.enableFacebookDeferredApplinks = function (isEnabled) {
        exec(null, null, 'AppsFlyerPlugin', 'enableFacebookDeferredApplinks', [isEnabled]);
    };

    /**
     * Facebook Advanced Matching
     * @param args: phone number
     * @param callbackContext
     * @return
     */
    AppsFlyer.prototype.setPhoneNumber = function (phoneNumber, successC) {
        exec(successC, null, 'AppsFlyerPlugin', 'setPhoneNumber', [phoneNumber]);
    };

    /**
     * Facebook Advanced Matching
     * @param userEmails: Strings array of emails
     * @param successC: success functions
     */
    AppsFlyer.prototype.setUserEmails = function (userEmails, successC) {
        exec(successC, null, 'AppsFlyerPlugin', 'setUserEmails', [userEmails]);
    };

    /**
     * Set a custom host
     * @param hostPrefix
     * @param hostName
     */
    AppsFlyer.prototype.setHost = function (hostPrefix, hostName) {
        exec(null, null, 'AppsFlyerPlugin', 'setHost', [hostPrefix, hostName]);
    };

    /**
     * The addPushNotificationDeepLinkPath method provides app owners with a flexible interface for configuring how deep links are extracted from push notification payloads.
     * for more information: https://support.appsflyer.com/hc/en-us/articles/207032126-Android-SDK-integration-for-developers#core-apis-65-configure-push-notification-deep-link-resolution
     * @param path: an array of string that represents the path
     */
    AppsFlyer.prototype.addPushNotificationDeepLinkPath = function (path) {
        exec(null, null, 'AppsFlyerPlugin', 'addPushNotificationDeepLinkPath', [path]);
    };

    /**
     * Use this API to get the OneLink from click domains that launch the app. Make sure to call this API before SDK initialization.
     * @param urls
     */
    AppsFlyer.prototype.setResolveDeepLinkURLs = function (urls) {
        exec(null, null, 'AppsFlyerPlugin', 'setResolveDeepLinkURLs', [urls]);
    };

    /**
     * enable or disable SKAD support. set True if you want to disable it!
     * @param isDisabled
     */
    AppsFlyer.prototype.disableSKAD = function (isDisabled) {
        exec(null, null, 'AppsFlyerPlugin', 'disableSKAD', [isDisabled]);
    };

    /**
     *  Set the language of the device. The data will be displayed in Raw Data Reports
     * @param language: The device language
     */
    AppsFlyer.prototype.setCurrentDeviceLanguage = function (language ){
        argscheck.checkArgs('S', 'AppsFlyer.setCurrentDeviceLanguage', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'setCurrentDeviceLanguage', [language]);

    };

    /**
     * The setAdditionalData API allows you to add custom data to events sent from the SDK.
     * Typically it is used to integrate on the SDK level with several external partner platforms
     * @param additionalData
     */
    AppsFlyer.prototype.setAdditionalData = function (additionalData){
        exec(null, null, 'AppsFlyerPlugin', 'setAdditionalData', [additionalData]);
    };

    /**
     * The setPartnerData API allows sending custom data for partner integration purposes.
     *
     * Typically it is used to integrate on the SDK level with several external partner platforms
     * @param partnerId - ID of the partner (usually suffixed with "_int")
     * @param data - Customer data, depends on the integration configuration with the specific partner
     */
    AppsFlyer.prototype.setPartnerData = function (partnerId, data){
        exec(null, null, 'AppsFlyerPlugin', 'setPartnerData', [partnerId, data]);
    };

    /**
     * Measure and get data from push-notification campaigns.
     * @param pushData - JSON object contains the push data
     */
    AppsFlyer.prototype.sendPushNotificationData = function (pushData){
        exec(null, null, 'AppsFlyerPlugin', 'sendPushNotificationData', [pushData]);
    };

    /**
     * Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device.
     * @param disable - Defaults to false
     */
    AppsFlyer.prototype.setDisableNetworkData = function (disable){
        exec(null, null, 'AppsFlyerPlugin', 'setDisableNetworkData', [disable]);
    };

    /**
     * Use to manually collecting the consent data from the user.
     * @param appsFlyerConsent - object of AppsFlyerConsent that holds three values when GDPR is applies to the user, and one value when It's not.
     * when GDPR applies to the user and your app does not use a CMP compatible with TCF v2.2, use this API to provide the consent data directly to the SDK.<br>
     */
    AppsFlyer.prototype.setConsentData = function (appsFlyerConsent){
        exec(null, null, 'AppsFlyerPlugin', 'setConsentData', [appsFlyerConsent]);
    };

    /**
     * set collect tcf data or not.
     *
     * @param enable - boolean value that represent if enables to collect or not.
     */
    AppsFlyer.prototype.enableTCFDataCollection = function (enable) {
        exec(null, null, 'AppsFlyerPlugin', 'enableTCFDataCollection', [enable]);
    };

    module.exports = new AppsFlyer();
})(window);