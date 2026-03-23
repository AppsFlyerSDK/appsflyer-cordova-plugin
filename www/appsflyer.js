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

    function isAndroid() {
        return typeof window.cordova !== 'undefined' && window.cordova.platformId === 'android';
    }

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
     * @class AFPurchaseDetails
     * @constructor
     * @param {string} purchaseType - Type of the purchase can be: subscription or one_time_purchase.
     * @param {string} purchaseToken - Token of the purchase.
     * @param {string} productId - ID of the purchased product.
     */
    function AFPurchaseDetails(purchaseType, purchaseToken, productId) {
        this.purchaseType = purchaseType;
        this.purchaseToken = purchaseToken;
        this.productId = productId;
    }

    // Expose AFPurchaseDetails to the global scope
    global.AFPurchaseDetails = AFPurchaseDetails;

    /**
     * initialize the SDK.
     * args: SDK configuration (devKey required)
     */
    AppsFlyer.prototype.initSdk = function (args) {
        argscheck.checkArgs('O', 'AppsFlyer.initSdk', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'init', params: { devKey: args.devKey || '' } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'initSdk', [args]);
        }
    };

    /**
     * Starts the SDK. Optionally, pass success and error callbacks to be notified when start completes.
     */
    AppsFlyer.prototype.startSdk = function (successCB, errorCB) {
        if (isAndroid()) {
            const hasCallback = (typeof successCB === 'function') || (typeof errorCB === 'function');
            const params = { awaitResponse: hasCallback };
            if (hasCallback) {
                exec(successCB || function () {}, errorCB || function () {}, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'start', params: params }]);
            } else {
                exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'start', params: params }]);
            }
        } else {
            exec(successCB || null, errorCB || null, 'AppsFlyerPlugin', 'startSdk', []);
        }
    };

    /**
     * Enable or disable debug logs. Call after initSdk if you need to change debug mode at runtime.
     */
    AppsFlyer.prototype.setDebugLog = function (isEnabled) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'isDebug', params: { isDebug: !!isEnabled } }]);
        } else {
            exec(null, null, 'AppsFlyerSwiftPlugin', 'executeRpc', [{ method: 'isDebug', params: { isDebug: !!isEnabled } }]);
        }
    };

    /**
     * Register Unified deep link listener
     * @param onDeepLinkListener ddl callback triggered when deep linked has been clicked and onDeepLinkListener = true;
     */
    AppsFlyer.prototype.registerDeepLink = function (onDeepLinkListener) {
        callbackMap.ddlSuc = onDeepLinkListener;
        if (isAndroid()) {
            exec(onDeepLinkListener, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'subscribeForDeepLink', params: {} }]);
        } else {
            exec(onDeepLinkListener, null, 'AppsFlyerPlugin', 'registerDeepLink', []);
        }
    };

    /**
     * Register install conversion data listener. Call after initSdk to receive onInstallConversionDataLoaded / onInstallConversionDataFailure.
     * @param successCB called with a conversion data object on success
     * @param errorCB called with an error message on failure
     */
    AppsFlyer.prototype.registerConversionDataListener = function (successCB, errorCB) {
        if (isAndroid()) {
            exec(successCB || function () {}, errorCB || function () {}, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'registerConversionListener', params: {} }]);
        } else {
            exec(successCB || function () {}, errorCB || function () {}, 'AppsFlyerSwiftPlugin', 'executeRpc', [{ method: 'registerConversionListener', params: {} }]);
        }
    };

    /**
     * Unregister install conversion data listener. No further conversion data callbacks will be delivered.
     */
    AppsFlyer.prototype.unregisterConversionDataListener = function () {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'unregisterConversionListener', params: {} }]);
        } else {
            exec(null, null, 'AppsFlyerSwiftPlugin', 'executeRpc', [{ method: 'unregisterConversionListener', params: {} }]);
        }
    };

    /**
     * Enable or disable Android ID collection. Android only; no-op on iOS.
     */
    AppsFlyer.prototype.setCollectAndroidID = function (isEnabled) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setCollectAndroidID', params: { isCollect: !!isEnabled } }]);
        }
    };

    /**
     * currencyId: ISO 4217 Currency Codes
     */
    AppsFlyer.prototype.setCurrencyCode = function (currencyId) {
        argscheck.checkArgs('S', 'AppsFlyer.setCurrencyCode', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setCurrencyCode', params: { currencyCode: currencyId } }]);
        } else {
            exec(null, null, 'AppsFlyerSwiftPlugin', 'executeRpc', [{ method: 'setCurrencyCode', params: { currencyCode: currencyId } }]);
        }
    };

    /**
     * Set the minimum time between sessions (in seconds).
     */
    AppsFlyer.prototype.setMinTimeBetweenSessions = function (seconds) {
        argscheck.checkArgs('N', 'AppsFlyer.setMinTimeBetweenSessions', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setMinTimeBetweenSessions', params: { seconds: seconds != null ? Math.max(0, parseInt(seconds, 10)) : 0 } }]);
    };

    /**
     * Set the out-of-store source name.
     */
    AppsFlyer.prototype.setOutOfStore = function (sourceName) {
        argscheck.checkArgs('S', 'AppsFlyer.setOutOfStore', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setOutOfStore', params: { sourceName: sourceName || '' } }]);
    };

    /**
     * Set user emails with encryption type (e.g. SHA256, MD5).
     */
    AppsFlyer.prototype.setUserEmailsWithCryptType = function (cryptType, emails) {
        argscheck.checkArgs('SA', 'AppsFlyer.setUserEmailsWithCryptType', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setUserEmailsWithCryptType', params: { cryptType: cryptType || '', emails: emails || [] } }]);
    };

    /**
     * Set preinstall attribution (mediaSource, campaign, siteId).
     */
    AppsFlyer.prototype.setPreinstallAttribution = function (mediaSource, campaign, siteId) {
        argscheck.checkArgs('SSS', 'AppsFlyer.setPreinstallAttribution', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setPreinstallAttribution', params: { mediaSource: mediaSource || '', campaign: campaign || '', siteId: siteId || '' } }]);
    };

    /**
     * Set SDK log level (e.g. NONE, ERROR, WARNING, INFO, DEBUG, VERBOSE).
     */
    AppsFlyer.prototype.setLogLevel = function (logLevel) {
        argscheck.checkArgs('S', 'AppsFlyer.setLogLevel', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setLogLevel', params: { logLevel: logLevel || '' } }]);
    };

    /**
     * Set whether the current launch is an app update.
     */
    AppsFlyer.prototype.setIsUpdate = function (isUpdate) {
        argscheck.checkArgs('*', 'AppsFlyer.setIsUpdate', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setIsUpdate', params: { isUpdate: !!isUpdate } }]);
    };

    /**
     * Set the app ID (e.g. iOS bundle ID or Android package name for cross-promotion).
     */
    AppsFlyer.prototype.setAppId = function (appId) {
        argscheck.checkArgs('S', 'AppsFlyer.setAppId', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setAppId', params: { appId: appId || '' } }]);
    };

    /**
     * Set a custom install ID.
     */
    AppsFlyer.prototype.setInstallId = function (installId) {
        argscheck.checkArgs('S', 'AppsFlyer.setInstallId', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setInstallId', params: { installId: installId || '' } }]);
    };

    /**
     * Public API - logAdRevenue function
     */
    AppsFlyer.prototype.logAdRevenue = function (afAdRevenueData, additionalParameters) {
        argscheck.checkArgs('OO', 'AppsFlyer.logAdRevenue', arguments);
        if (isAndroid()) {
            const params = {
                monetizationNetwork: afAdRevenueData.monetizationNetwork || '',
                mediationNetwork: afAdRevenueData.mediationNetwork || '',
                currencyIso4217Code: afAdRevenueData.currencyIso4217Code || '',
                revenue: afAdRevenueData.revenue != null ? afAdRevenueData.revenue : 0,
                additionalParameters: additionalParameters || null
            };
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logAdRevenue', params: params }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'logAdRevenue', [afAdRevenueData, additionalParameters]);
        }
    };

    /**
     * Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs.
     */
    AppsFlyer.prototype.setAppUserId = function (customerUserId) {
        argscheck.checkArgs('S', 'AppsFlyer.setAppUserId', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setCustomerUserId', params: { customerId: customerUserId } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setAppUserId', [customerUserId]);
        }
    };

    /**
     * Get Appsflyer ID
     */
    AppsFlyer.prototype.getAppsFlyerUID = function (successCB) {
        argscheck.checkArgs('F', 'AppsFlyer.getAppsFlyerUID', arguments);
        if (isAndroid()) {
            exec(
                function (result) { successCB(result); },
                null,
                'AppsFlyerPlugin',
                'executeRpc',
                [{ method: 'getAppsFlyerUID', params: {} }]
            );
        } else {
            exec(
                function (result) { successCB(result); },
                null,
                'AppsFlyerPlugin',
                'getAppsFlyerUID',
                []
            );
        }
    };

    /**
     * Get the host name.
     */
    AppsFlyer.prototype.getHostName = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.getHostName', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'getHostName', params: {} }]);
    };

    /**
     * Get the host prefix.
     */
    AppsFlyer.prototype.getHostPrefix = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.getHostPrefix', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'getHostPrefix', params: {} }]);
    };

    /**
     * Get the out-of-store source name.
     */
    AppsFlyer.prototype.getOutOfStore = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.getOutOfStore', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'getOutOfStore', params: {} }]);
    };

    /**
     * Get the attribution ID.
     */
    AppsFlyer.prototype.getAttributionId = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.getAttributionId', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'getAttributionId', params: {} }]);
    };

    /**
     * Check if the SDK is stopped.
     */
    AppsFlyer.prototype.isStopped = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.isStopped', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'isStopped', params: {} }]);
    };

    /**
     * Check if the app was pre-installed.
     */
    AppsFlyer.prototype.isPreInstalledApp = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.isPreInstalledApp', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'isPreInstalledApp', params: {} }]);
    };

    /**
     * Unsubscribe from deep link callbacks.
     */
    AppsFlyer.prototype.unsubscribeForDeepLink = function () {
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'unsubscribeForDeepLink', params: {} }]);
    };

    /**
     * Perform deep linking with the given URL.
     */
    AppsFlyer.prototype.performDeepLinking = function (url, shouldTriggerSession) {
        argscheck.checkArgs('S*', 'AppsFlyer.performDeepLinking', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'performDeepLinking', params: { url: url || '', shouldTriggerSession: !!shouldTriggerSession } }]);
    };

    /**
     * Set deep link timeout in milliseconds.
     */
    AppsFlyer.prototype.setDeepLinkTimeout = function (timeout) {
        argscheck.checkArgs('N', 'AppsFlyer.setDeepLinkTimeout', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setDeepLinkTimeout', params: { timeout: timeout != null ? Number(timeout) : 0 } }]);
    };

    /**
     * Append parameters to deep linking URLs that contain the given substring.
     */
    AppsFlyer.prototype.appendParametersToDeepLinkingURL = function (contains, parameters) {
        argscheck.checkArgs('SO', 'AppsFlyer.appendParametersToDeepLinkingURL', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'appendParametersToDeepLinkingURL', params: { contains: contains || '', parameters: parameters || {} } }]);
    };

    /**
     * Log an invite event.
     */
    AppsFlyer.prototype.logInvite = function (channel, eventParameters) {
        argscheck.checkArgs('SO', 'AppsFlyer.logInvite', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logInvite', params: { channel: channel || '', eventParameters: eventParameters || null } }]);
    };

    /**
     * Log location (latitude, longitude).
     */
    AppsFlyer.prototype.logLocation = function (latitude, longitude) {
        argscheck.checkArgs('NN', 'AppsFlyer.logLocation', arguments);
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logLocation', params: { latitude: Number(latitude), longitude: Number(longitude) } }]);
    };

    /**
     * Manually log a session.
     */
    AppsFlyer.prototype.logSession = function () {
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logSession', params: {} }]);
    };

    /**
     * Notify the SDK that the app has entered background (e.g. for platforms that manage lifecycle themselves).
     */
    AppsFlyer.prototype.onPause = function () {
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'onPause', params: {} }]);
    };

    /**
     * End User Opt-Out from AppsFlyer analytics (Anonymize user data).
     */
    AppsFlyer.prototype.anonymizeUser = function (isDisabled) {
        argscheck.checkArgs('*', 'AppsFlyer.anonymizeUser', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'anonymizeUser', params: { shouldAnonymize: isDisabled } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'anonymizeUser', [isDisabled]);
        }
    };

    /**
     * Shut down SDK
     */
    AppsFlyer.prototype.Stop = function (isStop) {
        argscheck.checkArgs('*', 'AppsFlyer.Stop', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'stop', params: { shouldStop: isStop } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'Stop', [isStop]);
        }
    };

    /**
     * Registers a callback to be notified when the SDK is ready to trigger a new session.
     * Call start() within the callback to ensure proper session initialization with all required data (e.g. deeplink parameters).
     * @param {function} successCB - Called when the session is ready; receives event object with type "onSessionReady".
     */
    AppsFlyer.prototype.registerSessionReadyListener = function (successCB) {
        argscheck.checkArgs('F', 'AppsFlyer.registerSessionReadyListener', arguments);
        exec(
            function (result) { if (successCB) successCB(result); },
            null,
            'AppsFlyerPlugin',
            'executeRpc',
            [{ method: 'registerSessionReadyListener', params: {} }]
        );
    };

    /**
     * Unregisters the session ready listener.
     */
    AppsFlyer.prototype.unregisterSessionReadyListener = function () {
        exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'unregisterSessionReadyListener', params: {} }]);
    };

    /**
     * Returns whether the SDK session is ready (via successCB with boolean result).
     */
    AppsFlyer.prototype.isSessionReady = function (successCB, errorCB) {
        argscheck.checkArgs('F', 'AppsFlyer.isSessionReady', arguments);
        exec(function (result) { if (successCB) successCB(result); }, errorCB || null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'isSessionReady', params: {} }]);
    };

    /**
     * Log rich in-app events
     * eventName: custom event name, is presented in your dashboard.
     * eventValue: event details
     * successCB: Success callback - called after event sent successful (receives JSON string of RPC `result`).
     * errorCB: Error callback - called when error occurs.
     */
    AppsFlyer.prototype.logEvent = function (eventName, eventValue, successCB, errorCB) {
        argscheck.checkArgs('SO', 'AppsFlyer.logEvent', arguments);
        const hasCallback = (typeof successCB === 'function') || (typeof errorCB === 'function');
        const params = {
            eventName: eventName || '',
            eventValues: eventValue || null,
            awaitResponse: hasCallback
        };
        const rpcPayload = { method: 'logEvent', params: params };
        if (isAndroid()) {
            if (hasCallback) {
                exec(successCB || function () {}, errorCB || function () {}, 'AppsFlyerPlugin', 'executeRpc', [rpcPayload]);
            } else {
                exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [rpcPayload]);
            }
        } else {
            if (hasCallback) {
                exec(successCB || function () {}, errorCB || function () {}, 'AppsFlyerSwiftPlugin', 'executeRpc', [rpcPayload]);
            } else {
                exec(null, null, 'AppsFlyerSwiftPlugin', 'executeRpc', [rpcPayload]);
            }
        }
    };

    /**
     * (Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Uninstall log.
     */
    AppsFlyer.prototype.updateServerUninstallToken = function (token) {
        argscheck.checkArgs('S', 'AppsFlyer.updateServerUninstallToken', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'updateServerUninstallToken', params: { token: token } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'updateServerUninstallToken', [token]);
        }
    };

    /**
     * Set AppsFlyer’s OneLink ID
     * args: oneLinkID.
     */
    AppsFlyer.prototype.setAppInviteOneLinkID = function (args) {
        argscheck.checkArgs('S', 'AppsFlyer.setAppInviteOneLinkID', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setAppInviteOneLink', params: { oneLinkId: args } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setAppInviteOneLinkID', [args]);
        }
    };

    /**
     * Allowing your existing users to invite their friends and contacts as new users to your app
     * args: Parameters for Invite link (channel, campaign, referrerName, referrerImageURL/referrerImageUrl, customerID/customerId, baseDeepLink, brandDomain, userParams).
     * successCB: Success callback (generated link).
     * errorCB: Error callback.
     */
    AppsFlyer.prototype.generateInviteLink = function (args, successCB, errorCB) {
        argscheck.checkArgs('O', 'AppsFlyer.generateInviteLink', arguments);
        if (isAndroid()) {
            const params = {
                channel: args.channel || null,
                campaign: args.campaign || null,
                referrerName: args.referrerName || null,
                referrerImageUrl: args.referrerImageUrl || args.referrerImageURL || null,
                customerId: args.customerId || args.customerID || null,
                baseDeepLink: args.baseDeepLink || null,
                brandDomain: args.brandDomain || null,
                userParams: args.userParams || null,
                awaitResponse: args.awaitResponse !== false
            };
            exec(successCB, errorCB, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'generateInviteLink', params: params }]);
        } else {
            exec(successCB, errorCB, 'AppsFlyerPlugin', 'generateInviteLink', [args]);
        }
    };

    /**
     * log cross promotion impression. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
     * appId: Promoted Application ID
     * campaign: Promoted Campaign
     * userParams: Optional map of additional parameters.
     */
    AppsFlyer.prototype.logCrossPromotionImpression = function (appId, campaign, userParams) {
        argscheck.checkArgs('*', 'AppsFlyer.logCrossPromotionImpression', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logCrossPromoteImpression', params: { appId: appId || '', campaign: campaign || '', userParams: userParams || null } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'logCrossPromotionImpression', [appId, campaign]);
        }
    };

    /**
     * Launch the app store's app page (via Browser).
     * appId: Promoted Application ID.
     * campaign: Promoted Campaign.
     * params: Additional Parameters to log (optional object).
     */
    AppsFlyer.prototype.logCrossPromotionAndOpenStore = function (appId, campaign, params) {
        argscheck.checkArgs('*', 'AppsFlyer.logCrossPromotionAndOpenStore', arguments);
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'logAndOpenStore', params: { promotedAppId: appId || '', campaign: campaign || '', userParams: params || null } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'logCrossPromotionAndOpenStore', [appId, campaign, params]);
        }
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
        if (isAndroid()) {
            exec(function (result) { if (successCB) successCB(result); }, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'getSdkVersion', params: {} }]);
        } else {
            exec(successCB, null, 'AppsFlyerPlugin', 'getSdkVersion', []);
        }
    };

    /**
     * Used by advertisers to exclude specified networks/integrated partners from getting data
     * networks Comma separated array of partners that need to be excluded
     */
    AppsFlyer.prototype.setSharingFilterForPartners = function (networks) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setSharingFilterForPartners', params: { partners: networks || [] } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setSharingFilterForPartners', [networks]);
        }
    };

    /**
     * Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
     * Learn more:
     * Android: https://dev.appsflyer.com/hc/docs/validate-and-log-purchase-android
     * iOS: https://dev.appsflyer.com/hc/docs/validate-and-log-purchase-ios
     * @param {AFPurchaseDetails} afPurchaseDetails object containing purchase details (purchaseType, purchaseToken, productId)
     * @param {object} additionalParameters optional map of additional parameters
     * @param successC Success callback
     * @param errorC Error callback
     */
    AppsFlyer.prototype.validateAndLogInAppPurchase = function (afPurchaseDetails, additionalParameters, successC, errorC) {
        if (isAndroid()) {
            const hasCallback = (typeof successC === 'function') || (typeof errorC === 'function');
            const params = {
                purchaseType: (afPurchaseDetails && afPurchaseDetails.purchaseType) || '',
                purchaseToken: (afPurchaseDetails && afPurchaseDetails.purchaseToken) || '',
                productId: (afPurchaseDetails && afPurchaseDetails.productId) || '',
                additionalParameters: additionalParameters || null,
                awaitResponse: hasCallback
            };
            if (hasCallback) {
                exec(successC || function () {}, errorC || function () {}, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'validateAndLogInAppPurchase', params: params }]);
            } else {
                exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'validateAndLogInAppPurchase', params: params }]);
            }
        } else {
            exec(successC, errorC, 'AppsFlyerPlugin', 'validateAndLogInAppPurchaseV2', [afPurchaseDetails, additionalParameters]);
        }
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
        if (isAndroid()) {
            exec(successC, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setDisableAdvertisingIdentifiers', params: { isDisable: !!disableAdvertisingIdentifier } }]);
        } else {
            exec(successC, null, 'AppsFlyerPlugin', 'setDisableAdvertisingIdentifier', [disableAdvertisingIdentifier]);
        }
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
        if (isAndroid()) {
            exec(successC, errorC, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setOneLinkCustomDomain', params: { domains: domains || [] } }]);
        } else {
            exec(successC, errorC, 'AppsFlyerPlugin', 'setOneLinkCustomDomains', [domains]);
        }
    };

    /**
     * use this api If you need deep linking data from Facebook, deferred deep linking, Dynamic Product Ads, or reasons that
     * unrelated to attribution such as authentication, ad monetization, social sharing, user invites, etc.
     * More information here: https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration
     * @param isEnabled - boolean value
     */
    AppsFlyer.prototype.enableFacebookDeferredApplinks = function (isEnabled) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'enableFacebookDeferredApplinks', params: { isEnabled: !!isEnabled } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'enableFacebookDeferredApplinks', [isEnabled]);
        }
    };

    /**
     * Facebook Advanced Matching
     * @param phoneNumber phone number
     * @param successC success callback
     */
    AppsFlyer.prototype.setPhoneNumber = function (phoneNumber, successC) {
        if (isAndroid()) {
            exec(successC, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setPhoneNumber', params: { phoneNumber: phoneNumber || '' } }]);
        } else {
            exec(successC, null, 'AppsFlyerPlugin', 'setPhoneNumber', [phoneNumber]);
        }
    };

    /**
     * Facebook Advanced Matching
     * @param userEmails Strings array of emails
     * @param successC success callback
     */
    AppsFlyer.prototype.setUserEmails = function (userEmails, successC) {
        if (isAndroid()) {
            exec(successC, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setUserEmails', params: { emails: userEmails || [] } }]);
        } else {
            exec(successC, null, 'AppsFlyerPlugin', 'setUserEmails', [userEmails]);
        }
    };

    /**
     * Set a custom host
     * @param hostPrefix
     * @param hostName
     */
    AppsFlyer.prototype.setHost = function (hostPrefix, hostName) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setHost', params: { hostPrefixName: hostPrefix || null, hostName: hostName || '' } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setHost', [hostPrefix, hostName]);
        }
    };

    /**
     * The addPushNotificationDeepLinkPath method provides app owners with a flexible interface for configuring how deep links are extracted from push notification payloads.
     * for more information: https://support.appsflyer.com/hc/en-us/articles/207032126-Android-SDK-integration-for-developers#core-apis-65-configure-push-notification-deep-link-resolution
     * @param path an array of string that represents the path
     */
    AppsFlyer.prototype.addPushNotificationDeepLinkPath = function (path) {
        if (isAndroid()) {
            const deepLinkPath = Array.isArray(path) ? path : (path != null ? [path] : []);
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'addPushNotificationDeepLinkPath', params: { deepLinkPath: deepLinkPath } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'addPushNotificationDeepLinkPath', [path]);
        }
    };

    /**
     * Use this API to get the OneLink from click domains that launch the app. Make sure to call this API before SDK initialization.
     * @param urls
     */
    AppsFlyer.prototype.setResolveDeepLinkURLs = function (urls) {
        if (isAndroid()) {
            const urlList = Array.isArray(urls) ? urls : (urls != null ? [urls] : []);
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setResolveDeepLinkURLs', params: { urls: urlList } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setResolveDeepLinkURLs', [urls]);
        }
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
    AppsFlyer.prototype.setAdditionalData = function (additionalData) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setAdditionalData', params: { customData: additionalData || {} } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setAdditionalData', [additionalData]);
        }
    };

    /**
     * The setPartnerData API allows sending custom data for partner integration purposes.
     *
     * Typically it is used to integrate on the SDK level with several external partner platforms
     * @param partnerId - ID of the partner (usually suffixed with "_int")
     * @param data - Customer data, depends on the integration configuration with the specific partner
     */
    AppsFlyer.prototype.setPartnerData = function (partnerId, data) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setPartnerData', params: { partnerId: partnerId || '', data: data || {} } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setPartnerData', [partnerId, data]);
        }
    };

    /**
     * Measure and get data from push-notification campaigns.
     * Uses sendPushNotificationData(AFPushData). pushData must contain campaign, pid, and optionally isRetargeting, additionalParameters.
     * @param pushData - Object with campaign (string), pid (string), isRetargeting (boolean, optional), additionalParameters (object, optional)
     */
    AppsFlyer.prototype.sendPushNotificationData = function (pushData) {
        if (isAndroid()) {
            const params = {
                campaign: pushData && (pushData.campaign != null) ? String(pushData.campaign) : '',
                pid: pushData && (pushData.pid != null) ? String(pushData.pid) : '',
                isRetargeting: !!(pushData && pushData.isRetargeting),
                additionalParameters: (pushData && pushData.additionalParameters) || null
            };
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'sendPushNotificationData', params: params }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'sendPushNotificationData', [pushData]);
        }
    };

    /**
     * Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device.
     * @param disable - Defaults to false
     */
    AppsFlyer.prototype.setDisableNetworkData = function (disable) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setDisableNetworkData', params: { isDisable: !!disable } }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setDisableNetworkData', [disable]);
        }
    };

    /**
     * Use to manually collecting the consent data from the user.
     * @param appsFlyerConsent - object of AppsFlyerConsent that holds three values when GDPR is applies to the user, and one value when It's not.
     * when GDPR applies to the user and your app does not use a CMP compatible with TCF v2.2, use this API to provide the consent data directly to the SDK.<br>
     */
    AppsFlyer.prototype.setConsentData = function (appsFlyerConsent) {
        if (isAndroid()) {
            const params = {
                isUserSubjectToGDPR: appsFlyerConsent.isUserSubjectToGDPR === true,
                hasConsentForDataUsage: appsFlyerConsent.hasConsentForDataUsage,
                hasConsentForAdsPersonalization: appsFlyerConsent.hasConsentForAdsPersonalization,
                hasConsentForAdStorage: appsFlyerConsent.hasConsentForAdStorage
            };
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'setConsentData', params: params }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'setConsentData', [appsFlyerConsent]);
        }
    };

    /**
     * set collect tcf data or not.
     *
     * @param enable - boolean value that represent if enables to collect or not.
     */
    AppsFlyer.prototype.enableTCFDataCollection = function (enable) {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'enableTCFDataCollection', params: { shouldCollect: !!enable } }]);
        } else {
            exec(null, null, 'AppsFlyerSwiftPlugin', 'enableTCFDataCollection', [enable]);
        }
    };

    /**
     * If this method is called - AppsFlyer SDK will no longer collect App Set Id,
     * even if such dependency is added to the app.
     */
    AppsFlyer.prototype.disableAppSetId = function () {
        if (isAndroid()) {
            exec(null, null, 'AppsFlyerPlugin', 'executeRpc', [{ method: 'disableAppSetId', params: {} }]);
        } else {
            exec(null, null, 'AppsFlyerPlugin', 'disableAppSetId', []);
        }
    };

    module.exports = new AppsFlyer();
})(window);