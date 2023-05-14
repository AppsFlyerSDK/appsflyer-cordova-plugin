//Button Functions
let logEventBtn = document.getElementById('logEvent');
let logCrossPromotionAndOpenStoreBtn = document.getElementById('logCrossPromotionAndOpenStore');
let setCurrencyBtn = document.getElementById('setCurrency');
let setUserIdBtn = document.getElementById('setUserId');
let setUserEmailsBtn = document.getElementById('setUserEmails');
let setPhoneBtn = document.getElementById('setPhone');
let setHostsBtn = document.getElementById('setHosts');
let getUserIdBtn = document.getElementById('getUserId');
let getSdkVBtn = document.getElementById('getSdkV');
let customDomainsBtn = document.getElementById('customDomains');
let enableFBBtn = document.getElementById('enableFB');
let addPushNotificationPathBtn = document.getElementById('addPushNotificationPath');

if (logEventBtn) {
    logEventBtn.addEventListener('click', logEvent, false);
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
if (getUserIdBtn) {
    getUserIdBtn.addEventListener('click', getUserId, false);
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

function callBackFunction(id) {
    alert('received: ' + id);
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

function setCustomDomains() {
    let domains = ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"];
    window.plugins.appsFlyer.setOneLinkCustomDomains(domains, callBackFunction, callBackFunction);
}

function addPushNotificationDeepLinkPath() {
    let path = ["go", "to", "this", "path"];
    window.plugins.appsFlyer.addPushNotificationDeepLinkPath(path);
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

function logCrossPromotionAndOpenStore() {
    window.plugins.appsFlyer.logCrossPromotionAndOpenStore('1528937655', 'test', {
        custom_param: 'custom_value',
    });
}
