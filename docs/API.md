# API

<img src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400" >



The list of available methods for this plugin is described below.


| method name| params| description|
| ----------- |-----------------------------|--------------|
| [`initSdk`](#initSdk) | `(Object args, function success, function error)`  | Initialize the SDK|
| [`trackEvent`](#trackEvent) | `(String eventName, Object eventValue, function success, function error)` | Track rich in-app events |
| [`registerOnAppOpenAttribution`](#registerOnAppOpenAttribution) | `(function success, function error)` | Get the deeplink data |
| [`setCurrencyCode`](#setCurrencyCode) | `(String currencyId)` | Set currency code |
| [`setAppUserId`](#setAppUserId) | `(String customerUserId)` | Set custom_user_id  |
| [`setGCMProjectNumber`](#initSdk) | `(String gcmProjectNumber)` |  |
| [`getAppsFlyerUID`](#getAppsFlyerUID) | `(function success)` | Get AppsFlyer’s proprietary Device ID |
| [`setDeviceTrackingDisabled`](#deviceTrackingDisabled) | `(Boolean isDisabled)` | Anonymize user data |
| [`stopTracking`](#stopTracking)| `(Boolean isStopTracking)` | Shut down all SDK tracking |
| [`enableUninstallTracking`](#enableUninstallTracking) | `(String gcmProjectNumber,function success, function error)` | (Android) Enables app uninstall tracking |
| [`updateServerUninstallToken`](#updateServerUninstallToken) | `(String token)` | (Android) Pass GCM/FCM Tokens |
| [`registerUninstall`](#registerUninstall) | `(String token)` | (iOS) Pass APNs Tokens |
| [`setAppInviteOneLinkID`](#setAppInviteOneLinkID) | `(Object args)` | Set AppsFlyer’s OneLink ID |
| [`generateInviteLink`](#generateInviteLink) | `(Object args, function success, function error)` | Error callback |
| [`trackCrossPromotionImpression`](#trackCrossPromotionImpression) | `(String appId, String campaign)` | Track cross promotion impression |
| [`trackAndOpenStore`](#trackAndOpenStore) | `(String appId, String campaign, Object params)` | Launch the app store's app page (via Browser) |
| [`handleOpenUrl`](#deep-linking-tracking) | `(String url)` |  |
| [`getSdkVersion`](#getSdkVersion) | `((function success)` | Get the current SDK version |


---

##### <a id="initSdk"> **`initSdk(options, onSuccess, onError): void`**

initialize the SDK.

| parameter   | type                        | description  |
| ----------- |-----------------------------|--------------|
| `options`   | `Object`                    |   SDK configuration           |
| `onSuccess` | `(message: string)=>void` | Success callback - called after successful SDK initialization. |
| `onError`   | `(message: string)=>void` | Error callback - called when error occurs during initialization. |

**`options`**

| name       | type    | default | description            |
| -----------|---------|---------|------------------------|
| `devKey`   |`string` |         |   [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android)    |
| `appId`    |`string` |        | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |
| `isDebug`  |`boolean`| `false` | debug mode (optional)|
| `useUninstallSandbox`  |`boolean`| `false` | For iOS only, to test uninstall in Sandbox environment (optional)|
| `collectIMEI`   | `boolean` | `false` |opt-out of collection of IMEI |
| `collectAndroidID`   | `boolean` | `false` |opt-out of collection of collectAndroidID |
| `onInstallConversionDataListener`  |`boolean`| `false` | Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](http://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](http://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data in `onSuccess` callback.

*Example:*

```javascript
var onSuccess = function(result) {
// handle result  
};

var onError = function(err) {
// handle error
}

var options = {
devKey: 'd3Ac9qPardVYZxfWmCspwL',
appId: '123456789',
isDebug: false,
onInstallConversionDataListener: true //optional
};

window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
```

---

##### <a id="trackEvent"> **`trackEvent(eventName, eventValues, onSuccess, onError): void`** (optional)


- These in-app events help you track how loyal users discover your app, and attribute them to specific 
campaigns/media-sources. Please take the time define the event/s you want to measure to allow you 
to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `eventName` | `String`                    | custom event name, is presented in your dashboard.  See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h)  |
| `eventValue` | `Object`                    | event details |
| `onSuccess` | `(message: string)=>void`                    | event details |
| `onError` | `(message: string)=>void`                    | event details |

*Example:*

```javascript
var successTrackEvent = function(success){
    alert(success);
}

var failureTrackEvent = function(failure){
    alert(failure);
}

var eventName = 'af_add_to_cart';
var eventValues = {
'af_content_id': 'id123',
'af_currency': 'USD',
'af_revenue': '2'
};
window.plugins.appsFlyer.trackEvent(eventName, eventValues, successTrackEvent, failureTrackEvent);
```
---

##### <a id="deviceTrackingDisabled"> **`deviceTrackingDisabled(bool): void`**
**End User Opt-Out (Optional)** 
AppsFlyer provides you a method to opt‐out specific users from AppsFlyer analytics. This method complies with the latest privacy requirements and complies with Facebook data and privacy policies. Default is FALSE, meaning tracking is enabled by default.

*Examples:*

```javascript
window.plugins.appsFlyer.setDeviceTrackingDisabled(true);
```
---

##### <a id="setCurrencyCode"> **`setCurrencyCode(currencyId): void`**


| parameter   | type                  | Default     | description |
| ----------- |-----------------------|-------------|-------------|
| `currencyId`| `String`              |   `USD`     |  [ISO 4217 Currency Codes](http://www.xe.com/iso4217.php)           |

*Examples:*

```javascript
window.plugins.appsFlyer.setCurrencyCode('USD');
window.plugins.appsFlyer.setCurrencyCode('GBP'); // British Pound
```

---

##### <a id="setAppUserId"> **`setAppUserId(customerUserId): void`**


Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs. This ID is available in AppsFlyer CSV reports along with postbacks APIs for cross-referencing with you internal IDs.

**Note:** The ID must be set during the first launch of the app at the SDK initialization. The best practice is to call this API during the `deviceready` event, where possible.


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `customerUserId`   | `String`                      | |

*Example:*

```javascript
window.plugins.appsFlyer.setAppUserId(userId);
```

---


##### <a id="stopTracking"> **`stopTracking(isStopTracking): void`**

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `isStopTracking`   | `boolean`                      |In some extreme cases you might want to shut down all SDK tracking due to legal and privacy compliance. This can be achieved with the isStopTracking API. Once this API is invoked, our SDK will no longer communicate with our servers and stop functioning. |

*Example:*

```javascript
window.plugins.appsFlyer.stopTracking(true);
```

In any event, the SDK can be reactivated by calling the same API, but to pass false.

---


##### <a id="registerOnAppOpenAttribution"> **`registerOnAppOpenAttribution(onSuccess, onError): void`**




| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `onSuccess` | `(message: stringifed JSON)=>void` | Success callback - called after receiving data on App Open Attribution.|
| `onError`   | `(message: stringifed JSON)=>void` | Error callback - called when error occurs.|

*Example:*

```javascript
window.plugins.appsFlyer.registerOnAppOpenAttribution(function(res) {
/*
{
"data": {
"af_deeplink": "true",
"campaign": "boo",
"key": "val",
"media_source": "someMedia",
"install_time": "2018-07-12 13:20:19",
"af_status": "Non-organic",
"path": "",
"scheme": "https",
"host": "ionic.fess.onelink.me"
},
"type": "onAppOpenAttribution",
"status": "success"
}
*/
}, 
function onAppOpenAttributionError(err){
// ...
});
```

---


##### <a id="enableUninstallTracking"> **`enableUninstallTracking(token, onSuccess, onError): void`** 

(Android) Enables app uninstall tracking.
<a href="https://support.appsflyer.com/hc/en-us/articles/211211963-iOS-Uninstall-Tracking">More Information</a>

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `FCM/GCM ProjectNumber`   | `String`    | GCM/FCM ProjectNumber |
| `onSuccess` | `(message: string)=>void` | Success callback - called after successful register uninstall. (optional)|
| `onError`   | `(message: string)=>void` | Error callback - called when error occurs during register uninstall. (optional)|


---



##### <a id="updateServerUninstallToken"> **`updateServerUninstallToken("token"): void`** 

(Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server.
Can be used for Uninstall Tracking.


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `token`   | `String`                      | GCM/FCM Token|


---



##### <a id="registerUninstall"> **`registerUninstall("<token>"): void`** 

(iOS) Allows to pass APN Tokens that where collected by third party plugins to the AppsFlyer server.
Can be used for Uninstall Tracking.


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `token`   | `String`                      | APN Token|


---

##### <a id="getAppsFlyerUID"> **`getAppsFlyerUID(successCB): void`**  (Advanced)

Get AppsFlyer’s proprietary Device ID. The AppsFlyer Device ID is the main ID used by AppsFlyer in Reports and APIs.

```javascript
function getUserIdCallbackFn(id){/* ... */} 
window.plugins.appsFlyer.getAppsFlyerUID(getUserIdCallbackFn);
```
*Example:*

```javascript
var getUserIdCallbackFn = function(id) {
alert('received id is: ' + id);
}
window.plugins.appsFlyer.getAppsFlyerUID(getUserIdCallbackFn);
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `getUserIdCallbackFn` | `() => void`                | Success callback |


---

##### <a id="setAppInviteOneLinkID"> **`setAppInviteOneLinkID(OneLinkID): void`**  (User Invite / Cross Promotion)

Set AppsFlyer’s OneLink ID. Setting a valid OneLink ID will result in shortened User Invite links, when one is generated. The OneLink ID can be obtained on the AppsFlyer Dashboard.

*Example:*
```javascript
window.plugins.appsFlyer.setAppInviteOneLinkID('Ab1C');
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `OneLinkID` | `String`                    | OneLink ID |


---

##### <a id="generateInviteLink"> **`generateInviteLink(options, onSuccess, onError): void`**  (User Invite)

Allowing your existing users to invite their friends and contacts as new users to your app can be a key growth factor for your app. AppsFlyer allows you to track and attribute new installs originating from user invites within your app.

*Example:*
```javascript
var inviteOptions {
channel: 'gmail',
campaign: 'myCampaign',
customerID: '1234',
userParams {
myParam: 'newUser',
anotherParam: 'fromWeb',
amount: 1
}
};

var onInviteLinkSuccess = function(link) {
console.log(link); // Handle Generated Link Here
}

function onInviteLinkError(err) {
console.log(err);
}

window.plugins.appsFlyer.generateInviteLink(inviteOptions, onInviteLinkSuccess, onInviteLinkError);
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `inviteOptions` | `Object`                    |Parameters for Invite link  |
| `onInviteLinkSuccess` | `() => void`                | Success callback (generated link) |
| `onInviteLinkError` | `() => void`                | Error callback |

A complete list of supported parameters is available <a href="https://support.appsflyer.com/hc/en-us/articles/115004480866-User-Invite-Tracking">here</a>.
Custom parameters can be passed using a `userParams{}` nested object, as in the example above.

---

##### <a id="trackCrossPromotionImpression"> **`trackCrossPromotionImpression("appID", "campaign"): void`**  (Cross Promotion)

Use this call to track an impression use the following API call. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.

*Example:*
```javascript
window.plugins.appsFlyer.trackCrossPromotionImpression("com.myandroid.app", "myCampaign");
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `appID` | `String`                    | Promoted Application ID |
| `campaign` | `String`                    | Promoted Campaign |

For more details about Cross-Promotion tracking please see <a href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="trackAndOpenStore"> **`trackAndOpenStore("appID","campaign", options): void`**  (Cross Promotion)

Use this call to track the click and launch the app store's app page (via Browser)

*Example:*
```javascript
var crossPromOptions {
customerID: '1234',
myCustomParameter: 'newUser'
};

window.plugins.appsFlyer.trackAndOpenStore('com.myandroid.app', 'myCampaign', crossPromOptions);
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `appID` | `String`                    | Promoted Application ID |
| `campaign` | `String`                    | Promoted Campaign |
| `options` | `Object`                    | Additional Parameters to track |

For more details about Cross-Promotion tracking please see <a href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="getSdkVersion"> **`getSdkVersion(successCB): void`**

Get the current SDK version

*Example:*
```javascript
var getSdkVersionCallbackFn = function(v) {
alert('SDK version: ' + v);
}
window.plugins.appsFlyer.getSdkVersion(getSdkVersionCallbackFn);
```

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `getSdkVersionCallbackFn` | `void`                   | Success callback |

---
### <a id="deep-linking-tracking"> Deep linking Tracking

#### <a id="dl-android"> Android
In ver. >4.2.5 deeplinking metadata (scheme/host) is sent automatically

#### <a id="dl-ios"> iOS URL Types
Add the following lines to your code to be able to track deeplinks with AppsFlyer attribution data:

for pure Cordova - add a function 'handleOpenUrl' to your root, and call our SDK as shown:
```javascript
window.plugins.appsFlyer.handleOpenUrl(url);
```
It appears as follows:

```javascript
var handleOpenURL = function(url) {
window.plugins.appsFlyer.handleOpenUrl(url);
}
```
#### <a id='dl-ul'>Universal Links in iOS
To enable Universal Links in iOS please follow the guide <a href="https://support.appsflyer.com/hc/en-us/articles/207032266-Setting-Deeplinking-on-iOS9-using-iOS-Universal-Links">here</a>.

##### **Note**: Our plugin uses method swizzeling for

` - (BOOL)application:(UIApplication *)application 
continueUserActivity:(NSUserActivity *)userActivity
restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler; ` 

---
