//Button Functions
let trackEventBtn = document.getElementById('logEvent');
let setCurrencyBtn = document.getElementById('setCurrency');
let setUserIdBtn = document.getElementById('setUserId');
let getUseridBtn = document.getElementById('getUserId');
let getSdkVersionBtn = document.getElementById('getSdkV');
let crossPromotionandStore = document.getElementById('logCrossPromotionAndOpenStore');
let customDomains = document.getElementById('customDomains');
let enableFB = document.getElementById('enableFB');
let setUserEmails = document.getElementById('userEmails');
let setPhone = document.getElementById('phone');
let setHost = document.getElementById('hosts');
let setPath = document.getElementById('path');

if (trackEventBtn) {
    trackEventBtn.addEventListener('click', logEvent, false);
}
if (setCurrencyBtn) {
    setCurrencyBtn.addEventListener('click', setCurrency, false);
}
if (setUserIdBtn) {
    setUserIdBtn.addEventListener('click', setUserId, false);
}
if (getUseridBtn) {
    getUseridBtn.addEventListener('click', getUserId, false);
}
if (getSdkVersionBtn) {
    getSdkVersionBtn.addEventListener('click', getSdkVersion, false);
}
if (crossPromotionandStore) {
    crossPromotionandStore.addEventListener('click', logCrossPromotionAndOpenStore, false);
}
if (customDomains) {
    customDomains.addEventListener('click', setCustomDomains, false);
}
if (enableFB) {
    enableFB.addEventListener('click', setFBEnabled, false);
}
if (setUserEmails) {
    setUserEmails.addEventListener('click', setEmails, false);
}
if (setPhone) {
    setPhone.addEventListener('click', setPhoneNumber, false);
}
if (setHost) {
    setHost.addEventListener('click', setHosts, false);
}
if (setPath) {
    setPath.addEventListener('click', addPushNotificationDeepLinkPath, false);
}
let successTrackEvent = function (success) {
    alert(success);
};

let failureTrackEvent = function (failure) {
    alert(failure);
};
let print = function (txt) {
    console.log(txt);
};

function callBackFunction(id) {
    alert('received: ' + id);
}

function setCurrency(currencyId) {
    currencyId = 'USD';
    window.plugins.appsFlyer.setCurrencyCode(currencyId);
}

function setHosts() {
    let prefix = "foo"
    let name = "bar"
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
    let phone = "0522565426"
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

