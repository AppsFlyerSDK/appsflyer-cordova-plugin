//Button Functions
var trackEventBtn=document.getElementById("trackEvent");
var setCurrencyBtn=document.getElementById("setCurrency");
var setUserIdBtn=document.getElementById("setUserId");
var getUseridBtn=document.getElementById("getUserId");
var getSdkVersionBtn=document.getElementById("getSdkV");

if(trackEventBtn){
    trackEventBtn.addEventListener("click", trackEvent, false);
}
if(setCurrencyBtn){
    setCurrencyBtn.addEventListener("click", setCurrency, false);
}
if(setUserIdBtn){
    setUserIdBtn.addEventListener("click", setUserId, false);
}
if(getUseridBtn){
   getUseridBtn.addEventListener("click", getUserId, false);
}
if(getSdkVersionBtn){
   getSdkVersionBtn.addEventListener("click", getSdkVersion, false);
}

var successTrackEvent = function(success){
    alert(success);
}

var failureTrackEvent = function(failure){
    alert(failure);
}

 function setCurrency(currencyId){
    currencyId = "USD";
    alert('Currency Set: '+currencyId);
    window.plugins.appsFlyer.setCurrencyCode(currencyId);
}
 function setUserId(userAppId) {
    userAppId = "887788778";
     alert('Set User ID: '+userAppId);
    window.plugins.appsFlyer.setAppUserId(userAppId);
}
 function getUserId() {
    window.plugins.appsFlyer.getAppsFlyerUID(callBackFunction);
}

 function getSdkVersion() {
    window.plugins.appsFlyer.getSdkVersion(callBackFunction);
}

 function callBackFunction(id) {
    alert('received: ' + id);
}
 function trackEvent(eventName, eventValues) {
    eventName = "af_add_to_cart";
    eventValues = {"af_content_id": "id123", "af_currency":"USD", "af_revenue": "2"};
    window.plugins.appsFlyer.trackEvent(eventName, eventValues, successTrackEvent, failureTrackEvent);
}
