let startSdkBtn = document.getElementById('startSdk');
let logEventBtn = document.getElementById('logEvent');
let sendPushNotificationDataBtn = document.getElementById('sendPushNotificationData');
let logCrossPromotionAndOpenStoreBtn = document.getElementById('logCrossPromotionAndOpenStore');
let setCurrencyBtn = document.getElementById('setCurrency');
let generateUserInviteBtn = document.getElementById('generateUserInvite');
let logCrossPromotionImpressionBtn = document.getElementById('logCrossPromotionImpression');
let setUserIdBtn = document.getElementById('setUserId');
let setUserEmailsBtn = document.getElementById('setUserEmails');
let setPhoneBtn = document.getElementById('setPhone');
let setHostsBtn = document.getElementById('setHosts');
let setSharingFilterForPartnersBtn = document.getElementById('setSharingFilterForPartners');
let getUserIdBtn = document.getElementById('getUserId');
let unregisterConversionDataListenerBtn = document.getElementById('unregisterConversionDataListener');
let anonymizeUserBtn = document.getElementById('anonymizeUser');
let stopBtn = document.getElementById('stop');
let updateServerUninstallTokenBtn = document.getElementById('updateServerUninstallToken');
let getSdkVBtn = document.getElementById('getSdkV');
let customDomainsBtn = document.getElementById('customDomains');
let enableFBBtn = document.getElementById('enableFB');
let addPushNotificationPathBtn = document.getElementById('addPushNotificationPath');
let setResolveDeepLinkURLsBtn = document.getElementById('setResolveDeepLinkURLs');
let logAdRevenueBtn = document.getElementById('logAdRevenue');
let disableAppSetIdBtn = document.getElementById('disableAppSetId');
let validateAndLogBtn = document.getElementById('validateAndLog');
let setAdditionalDataBtn = document.getElementById('setAdditionalData');
let setPartnerDataBtn = document.getElementById('setPartnerData');
let setDisableAdvertisingIdentifierBtn = document.getElementById('setDisableAdvertisingIdentifier');
let setDisableNetworkDataBtn = document.getElementById('setDisableNetworkData');

// Consent
let setConsentBtn = document.getElementById('testSetConsent');
let isUserSubjectToGDPRSwitch = document.getElementById('isUserSubjectToGDPR');
let hasConsentForDataUsageSwitch = document.getElementById('hasConsentForDataUsage');
let hasConsentForAdsPersonalizationSwitch = document.getElementById('hasConsentForAdsPersonalization');
let hasConsentForAdStorageSwitch = document.getElementById('hasConsentForAdStorage');


if(startSdkBtn){
    startSdkBtn.addEventListener('click', startSdk, false);
}
if(logAdRevenueBtn){
    logAdRevenueBtn.addEventListener('click', logAdRevenue, false);
}
if(setConsentBtn){
    setConsentBtn.addEventListener('click', setConsentData, false);
}
if (generateUserInviteBtn) {
    generateUserInviteBtn.addEventListener('click', generateUserInvite, false);
}
if (logCrossPromotionImpressionBtn) {
    logCrossPromotionImpressionBtn.addEventListener('click', logCrossPromotionImpression, false);
}
if (logEventBtn) {
    logEventBtn.addEventListener('click', logEvent, false);
}
if (sendPushNotificationDataBtn) {
    sendPushNotificationDataBtn.addEventListener('click', sendPushNotificationData, false);
}
if (logCrossPromotionAndOpenStoreBtn) {
    logCrossPromotionAndOpenStoreBtn.addEventListener('click', logCrossPromotionAndOpenStore, false);
}
if (setCurrencyBtn) {
    setCurrencyBtn.addEventListener('click', setCurrency, false);
}
if (setUserIdBtn) {
    setUserIdBtn.addEventListener('click', setUserId, false);
}
if (setUserEmailsBtn) {
    setUserEmailsBtn.addEventListener('click', setEmails, false);
}
if (setPhoneBtn) {
    setPhoneBtn.addEventListener('click', setPhoneNumber, false);
}
if (setHostsBtn) {
    setHostsBtn.addEventListener('click', setHosts, false);
}
if (setSharingFilterForPartnersBtn) {
    setSharingFilterForPartnersBtn.addEventListener('click', setSharingFilterForPartners, false);
}
if (getUserIdBtn) {
    getUserIdBtn.addEventListener('click', getUserId, false);
}
if (unregisterConversionDataListenerBtn) {
    unregisterConversionDataListenerBtn.addEventListener('click', unregisterConversionDataListener, false);
}
if (anonymizeUserBtn) {
    anonymizeUserBtn.addEventListener('click', anonymizeUser, false);
}
if (stopBtn) {
    stopBtn.addEventListener('click', stop, false);
}
if (stopBtn) {
    stopBtn.addEventListener('click', stop, false);
}
if (updateServerUninstallTokenBtn) {
    updateServerUninstallTokenBtn.addEventListener('click', updateServerUninstallToken, false);
}
if (getSdkVBtn) {
    getSdkVBtn.addEventListener('click', getSdkVersion, false);
}
if (customDomainsBtn) {
    customDomainsBtn.addEventListener('click', setCustomDomains, false);
}
if (enableFBBtn) {
    enableFBBtn.addEventListener('click', setFBEnabled, false);
}
if (addPushNotificationPathBtn) {
    addPushNotificationPathBtn.addEventListener('click', addPushNotificationDeepLinkPath, false);
}
if (setResolveDeepLinkURLsBtn) {
    setResolveDeepLinkURLsBtn.addEventListener('click', setResolveDeepLinkURLs, false);
}
if (disableAppSetIdBtn) {
    disableAppSetIdBtn.addEventListener('click', disableAppSetId, false);
}
if (validateAndLogBtn) {
    validateAndLogBtn.addEventListener('click', validateAndLog, false);
}
if (setAdditionalDataBtn) {
    setAdditionalDataBtn.addEventListener('click', setAdditionalData, false);
}
if (setPartnerDataBtn) {
    setPartnerDataBtn.addEventListener('click', setPartnerData, false);
}
if (setDisableAdvertisingIdentifierBtn) {
    setDisableAdvertisingIdentifierBtn.addEventListener('click', setDisableAdvertisingIdentifier, false);
}
if (setDisableNetworkDataBtn) {
    setDisableNetworkDataBtn.addEventListener('click', setDisableNetworkData, false);
}

function callBackFunction(id) {
    alert('received: ' + id);
}

function generateUserInvite(){
    window.plugins.appsFlyer.setAppInviteOneLinkID("em3J");
    let args = {
        "campaign": "testCampaign",
        "referrerName": "testReferrer",
        "referrerImageURL": "testReferrerImageURL",
        "baseDeepLink": "testBaseDeepLink",
        "brandDomain": "noakogonia.afsdktests.com",
        "userParams": {"a":"b"}
    };
    window.plugins.appsFlyer.generateInviteLink(args, callBackFunction, callBackFunction);
}

function logCrossPromotionImpression(){
    window.plugins.appsFlyer.setAppInviteOneLinkID("em3J");
    let args = {
        "campaign": "testCampaign",
        "appId": "testAppId"
    };
    window.plugins.appsFlyer.logCrossPromotionImpression(args, callBackFunction, callBackFunction);
}


function setCurrency(currencyId) {
    currencyId = 'USD';
    window.plugins.appsFlyer.setCurrencyCode(currencyId);
}

function setHosts() {
    let prefix = "foo";
    let name = "bar";
    window.plugins.appsFlyer.setHost(prefix, name);
}

function setSharingFilterForPartners() {
    window.plugins.appsFlyer.setSharingFilterForPartners(["partner1", "partner2"]);
}

function setCustomDomains() {
    let domains = ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"];
    window.plugins.appsFlyer.setOneLinkCustomDomains(domains, callBackFunction, callBackFunction);
}

function addPushNotificationDeepLinkPath() {
    let path = ["go", "to", "this", "path"];
    window.plugins.appsFlyer.addPushNotificationDeepLinkPath(path);
}

function setResolveDeepLinkURLs() {
    let path = ["click.example.com", "link.partner.com"];
    window.plugins.appsFlyer.setResolveDeepLinkURLs(path);
}

function setEmails() {
    let emails = ["foo@bar.com", "support@appsflyer.com"];
    window.plugins.appsFlyer.setUserEmails(emails, print);
}

function setPhoneNumber() {
    let phone = "0522565426";
    window.plugins.appsFlyer.setPhoneNumber(phone, print);
}

function setFBEnabled() {
    window.plugins.appsFlyer.enableFacebookDeferredApplinks(false);
}

function setUserId(userAppId) {
    userAppId = '887788778';
    window.plugins.appsFlyer.setAppUserId(userAppId);
}

function getUserId() {
    window.plugins.appsFlyer.getAppsFlyerUID(callBackFunction);
}

function unregisterConversionDataListener() {
    window.plugins.appsFlyer.unregisterConversionDataListener();
    alert('Conversion data listener unregistered');
}

function anonymizeUser() {
    window.plugins.appsFlyer.anonymizeUser(true);
}

function stop() {
    window.plugins.appsFlyer.Stop();
}

function updateServerUninstallToken() {
    window.plugins.appsFlyer.updateServerUninstallToken("test_uninstall_token");
}

function getSdkVersion() {
    window.plugins.appsFlyer.getSdkVersion(callBackFunction);
}


function logEvent(eventName, eventValues) {
    eventName = 'af_content_view';
    eventValues = {
        'af_content_id': 'id123',
        'af_currency': 'USD',
        'af_content_type': 'shoes',
        'af_revenue': '10',
    };
    window.plugins.appsFlyer.logEvent(eventName, eventValues, callBackFunction, callBackFunction);
}

function sendPushNotificationData() {
    const data = {
        campaign: 'test_campaign',
        pid: '123',
        isRetargeting: false,
        additionalParameters: {
            "key1": "value1",
        }
    }
    window.plugins.appsFlyer.sendPushNotificationData(data);
}

function logCrossPromotionAndOpenStore() {
    window.plugins.appsFlyer.logCrossPromotionAndOpenStore('1528937655', 'test', {
        custom_param: 'custom_value',
    });
}

function setConsentData() {
    console.log("Button clicked: Set consent data");

    let isUserSubjectToGDPR = isUserSubjectToGDPRSwitch.checked;
    let hasConsentForDataUsage = hasConsentForDataUsageSwitch.checked;
    let hasConsentForAdsPersonalization = hasConsentForAdsPersonalizationSwitch.checked;
    let hasConsentForAdStorage = hasConsentForAdStorageSwitch.checked;

    let consentData = new AppsFlyerConsent(
        isUserSubjectToGDPR,
        hasConsentForDataUsage,
        hasConsentForAdsPersonalization,
        hasConsentForAdStorage
    );

    window.plugins.appsFlyer.setConsentData(consentData);
}

function logAdRevenue() {
    console.log("Button clicked: logAdRevenue");
    let mediationNetwork = MediationNetwork.TOPON;
    let adRevenueData = {
        'monetizationNetwork': 'testMonetizationNetwork',
        'mediationNetwork': mediationNetwork,
        'currencyIso4217Code': 'USD',
        'revenue': 15.0
    };
    let additionalParams = {
        'additionalKey1':'additionalValue1',
        'additionalKey2':'additionalValue2'
    }
    window.plugins.appsFlyer.logAdRevenue(adRevenueData, additionalParams);
}

function disableAppSetId() {
    window.plugins.appsFlyer.disableAppSetId();
}

function validateAndLog() {
    const afDetails = new AFPurchaseDetails("subscription", "abcd", "product1");

    const additionalParams = {
        param1: "value1",
        param2: "value2"
    };

    window.plugins.appsFlyer.validateAndLogInAppPurchase(
        afDetails,
        additionalParams,
        callBackFunction,
        callBackFunction
    );
}

function setAdditionalData() {
    const data = {
        param1: "value1",
        param2: "value2"
    };

    window.plugins.appsFlyer.setAdditionalData(data);
}

function setPartnerData() {
    const data = {
        param1: "value1",
        param2: "value2"
    };

    window.plugins.appsFlyer.setPartnerData("partner_id", data);
}

function setDisableAdvertisingIdentifier() {
    window.plugins.appsFlyer.setDisableAdvertisingIdentifier(true);
}

function setDisableNetworkData() {
    window.plugins.appsFlyer.setDisableNetworkData(true);
}

function startSdk() {
    console.log("Button clicked: Started the SDK");
    window.plugins.appsFlyer.startSdk();
}
