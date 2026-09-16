const buttonBindings = [
    ['logAdRevenue', logAdRevenue],
    ['testSetConsent', setConsentData],
    ['generateUserInvite', generateUserInvite],
    ['logEvent', logEvent],
    ['logCrossPromotionAndOpenStore', logCrossPromotionAndOpenStore],
    ['setCurrency', setCurrency],
    ['setUserId', setUserId],
    ['setUserEmails', setEmails],
    ['setPhone', setPhoneNumber],
    ['setHosts', setHosts],
    ['getUserId', getUserId],
    ['getSdkV', getSdkVersion],
    ['customDomains', setCustomDomains],
    ['enableFB', setFBEnabled],
    ['addPushNotificationPath', addPushNotificationDeepLinkPath],
    ['disableAppSetId', disableAppSetId],
    ['validateAndLogV2', validateAndLogV2]
];

for (const [id, handler] of buttonBindings) {
    document.getElementById(id)?.addEventListener('click', handler, false);
}

const isUserSubjectToGDPRSwitch = document.getElementById('isUserSubjectToGDPR');
const hasConsentForDataUsageSwitch = document.getElementById('hasConsentForDataUsage');
const hasConsentForAdsPersonalizationSwitch = document.getElementById('hasConsentForAdsPersonalization');
const hasConsentForAdStorageSwitch = document.getElementById('hasConsentForAdStorage');

function fmt(value) {
    // RPC results/errors are objects -- string-concatenating one directly renders "[object Object]".
    return typeof value === 'object' && value !== null ? JSON.stringify(value) : value;
}

function callBackFunction(id) {
    alert('received: ' + fmt(id));
}

// Every API call below alerts on both success and failure -- any answer must be visible,
// not just logged. `label` is the call name shown in the alert.
function notify(promise, label) {
    promise.then(function (res) {
        alert(label + ' -> ' + fmt(res === undefined ? 'OK' : res));
    }).catch(function (err) {
        alert(label + ' failed -> ' + fmt(err));
    });
}

// setUserPhone() now requires a countryCode that the old setPhoneNumber() call never took (see
// RENAME_AUDIT.md) -- this repo has no source for a real one, placeholder pending a human decision.
const TODO_COUNTRY_CODE = "TODO_COUNTRY_CODE";

function generateUserInvite(){
    notify(window.plugins.appsFlyer.setAppInviteOneLink({ oneLinkId: "em3J" }), 'setAppInviteOneLink');
    let args = {
        "campaign": "testCampaign",
        "referrerName": "testReferrer",
        "referrerImageURL": "testReferrerImageURL",
        "baseDeepLink": "testBaseDeepLink",
        "brandDomain": "noakogonia.afsdktests.com",
        "userParams": {"a":"b"}
    };
    notify(window.plugins.appsFlyer.generateInviteLink({ parameters: args }), 'generateInviteLink');
}

function setCurrency() {
    notify(window.plugins.appsFlyer.setCurrencyCode({ currencyCode: 'USD' }), 'setCurrencyCode');
}

function setHosts() {
    notify(window.plugins.appsFlyer.setHost({ hostPrefixName: 'foo', hostName: 'bar' }), 'setHost');
}

function setCustomDomains() {
    let domains = ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"];
    notify(window.plugins.appsFlyer.setOneLinkCustomDomain({ domains: domains }), 'setOneLinkCustomDomain');
}

function addPushNotificationDeepLinkPath() {
    let path = ["go", "to", "this", "path"];
    notify(window.plugins.appsFlyer.addPushNotificationDeepLinkPath({ deepLinkPath: path }), 'addPushNotificationDeepLinkPath');
}

function setEmails() {
    let emails = ["foo@bar.com", "support@appsflyer.com"];
    // setUserEmails (array) -> setUserEmail (single) -- cardinality change, no batch equivalent
    // (see RENAME_AUDIT.md) -- call once per email to preserve sending all of them.
    emails.forEach(function (email) {
        notify(window.plugins.appsFlyer.setUserEmail({ email: email }), 'setUserEmail(' + email + ')');
    });
}

function setPhoneNumber() {
    notify(window.plugins.appsFlyer.setUserPhone({ countryCode: TODO_COUNTRY_CODE, phoneNumber: "0522565426" }), 'setUserPhone');
}

function setFBEnabled() {
    notify(window.plugins.appsFlyer.enableFacebookDeferredApplinks({ isEnabled: false }), 'enableFacebookDeferredApplinks');
}

function setUserId() {
    notify(window.plugins.appsFlyer.setCustomerUserId({ customerId: '887788778' }), 'setCustomerUserId');
}

function getUserId() {
    notify(window.plugins.appsFlyer.getAppsFlyerUID(), 'getAppsFlyerUID');
}

function getSdkVersion() {
    notify(window.plugins.appsFlyer.getSdkVersion(), 'getSdkVersion');
}

function logEvent() {
    let eventValues = {
        'af_content_id': 'id123',
        'af_currency': 'USD',
        'af_content_type': 'shoes',
        'af_revenue': '10',
    };
    notify(window.plugins.appsFlyer.logEvent({ eventName: 'af_content_view', eventValues: eventValues }), 'logEvent');
}

function logCrossPromotionAndOpenStore() {
    notify(window.plugins.appsFlyer.logAndOpenStore({
        promotedAppId: '1528937655',
        campaign: 'test',
        userParams: {
            custom_param: 'custom_value',
        },
    }), 'logAndOpenStore');
}

function setConsentData() {
    let consentData = {
        isUserSubjectToGDPR: isUserSubjectToGDPRSwitch.checked,
        hasConsentForDataUsage: hasConsentForDataUsageSwitch.checked,
        hasConsentForAdsPersonalization: hasConsentForAdsPersonalizationSwitch.checked,
        hasConsentForAdStorage: hasConsentForAdStorageSwitch.checked
    };
    notify(window.plugins.appsFlyer.setConsentData(consentData), 'setConsentData');
}

function logAdRevenue() {
    let mediationNetwork = window.plugins.appsFlyer.MediationNetwork.TOPON;
    let additionalParams = {
        'additionalKey1':'additionalValue1',
        'additionalKey2':'additionalValue2'
    }
    notify(window.plugins.appsFlyer.logAdRevenue({
        monetizationNetwork: 'testMonetizationNetwork',
        mediationNetwork: mediationNetwork,
        currencyIso4217Code: 'USD',
        revenue: 15.0,
        additionalParameters: additionalParams
    }), 'logAdRevenue');
}

function disableAppSetId() {
    notify(window.plugins.appsFlyer.disableAppSetId(), 'disableAppSetId');
}

function validateAndLogV2() {
    const afDetails = {
        purchaseType: window.plugins.appsFlyer.AFPurchaseType.subscription,
        purchaseToken: "abcd",
        productId: "product1"
    };
    const additionalParams = {
        param1: "value1",
        param2: "value2"
    };
    notify(window.plugins.appsFlyer.validateAndLogInAppPurchase({
        purchase: afDetails,
        additionalParameters: additionalParams
    }), 'validateAndLogInAppPurchase');
}
