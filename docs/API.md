# API

  

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

  
  
  

The list of available methods for this plugin is described below.

| method name                                                           | params                                                                    | description                                                                                             |
|-----------------------------------------------------------------------|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| [`initSdk`](#initSdk)                                                 | `(Object args, function success, function error)`                         | Initialize the SDK                                                                                      |
| [`startSdk`](#startSdk)                                               | `()`                                                                      | Starts the SDK - Must call initSdk first in order to make this work                                     |
| [`logEvent`](#trackEvent)                                             | `(String eventName, Object eventValue, function success, function error)` | Track rich in-app events                                                                                |
| [`registerOnAppOpenAttribution`](#registerOnAppOpenAttribution)       | `(function success, function error)`                                      | Get the deeplink data                                                                                   |
| [`registerDeepLink`](#registerDeepLink)                               | `(function callBack)`                                                     | Get unified deep link data                                                                              |
| [`setCurrencyCode`](#setCurrencyCode)                                 | `(String currencyId)`                                                     | Set currency code                                                                                       |
| [`setAppUserId`](#setAppUserId)                                       | `(String customerUserId)`                                                 | Set custom_user_id                                                                                      |
| [`setGCMProjectNumber`](#initSdk)                                     | `(String gcmProjectNumber)`                                               |                                                                                                         |
| [`getAppsFlyerUID`](#getAppsFlyerUID)                                 | `(function success)`                                                      | Get AppsFlyer’s proprietary Device ID                                                                   |
| [`anonymizeUser`](#deviceTrackingDisabled)                            | `(Boolean isDisabled)`                                                    | Anonymize user data                                                                                     |
| [`Stop`](#stopTracking)                                               | `(Boolean isStopTracking)`                                                | Shut down all SDK tracking                                                                              |
| [`updateServerUninstallToken`](#updateServerUninstallToken)           | `(String token)`                                                          | (Android) Pass GCM/FCM Tokens                                                                           |
| [`registerUninstall`](#registerUninstall)                             | `(String token)`                                                          | (iOS) Pass APNs Tokens                                                                                  |
| [`setAppInviteOneLinkID`](#setAppInviteOneLinkID)                     | `(Object args)`                                                           | Set AppsFlyer’s OneLink ID                                                                              |
| [`generateInviteLink`](#generateInviteLink)                           | `(Object args, function success, function error)`                         | Error callback                                                                                          |
| [`logCrossPromotionImpression`](#trackCrossPromotionImpression)       | `(String appId, String campaign)`                                         | Track cross promotion impression                                                                        |
| [`logCrossPromotionAndOpenStore`](#trackAndOpenStore)                 | `(String appId, String campaign, Object params)`                          | Launch the app store's app page (via Browser)                                                           |
| [`handleOpenUrl`](#deep-linking-tracking)                             | `(String url)`                                                            |                                                                                                         |
| [`getSdkVersion`](#getSdkVersion)                                     | `((function success)`                                                     | Get the current SDK version                                                                             |
| [`setSharingFilterForAllPartners`](#setSharingFilterForAllPartners)   |                                                                           | Used by advertisers to exclude all networks/integrated partners from getting data                       |
| [`setSharingFilter`](#setSharingFilter)                               | `(partners)`                                                              | Used by advertisers to exclude specified networks/integrated partners from getting data                 |
| [`setSharingFilterForPartners`](#setSharingFilterForPartners)         | `(partners)`                                                              | Used by advertisers to exclude specified networks/integrated partners from getting data                 |
| [`validateAndLogInAppPurchase`](#validateAndLogInAppPurchase)         | `(Object purchaseInfo, function success, function error)`                 | API for server verification of in-app purchases                                                         |
| [`setUseReceiptValidationSandbox`](#setUseReceiptValidationSandbox)   | `(boolean isSandbox, function success, function error)`                   | In app purchase receipt validation Apple environment                                                    |
| [`disableCollectASA`](#disableCollectASA)                             | `(boolean collectASA, function success)`                                  | **iOS**  - set the SDK to load OR not to load iAd.framework dynamically                                 |
| [`setDisableAdvertisingIdentifier`](#setDisableAdvertisingIdentifier) | `(boolean disableAdvertisingIdentifier, function success)`                | Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).          |
| [`setOneLinkCustomDomains`](#setOneLinkCustomDomains)                 | `(domains, function success, function error)`                             | Set Onelink custom/branded domains                                                                      |
| [`enableFacebookDeferredApplinks`](#enableFacebookDeferredApplinks)   | `(boolean isEnabled)`                                                     | support deferred deep linking from Facebook Ads                                                         |
| [`setUserEmails`](#setUserEmails)                                     | `(emails, function success)`                                              | Set user emails for FB Advanced Matching                                                                |
| [`setPhoneNumber`](#setPhoneNumber)                                   | `(String phoneNumber, function success)`                                  | Set phone number for FB Advanced Matching                                                               |
| [`setHost`](#setHost)                                                 | `(String hostPrefix, String hostName)`                                    | Set custom host prefix and host name                                                                    |
| [`addPushNotificationDeepLinkPath`](#addPushNotificationDeepLinkPath) | `(path)`                                                                  | configure push notification deep link resolution                                                        |
| [`setResolveDeepLinkURLs`](#setResolveDeepLinkURLs)                   | `(urls)`                                                                  | get the OneLink from click domains                                                                      |
| [`disableSKAD`](#disableSKAD)                                         | `(boolean disableSkad)`                                                   | disable or enable SKAD                                                                                  |
| [`setCurrentDeviceLanguage`](#setCurrentDeviceLanguage)               | `(string language)`                                                       | Set the language of the device.                                                                         |
| [`setAdditionalData`](#setAdditionalData)                             | `(Object additionalData)`                                                 | Allows you to add custom data to events sent from the SDK.                                              |
| [`setPartnerData`](#setPartnerData)                                   | `(partnerId, data)`                                                       | Allows sending custom data for partner integration purposes.                                            |
| [`sendPushNotificationData`](#sendPushNotificationData)               | `(Object data)`                                                           | Measure and get data from push-notification campaigns.                                                  |
| [`setDisableNetworkData`](#setDisableNetworkData)                     | `(boolean disable)`                                                       | Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device. |
| [`setConsentData`](#setConsentData)                                   | `(AppsFlyerConsent consent)`                                              | Set consent fields manually (e.g. by prompting user and collecting results).                            |                                           
| [`enableTCFDataCollection`](#enableTCFDataCollection)                                   | `(boolean enable)`                                                        | instruct the SDK to collect the TCF data from the device.                                               |                                           
| [`logAdRevenue`](#logAdRevenue)                                   | `(Object adRevenueData, Object additionalParams)`                         | Log ad revenue event.                                                                                   |                                           

  
---

##### <a id="initSdk"> **`initSdk(options, onSuccess, onError): void`**

initialize the SDK.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `options` | `Object` | SDK configuration |
| `onSuccess` | `(message: string)=>void` | Success callback - called after successful SDK initialization. |
| `onError` | `(message: string)=>void` | Error callback - called when error occurs during initialization. |

**`options`**

| name                              | type | default | description |
|-----------------------------------|---------|---------|------------------------|
| `devKey`                          |`string` |         | [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android) |
| `appId`                           |`string` |         | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |
| `isDebug`                         |`boolean`| `false` | debug mode (optional)|
| `useUninstallSandbox`             |`boolean`| `false` | For iOS only, to test uninstall in Sandbox environment (optional)|
| `collectIMEI`                     | `boolean` | `false` |opt-out of collection of IMEI |
| `collectAndroidID`                | `boolean` | `false` |opt-out of collection of collectAndroidID |
| `onInstallConversionDataListener` |`boolean`| `false` | Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](http://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](http://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data in `onSuccess` callback. |
| `shouldStartSdk`                  |`boolean`| `true`  | Prevents from the SDK from sending the launch request after using appsFlyer.initSdk(...). When using this property, the apps needs to manually trigger the appsFlyer.startSdk() API to report the app launch. read more here. (Optional, default=true)|
.

*Example:*

```javascript
var  onSuccess = function(result) {
// handle result
};

var  onError = function(err) {
// handle error
}

var  options = {
devKey:  'd3Ac9qPardVYZxfWmCspwL',
appId:  '123456789',
isDebug:  false,
onInstallConversionDataListener:  true  //optional
};

window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
```

---

##### <a id="startSdk"> **`startSdk(): void`**

Starts the SDK

*Example:*

```javascript
window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
window.plugins.appsFlyer.startSdk();
```
---
##### <a id="trackEvent"> **`logEvent(eventName, eventValues, onSuccess, onError): void`** (optional)

- These in-app events help you track how loyal users discover your app, and attribute them to specific
campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `eventName` | `String` | custom event name, is presented in your dashboard. See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h) |
| `eventValue` | `Object` | event details |
| `onSuccess` | `function` | triggered when the event was sent successfully. returns the event's name. can be Null |
| `onError` | `function` | triggered when an error occurred. returns an error message. can be Null |

*Example:*

```javascript
var  successTrackEvent = function(success){
alert(success);
}

var  failureTrackEvent = function(failure){
alert(failure);
}

var  eventName = 'af_add_to_cart';
var  eventValues = {
'af_content_id':  'id123',
'af_currency':  'USD',
'af_revenue':  '2'
};

window.plugins.appsFlyer.logEvent(eventName, eventValues, successTrackEvent, failureTrackEvent);
//OR
window.plugins.appsFlyer.logEvent(eventName, eventValues, null, null);
```
---

##### <a id="deviceTrackingDisabled"> **`anonymizeUser(bool): void`**

**End User Opt-Out (Optional)**

AppsFlyer provides you a method to opt‐out specific users from AppsFlyer analytics. This method complies with the latest privacy requirements and complies with Facebook data and privacy policies. Default is FALSE, meaning tracking is enabled by default.

*Examples:*

```javascript
window.plugins.appsFlyer.anonymizeUser(true);
```

---

##### <a id="setCurrencyCode"> **`setCurrencyCode(currencyId): void`**

| parameter | type | Default | description |
| ----------- |-----------------------|-------------|-------------|
| `currencyId`| `String` | `USD` | [ISO 4217 Currency Codes](http://www.xe.com/iso4217.php) |

*Examples:*

```javascript

window.plugins.appsFlyer.setCurrencyCode('USD');
window.plugins.appsFlyer.setCurrencyCode('GBP'); // British Pound

```

---

##### <a id="setAppUserId"> **`setAppUserId(customerUserId): void`**

Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs. This ID is available in AppsFlyer CSV reports along with postbacks APIs for cross-referencing with you internal IDs.

**Note:** The ID must be set during the first launch of the app at the SDK initialization. The best practice is to call this API during the `deviceready` event, where possible.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `customerUserId` | `String` | |

*Example:*

```javascript
window.plugins.appsFlyer.setAppUserId(userId);
```

---

##### <a id="stopTracking"> **`Stop(isStopTracking): void`**

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `Stop` | `boolean` |In some extreme cases you might want to shut down all SDK tracking due to legal and privacy compliance. This can be achieved with the isStopTracking API. Once this API is invoked, our SDK will no longer communicate with our servers and stop functioning. |

*Example:*

```javascript
window.plugins.appsFlyer.Stop(true);
```

In any event, the SDK can be reactivated by calling the same API, but to pass false.

---

##### <a id="registerOnAppOpenAttribution"> **`registerOnAppOpenAttribution(onSuccess, onError): void`**

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `onSuccess` | `(message: stringifed JSON)=>void` | Success callback - called after receiving data on App Open Attribution.|
| `onError` | `(message: stringifed JSON)=>void` | Error callback - called when error occurs.|

*Example:*

```javascript
window.plugins.appsFlyer.registerOnAppOpenAttribution(function(res) {
        console.log('AppsFlyer OAOA ==> ' + res);
        alert('AppsFlyer OAOA ==> ' + res);
     },
     function onAppOpenAttributionError(err) {
         console.log(err);
     });

```
---
##### <a id="registerDeepLink"> **`registerDeepLink(callBack): void`**

**Note:** most be called before `initSdk()` and it overrides `registerOnAppOpenAttribution`.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `callBack` | `(message: stringifed JSON)=>void` | function called after receiving dep link data|

*Example:*

```javascript
window.plugins.appsFlyer.registerDeepLink(function(res) {
    console.log('AppsFlyer DDL ==> ' + res);
    alert('AppsFlyer DDL ==> ' + res);
});
```
---

##### <a id="updateServerUninstallToken"> **`updateServerUninstallToken("token"): void`**

(Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server.
Can be used for Uninstall Tracking.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `token` | `String` | GCM/FCM Token|

----

##### <a id="registerUninstall"> **`registerUninstall("<token>"): void`**

(iOS) Allows to pass APN Tokens that where collected by third party plugins to the AppsFlyer server.
Can be used for Uninstall Tracking.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `token` | `String` | APN Token|

---

##### <a id="getAppsFlyerUID"> **`getAppsFlyerUID(successCB): void`** (Advanced)

Get AppsFlyer’s proprietary Device ID. The AppsFlyer Device ID is the main ID used by AppsFlyer in Reports and APIs.

```javascript
function  getUserIdCallbackFn(id){/* ... */}

window.plugins.appsFlyer.getAppsFlyerUID(getUserIdCallbackFn);
```
*Example:*

```javascript
var  getUserIdCallbackFn = function(id) {
alert('received id is: ' + id);
}

window.plugins.appsFlyer.getAppsFlyerUID(getUserIdCallbackFn);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `getUserIdCallbackFn` | `() => void` | Success callback |

---

##### <a id="setAppInviteOneLinkID"> **`setAppInviteOneLinkID(OneLinkID): void`** (User Invite / Cross Promotion)

Set AppsFlyer’s OneLink ID. Setting a valid OneLink ID will result in shortened User Invite links, when one is generated. The OneLink ID can be obtained on the AppsFlyer Dashboard.

*Example:*
```javascript
window.plugins.appsFlyer.setAppInviteOneLinkID('Ab1C');
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `OneLinkID` | `String` | OneLink ID |

---

##### <a id="generateInviteLink"> **`generateInviteLink(options, onSuccess, onError): void`** (User Invite)

Allowing your existing users to invite their friends and contacts as new users to your app can be a key growth factor for your app. AppsFlyer allows you to track and attribute new installs originating from user invites within your app.

*Example:*
```javascript
var  inviteOptions {
channel: 'gmail',
campaign: 'myCampaign',
customerID: '1234',
userParams {
myParam: 'newUser',
anotherParam: 'fromWeb',
amount: 1
}
};

var  onInviteLinkSuccess = function(link) {
console.log(link); // Handle Generated Link Here
}

function  onInviteLinkError(err) {
console.log(err);
}

window.plugins.appsFlyer.generateInviteLink(inviteOptions, onInviteLinkSuccess, onInviteLinkError);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `inviteOptions` | `Object` |Parameters for Invite link |
| `onInviteLinkSuccess` | `() => void` | Success callback (generated link) |
| `onInviteLinkError` | `() => void` | Error callback |

A complete list of supported parameters is available <a  href="https://support.appsflyer.com/hc/en-us/articles/115004480866-User-Invite-Tracking">here</a>.
Custom parameters can be passed using a `userParams{}` nested object, as in the example above.

---

##### <a id="trackCrossPromotionImpression"> **`logCrossPromotionImpression("appID", "campaign"): void`** (Cross Promotion)

Use this call to track an impression use the following API call. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.

*Example:*
```javascript
window.plugins.appsFlyer.logCrossPromotionImpression("com.myandroid.app", "myCampaign");
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `appID` | `String` | Promoted Application ID |
| `campaign` | `String` | Promoted Campaign |

For more details about Cross-Promotion tracking please see <a  href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="trackAndOpenStore"> **`logCrossPromotionAndOpenStore("appID","campaign", options): void`** (Cross Promotion)

Use this call to track the click and launch the app store's app page (via Browser)

*Example:*

```javascript
var  crossPromOptions {
customerID: '1234',
myCustomParameter: 'newUser'
};

window.plugins.appsFlyer.logCrossPromotionAndOpenStore('com.myandroid.app', 'myCampaign', crossPromOptions);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `appID` | `String` | Promoted Application ID |
| `campaign` | `String` | Promoted Campaign |
| `options` | `Object` | Additional Parameters to track |

For more details about Cross-Promotion tracking please see <a  href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="getSdkVersion"> **`getSdkVersion(successCB): void`**

Get the current SDK version

*Example:*

```javascript
var  getSdkVersionCallbackFn = function(v) {
alert('SDK version: ' + v);
}
window.plugins.appsFlyer.getSdkVersion(getSdkVersionCallbackFn);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `getSdkVersionCallbackFn` | `void` | Success callback |

---

##### <a id="setSharingFilterForAllPartners"> **`setSharingFilterForAllPartners(): void`**

Used by advertisers to exclude all networks/integrated partners from getting data. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

*Example:*

```javascript
window.plugins.appsFlyer.setSharingFilterForAllPartners();
```
---

##### <a id="setSharingFilter"> **`setSharingFilter(partners): void`**

Used by advertisers to exclude specified networks/integrated partners from getting data. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

*Example:*

```javascript
let  partners = ["facebook_int","googleadwords_int","snapchat_int","doubleclick_int"];

window.plugins.appsFlyer.setSharingFilter(partners);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `partners` | `array` | Comma separated array of partners that need to be excluded |

---

##### <a id="setSharingFilterForPartners"> **`setSharingFilterForPartners(partners): void`**

Used by advertisers to exclude specified networks/integrated partners from getting data networks Comma separated array of partners that need to be excluded. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

*Example:*

```javascript
let  partners = ["facebook_int","googleadwords_int","snapchat_int","doubleclick_int"];

window.plugins.appsFlyer.setSharingFilterForPartners(partners);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `partners` | `array` | Comma separated array of partners that need to be excluded |

---

##### <a id="validateAndLogInAppPurchase"> **`validateAndLogInAppPurchase(purchaseInfo, successC, failureC): void`**

Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases)

*Example:*

```javascript
 purchaseInfo = {
        productIdentifier: 'identifier', //iOS
        transactionId: '12xxx56', //iOS
        publicKey: "key",
        currency: 'biz',
        signature: "sig",
        purchaseData: "data",
        price: '123',
        additionalParameters: {'foo': 'bar'},
    };
    window.plugins.appsFlyer.setUseReceiptValidationSandbox(true); // iOS -> for testing in sandbox environment
    window.plugins.appsFlyer.validateAndLogInAppPurchase(purchaseInfo, successC, failureC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `purchaseInfo` | `Object` | In-App Purchase parameters |
| `successC` | `function` | success callback |
| `failureC` | `function` | failure callback |

*Purchase parameters:*

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `publicKey` | `string` | License Key obtained from the Google Play Console |
| `signature` | `string` | data.INAPP_DATA_SIGNATURE |
| `purchaseData` | `string` | data.INAPP_PURCHASE_DATA |
| `price` | `string` | The product price |
| `additionalParameters` | `Object` | The additional param, which you want to receive it in the raw reports. |
| `productIdentifier` | `string` | The product identifier. *FOR iOS* |
| `transactionId` | `string` | The purchase transaction Id. *FOR iOS* |
| `currency` | `string` | The product currency |
---

##### <a id="setUseReceiptValidationSandbox"> **`setUseReceiptValidationSandbox(isSandbox, successC, failureC): void`**

In app purchase receipt validation Apple environment(production or sandbox)<br>Callback functions are optional.

*Example:*

```javascript
window.plugins.appsFlyer.setUseReceiptValidationSandbox(true);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `isSandbox` | `boolean` | true if In app purchase is done with sandbox |

---

##### <a id="disableCollectASA"> **`disableCollectASA(collectASA, successC): void`**
**iOS ONLY**<br>
AppsFlyer SDK dynamically loads the Apple iAd.framework. This framework is required to record and measure the performance of Apple Search Ads in your app.<br>
If you don't want AppsFlyer to dynamically load this framework, set this property to true.<br>
*Example:*

```javascript
window.plugins.appsFlyer.disableCollectASA(true, successC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `collectASA` | `boolean` | If you don't want AppsFlyer to dynamically load iAd.framework, set this property to true |
| `successC` | `function` | success callback |
---
##### <a id="setDisableAdvertisingIdentifier"> **`setDisableAdvertisingIdentifier(disableAdvertisingIdentifier, successC): void`**
Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).<br>
*Example:*

```javascript
window.plugins.appsFlyer.setDisableAdvertisingIdentifier(true, successC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disableAdvertisingIdentifier` | `boolean` |Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).|
| `successC` | `function` | success callback |
---

##### <a id="setOneLinkCustomDomains"> **`setOneLinkCustomDomains(domains, successC, errorC): void`**
Set Onelink custom/branded domains<br>
Use this API during the SDK Initialization to indicate branded domains. For more information [Learn here](https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links)

*Example:*

```javascript
let domains = ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"];
window.plugins.appsFlyer.setOneLinkCustomDomains(domains, successC, errorC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `domains` | `String array` | String array of branded domains |
| `successC` | `function` | will trigger if the domains were sent successfully |
| `errorC` | `function` | will trigger if an error occurred |

---
##### <a id="enableFacebookDeferredApplinks"> **`enableFacebookDeferredApplinks(boolean isEnabled): void`**
support deferred deep linking from Facebook Ads<br>

**NOTE:** use this api before ```init```.<br>For more information [Learn here](https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration)

*Example:*

```javascript
window.plugins.appsFlyer.enableFacebookDeferredApplinks(true);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `isEnabled` | `boolean` | enable support deferred deep linking from Facebook Ads |

---
##### <a id="setUserEmails"> **`setUserEmails(emails, successC: void`**
Set user emails for FB Advanced Matching<br>

*Example:*

```javascript
let emails = ["foo@gmail.com", "bar@foo.com"];
window.plugins.appsFlyer.setUserEmails(emails, successC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `emails` | `String array` | String array of emails |
| `successC` | `function` | will trigger if the emails were sent successfully |

---
##### <a id="setPhoneNumber"> **`setPhoneNumber(phoneNumber, successC: void`**
Set phone number for FB Advanced Matching<br>

*Example:*

```javascript
let phoneNumber = "0548561587";
window.plugins.appsFlyer.setPhoneNumber(phoneNumber, successC);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `phoneNumber` | `String` | String phone number |
| `successC` | `function` | will trigger if the number was sent successfully |

---
##### <a id="setHost"> **`setHost(String hostPrefix, String hostName): void`**
Set custom host prefix and host name<br>

*Example:*

```javascript
let prefix = "another"
let name = "host"
window.plugins.appsFlyer.setHost(prefix, name);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `hostPrefix` | `String` | host prefix |
| `hostName` | `String` | host name |

---
##### <a id="addPushNotificationDeepLinkPath"> **`addPushNotificationDeepLinkPath(path): void`**
The addPushNotificationDeepLinkPath method provides app owners with a flexible interface for configuring how deep links are extracted from push notification payloads. for more information: [here](https://support.appsflyer.com/hc/en-us/articles/207032126-Android-SDK-integration-for-developers#core-apis-65-configure-push-notification-deep-link-resolution)
❗Important❗ addPushNotificationDeepLinkPath must be called before calling initSDK

*Example:*

```javascript
let path = ["go", "to", "this", "path"]
window.plugins.appsFlyer.addPushNotificationDeepLinkPath(path);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `path` | `String[]` | strings array of the path |

---

---
##### <a id="setResolveDeepLinkURLs"> **`setResolveDeepLinkURLs(urls): void`**
Use this API to get the OneLink from click domains that launch the app. Make sure to call this API before SDK initialization.

*Example:*

```javascript
let urls = ['clickdomain.com', 'anotherclickdomain.com'];
window.plugins.appsFlyer.setResolveDeepLinkURLs(urls);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `urls` | `String[]` | strings array of domains |

---

##### <a id="disableSKAD"> **`disableSKAD(disableSkad): void`**
enable or disable SKAD support. set True if you want to disable it!<br>
`disableSKAD` must be called before calling `initSDK` and for iOS ONLY!.

*Example:*

```javascript
appsFlyer.disableSKAD(true);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disableSkad` | `boolean` | disable or enable SKAD support |

---
##### <a id="setCurrentDeviceLanguage"> **`setCurrentDeviceLanguage(language): void`**
Set the language of the device. The data will be displayed in Raw Data Reports<br>
`setCurrentDeviceLanguage` must be called before calling `initSDK` and for iOS ONLY!.

*Example:*

```javascript
appsFlyer.setCurrentDeviceLanguage('en');
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `language` |  `string` | Set the language of the device. |

---
##### <a id="setAdditionalData"> **`setAdditionalData(additionalData): void`**
The setAdditionalData API allows you to add custom data to events sent from the SDK.<br>
Typically it is used to integrate on the SDK level with several external partner platforms.

*Example:*

```javascript
appsFlyer.setAdditionalData({"aa":"cc",
        "af":"cordova",
        "ts":195659889569,
        "revenue": 15});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `additionalData` |  `Object` | Set the language of the device. |

---
##### <a id="setPartnerData"> **`setPartnerData(partnerId, data): void`**
Allows sending custom data for partner integration purposes.

*Example:*

```javascript
appsFlyer.setPartnerData("af_int", {apps: "Flyer", cuid: "123abc"});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `partnerId` |  `String` | ID of the partner (usually suffixed with "_int"). |
| `data` |  `Object` | Customer data, depends on the integration configuration with the specific partner. |

------
##### <a id="sendPushNotificationData"> **`sendPushNotificationData(pushData): void`**
Measure and get data from push-notification campaigns.
*Example:*
 
```javascript
appsFlyer.sendPushNotificationData({apps: "Flyer", cuid: "123abc", someKey: "Some Value"});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `pushData` |  `Object` | JSON object contains the push data |

---
##### <a id="sendPushNotificationData"> **`setDisableNetworkData(disable): void`**
Measure and get data from push-notification campaigns.
*Example:*
 
```javascript
appsFlyer.setDisableNetworkData(true);
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disable` |  `boolean` | If should opt out, default to false|

---

##### <a id="setConsentData"> **`setConsentData(appsFlyerConsent): void`**
When GDPR applies to the user and your app does not use a CMP compatible with TCF v2.2, use this API to provide the consent data directly to the SDK.
The AppsFlyerConsent object has 4 parameters:

| parameter | type           | description                                                                                                                                                                     |
| ----------- |----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `isUserSubjectToGDPR` | `boolean\null` | Indicates whether GDPR regulations apply to the user (true if the user is a subject of GDPR). It also serves as a flag for compliance with relevant aspects of DMA regulations. |
| `hasConsentForDataUsage` | `boolean\null` | Indicates whether the user has consented to use their data for advertising purposes.  This can apply under GDPR, DMA, or other applicable privacy regulations.|
| `hasConsentForAdsPersonalization` | `boolean\null` | Indicates whether the user has consented to use their data for personalized advertising.  This can apply under GDPR, DMA, or other applicable privacy regulations.              |
| `hasConsentForAdStorage` | `boolean\null` | Indicates whether the user has provided consent for the storage of their advertising data. This can be relevant for GDPR, DMA, or other regulatory compliance purposes.         |

<b>Deprecated functions</b>

<s>AppsFlyerConsent.forNonGDPRUser: Indicates that GDPR doesn’t apply to the user and generates nonGDPR consent object. This method doesn’t accept any parameters.
AppsFlyerConsent.forGDPRUser: create an AppsFlyerConsent object with 2 parameters.
</s>

*Example:*

```javascript

window.plugins.appsFlyer.setConsentData(AppsFlyerConsent.forGDPRUser(true, true));
// OR
window.plugins.appsFlyer.setConsentData(AppsFlyerConsent.forNonGDPRUser());

```

---

##### <a id="enableTCFDataCollection"> **`enableTCFDataCollection(enable): void`**
instruct the SDK to collect the TCF data from the device.

| parameter | type | description                                                                            |
| ---------- |-----------------------------|----------------------------------------------------------------------------------------|
| `enable` |  `boolean` | enable/disable TCF data collection                                                     |

*Example:*

```javascript

window.plugins.appsFlyer.enableTCFDataCollection(true);

```

---

##### <a id="logAdRevenue"> **`logAdRevenue(adRevenueData, additionalParams): void`**
log ad-revenue event.

| parameter        | type     | description                                                                                                                                                                                                                                                |
|------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `adRevenueData`  | `Object` | the object must contain the following fields:<br/>monetizationNetwork: String testMonetizationNetwork<br/> mediationNetwork: MediationNetwork testMediationNetwork<br/>currencyIso4217Code: String currencyByIso4217CodeFormat <br/>revenue:double revenue |
| `additionalData` | `Object` | additional Params Data map, @Nullable                                                                                                                                                                                                                      |


*Example:*

```javascript

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


```
Here's how you use `appsFlyer.logAdRevenue` within a Cordova app:

1. Prepare the `adRevenueData` object as shown, including any additional parameters you wish to track along with the ad revenue event.
2. Call the `appsFlyer.logAdRevenue` method with the `adRevenueData` object.

By passing all the required fields in `AFAdRevenueData`, you help ensure accurate tracking within the AppsFlyer platform. This enables you to analyze your ad revenue alongside other user acquisition data to optimize your app's overall monetization strategy.

**Note:** 
The `additionalParameters` object is optional. You can add any additional data you want to log with the ad revenue event in this object. This can be useful for detailed analytics or specific event tracking later on. Make sure that the custom parameters follow the data types and structures specified by AppsFlyer in their documentation.
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
var  handleOpenURL = function(url) {
window.plugins.appsFlyer.handleOpenUrl(url);
}
```

#### <a id='dl-ul'>Universal Links in iOS
To enable Universal Links in iOS please follow the guide <a  href="https://support.appsflyer.com/hc/en-us/articles/207032266-Setting-Deeplinking-on-iOS9-using-iOS-Universal-Links">here</a>.

##### **Note**: Our plugin uses method swizzeling for

- (BOOL)application:(UIApplication *)application

continueUserActivity:(NSUserActivity *)userActivity

restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler; `

---
