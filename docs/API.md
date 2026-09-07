# API

  

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

  
  
  

The list of available methods for this plugin is described below.

### Removed in 7.0

The following methods were removed with no replacement — see [RELEASENOTES.md](../RELEASENOTES.md) for the full breaking-change list:

- `registerOnAppOpenAttribution` — folded into [`registerDeepLinkListener`](#registerDeepLink)'s `onDeepLinking` callback.
- `registerUninstall` (iOS APNs token) — no equivalent method in the new RPC schema.
- `setSharingFilter` / `setSharingFilterForAllPartners` — already deprecated pre-7.0; superseded by [`setSharingFilterForPartners`](#setSharingFilterForPartners).

Every remaining method is now **Promise-based**: `fn(args, successCallback, errorCallback)` calls became `await AppsFlyer.fn(params)`, with a single params object. Failures throw `AppsFlyerRpcError` or `AppsFlyerError` instead of invoking an error callback.

| method name                                                           | params                                                                    | description                                                                                             |
|-----------------------------------------------------------------------|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| [`init`](#initSdk)                                                    | `({devKey, appId?}): Promise<void>`                                       | Initialize the SDK                                                                                      |
| [`start`](#startSdk)                                                  | `(params?: {awaitResponse?}): Promise<void>`                              | Starts the SDK - must be called from inside `registerSessionReadyListener`'s callback                   |
| [`logEvent`](#trackEvent)                                             | `({eventName, eventValues?, awaitResponse?}): Promise<void>`              | Track rich in-app events                                                                                |
| [`registerDeepLinkListener`](#registerDeepLink)               | `({onDeepLinking}): Promise<void>`                                        | Get unified deep link data (also covers what used to be app-open attribution)                           |
| [`setCurrencyCode`](#setCurrencyCode)                                 | `({currencyCode}): Promise<void>`                                         | Set currency code                                                                                       |
| [`setCustomerUserId`](#setAppUserId)                                  | `({customerId}): Promise<void>`                                           | Set custom_user_id                                                                                      |
| [`getAppsFlyerUID`](#getAppsFlyerUID)                                 | `(): Promise<string \| null>`                                             | Get AppsFlyer’s proprietary Device ID                                                                   |
| [`anonymizeUser`](#deviceTrackingDisabled)                            | `({shouldAnonymize}): Promise<void>`                                      | Anonymize user data                                                                                     |
| [`stop`](#stopTracking)                                               | `({shouldStop}): Promise<void>`                                           | Shut down all SDK tracking                                                                              |
| [`updateServerUninstallToken`](#updateServerUninstallToken)           | `({token}): Promise<void>`                                                | (Android) Pass GCM/FCM Tokens                                                                           |
| [`setAppInviteOneLink`](#setAppInviteOneLinkID)                       | `({oneLinkId}): Promise<void>`                                            | Set AppsFlyer’s OneLink ID                                                                              |
| [`generateInviteLink`](#generateInviteLink)                           | `(params?: {parameters?, awaitResponse?}): Promise<string>`               | Generate a user-invite link                                                                             |
| [`logCrossPromoteImpression`](#trackCrossPromotionImpression)         | `({appId, campaign?, userParams?}): Promise<void>`                        | Track cross promotion impression                                                                        |
| [`logAndOpenStore`](#trackAndOpenStore)                               | `({promotedAppId, campaign?, userParams?}): Promise<void>`                | Launch the app store's app page (via Browser)                                                           |
| [`handleOpenUrl`](#handleOpenUrl)                                     | `({url, options?}): Promise<void>`                                        | **iOS only.** Forward a URL-scheme open to the SDK                                                      |
| [`handleOpenURL`](#handleOpenURL)                                     | `({url, options?}): Promise<void>`                                        | **iOS only.** Case-variant of `handleOpenUrl`, kept for hand-integrated `AppDelegate`s                  |
| [`getSdkVersion`](#getSdkVersion)                                     | `(): Promise<string>`                                                     | Get the current SDK version                                                                             |
| [`setSharingFilterForPartners`](#setSharingFilterForPartners)         | `({partners}): Promise<void>`                                             | Used by advertisers to exclude specified networks/integrated partners from getting data                 |
| [`validateAndLogInAppPurchase`](#validateAndLogInAppPurchase)         | `({purchase, additionalParameters?}): Promise<Record<string, unknown>>`   | API for server verification of in-app purchases                                                         |
| [`setUseReceiptValidationSandbox`](#setUseReceiptValidationSandbox)   | `({sandbox}): Promise<void>`                                              | In app purchase receipt validation Apple environment                                                    |
| [`setDisableCollectASA`](#disableCollectASA)                          | `({disable}): Promise<void>`                                              | **iOS**  - set the SDK to load OR not to load iAd.framework dynamically                                 |
| [`setDisableAdvertisingIdentifiers`](#setDisableAdvertisingIdentifier)| `({disable}): Promise<void>`                                              | Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).          |
| [`setOneLinkCustomDomain`](#setOneLinkCustomDomains)                  | `({domains}): Promise<void>`                                              | Set Onelink custom/branded domains                                                                      |
| [`enableFacebookDeferredApplinks`](#enableFacebookDeferredApplinks)   | `({isEnabled}): Promise<void>`                                            | support deferred deep linking from Facebook Ads                                                         |
| [`setUserEmail`](#setUserEmails)                                      | `({email}): Promise<void>`                                                | Set a single user email for FB Advanced Matching                                                        |
| [`setUserPhone`](#setPhoneNumber)                                     | `({countryCode, phoneNumber}): Promise<void>`                             | Set phone number for FB Advanced Matching                                                               |
| [`setHost`](#setHost)                                                 | `({hostPrefixName, hostName}): Promise<void>`                             | Set custom host prefix and host name                                                                    |
| [`addPushNotificationDeepLinkPath`](#addPushNotificationDeepLinkPath) | `({deepLinkPath}): Promise<void>`                                         | configure push notification deep link resolution                                                        |
| [`setResolveDeepLinkURLs`](#setResolveDeepLinkURLs)                   | `({urls}): Promise<void>`                                                 | get the OneLink from click domains                                                                      |
| [`setDisableSKAdNetwork`](#disableSKAD)                               | `({disable}): Promise<void>`                                              | disable or enable SKAdNetwork support                                                                   |
| [`setCurrentDeviceLanguage`](#setCurrentDeviceLanguage)               | `({language}): Promise<void>`                                             | Set the language of the device.                                                                         |
| [`setAdditionalData`](#setAdditionalData)                             | `({customData}): Promise<void>`                                           | Allows you to add custom data to events sent from the SDK.                                              |
| [`setPartnerData`](#setPartnerData)                                   | `({partnerId, data}): Promise<void>`                                      | Allows sending custom data for partner integration purposes.                                            |
| [`sendPushNotificationData`](#sendPushNotificationData)               | `({campaign, pid, isRetargeting?, additionalParameters?}): Promise<void>` | Measure and get data from push-notification campaigns.                                                  |
| [`setDisableNetworkData`](#setDisableNetworkData)                     | `({isDisable}): Promise<void>`                                            | Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device. |
| [`setConsentData`](#setConsentData)                                   | `({isUserSubjectToGDPR, hasConsentForDataUsage?, hasConsentForAdsPersonalization?, hasConsentForAdStorage?}): Promise<void>` | Set consent fields manually (e.g. by prompting user and collecting results). |
| [`enableTCFDataCollection`](#enableTCFDataCollection)                 | `({shouldCollect}): Promise<void>`                                        | instruct the SDK to collect the TCF data from the device.                                               |
| [`logAdRevenue`](#logAdRevenue)                                       | `({monetizationNetwork, mediationNetwork, currencyIso4217Code, revenue, additionalParameters?}): Promise<void>` | Log ad revenue event. |
| [`disableAppSetId`](#disableAppSetId)                                 | `(): Promise<void>`                                                       | **Android only** - Disables App Set ID collection (enabled by default)                                  |
| [`registerConversionListener`](#registerConversionListener)          | `({onConversionDataSuccess?, onConversionDataFail?}): Promise<void>`      | Get conversion/attribution data, replacing the old `onInstallConversionDataListener` init flag           |
| [`enableDebug`](#enableDebug)                                         | `({enabled}): Promise<void>`                                              | Toggle debug mode, replacing the old `isDebug` init flag                                                 |
| [`setUseUninstallSandbox`](#setUseUninstallSandbox)                   | `({sandbox}): Promise<void>`                                              | **iOS only** - test uninstall in the Sandbox environment, replacing the old `useUninstallSandbox` init flag |
| [`setCollectAndroidID`](#setCollectAndroidID)                         | `({isCollect}): Promise<void>`                                            | **Android only** - opt in/out of Android ID collection, replacing the old `collectAndroidID` init flag   |

  
---

##### <a id="initSdk"> **`init(params): Promise<void>`**

initialize the SDK. No longer implicitly starts tracking — see [`start`](#startSdk) below, which must be called from inside [`registerSessionReadyListener`](#registerSessionReadyListener)'s callback. Client-side arg validation is gone; failures reject with `AppsFlyerError`/`AppsFlyerRpcError`.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `params` | `{devKey: string, appId?: string}` | SDK configuration |

**`params`**

| name                              | type | description |
|-----------------------------------|---------|------------------------|
| `devKey`                          |`string` | [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android) |
| `appId`                           |`string` (optional) | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |

**Note:** these old `initSdk` flags are gone from `init`'s params — most moved to their own setter, called after `init()`:

| old `initSdk` flag | replacement |
|---------------------|-------------|
| `isDebug` | [`enableDebug({enabled})`](#enableDebug) |
| `useUninstallSandbox` | `setUseUninstallSandbox({sandbox})` |
| `collectAndroidID` | `setCollectAndroidID({isCollect})` |
| `onInstallConversionDataListener` | [`registerConversionListener`](#registerConversionListener) |
| `shouldStartSdk` | nothing to set — start is now always explicit via [`registerSessionReadyListener`](#registerSessionReadyListener) |
| `collectIMEI` | **removed, no replacement** — IMEI collection isn't part of the SDK 7 RPC surface |

See [Guides.md](./Guides.md#init-sdk) for the full init/start sequencing.

*Example:*

```javascript
try {
  await window.plugins.appsFlyer.init({
    devKey: 'd3Ac9qPardVYZxfWmCspwL',
    appId: '123456789'
  });
} catch (err) {
  // handle error
}
```

---

##### <a id="startSdk"> **`start(params?): Promise<void>`**

Starts the SDK. **Must** be called from inside [`registerSessionReadyListener`](#registerSessionReadyListener)'s callback per SDK 7's manual startup model — it is no longer called implicitly after `init`. See [Guides.md](./Guides.md#init-sdk) for the full sequencing example.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `params` | `{awaitResponse?: boolean}` (optional) | |

*Example:*

```javascript
await window.plugins.appsFlyer.init({ devKey, appId });

await window.plugins.appsFlyer.registerSessionReadyListener(() => {
  window.plugins.appsFlyer.start();
});
```
---

##### <a id="registerSessionReadyListener"> **`registerSessionReadyListener(onReady): Promise<void>`**

Registers a callback for the session-ready event. `start()` must be called from inside this callback — see [Guides.md](./Guides.md#init-sdk).

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `onReady` | `() => void` | called once the SDK session is ready to start |

---

##### <a id="registerConversionListener"> **`registerConversionListener(callbacks): Promise<void>`**

Registers a callback for conversion/attribution data, replacing the old `onInstallConversionDataListener` init flag. Call after `init()` — see [Guides.md](./Guides.md#init-sdk).

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `onConversionDataSuccess` | `(data) => void` (optional) | called with the conversion data |
| `onConversionDataFail` | `(error) => void` (optional) | called if fetching conversion data fails |

---

##### <a id="enableDebug"> **`enableDebug(params): Promise<void>`**

Toggles debug mode, replacing the old `isDebug` init flag.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `enabled` | `boolean` | whether debug logging is on |

---

##### <a id="setUseUninstallSandbox"> **`setUseUninstallSandbox(params): Promise<void>`**

**iOS only.** Tests uninstall in the Sandbox environment, replacing the old `useUninstallSandbox` init flag.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `sandbox` | `boolean` | whether to use the Sandbox environment |

---

##### <a id="setCollectAndroidID"> **`setCollectAndroidID(params): Promise<void>`**

**Android only.** Opts in/out of Android ID collection, replacing the old `collectAndroidID` init flag.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `isCollect` | `boolean` | whether to collect the Android ID |

---
##### <a id="trackEvent"> **`logEvent(params): Promise<void>`** (optional)

- These in-app events help you track how loyal users discover your app, and attribute them to specific
campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `eventName` | `string` | custom event name, is presented in your dashboard. See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h) |
| `eventValues` | `Object` (optional) | event details |
| `awaitResponse` | `boolean` (optional) | |

*Example:*

```javascript
try {
  await window.plugins.appsFlyer.logEvent({
    eventName: 'af_add_to_cart',
    eventValues: {
      'af_content_id': 'id123',
      'af_currency': 'USD',
      'af_revenue': '2'
    }
  });
} catch (err) {
  // handle error
}
```
---

##### <a id="deviceTrackingDisabled"> **`anonymizeUser(params): Promise<void>`**

**End User Opt-Out (Optional)**

AppsFlyer provides you a method to opt‐out specific users from AppsFlyer analytics. This method complies with the latest privacy requirements and complies with Facebook data and privacy policies. Default is FALSE, meaning tracking is enabled by default.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `shouldAnonymize` | `boolean` | |

*Examples:*

```javascript
await window.plugins.appsFlyer.anonymizeUser({ shouldAnonymize: true });
```

---

##### <a id="setCurrencyCode"> **`setCurrencyCode(params): Promise<void>`**

| parameter | type | Default | description |
| ----------- |-----------------------|-------------|-------------|
| `currencyCode`| `string` | `USD` | [ISO 4217 Currency Codes](http://www.xe.com/iso4217.php) |

*Examples:*

```javascript
await window.plugins.appsFlyer.setCurrencyCode({ currencyCode: 'USD' });
await window.plugins.appsFlyer.setCurrencyCode({ currencyCode: 'GBP' }); // British Pound
```

---

##### <a id="setAppUserId"> **`setCustomerUserId(params): Promise<void>`**

Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs. This ID is available in AppsFlyer CSV reports along with postbacks APIs for cross-referencing with you internal IDs.

**Note:** The ID must be set during the first launch of the app at the SDK initialization. The best practice is to call this API during the `deviceready` event, where possible.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `customerId` | `string` | |

*Example:*

```javascript
await window.plugins.appsFlyer.setCustomerUserId({ customerId: userId });
```

---

##### <a id="stopTracking"> **`stop(params): Promise<void>`**

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `shouldStop` | `boolean` |In some extreme cases you might want to shut down all SDK tracking due to legal and privacy compliance. This can be achieved with the `shouldStop` param. Once this API is invoked, our SDK will no longer communicate with our servers and stop functioning. |

*Example:*

```javascript
await window.plugins.appsFlyer.stop({ shouldStop: true });
```

In any event, the SDK can be reactivated by calling the same API, but passing `shouldStop: false`.

---

##### <a id="registerDeepLink"> **`registerDeepLinkListener(params): Promise<void>`**

Registers the unified deep-link callback. This also covers what used to be the separate `registerOnAppOpenAttribution` API — that method was removed in 7.0 and folded into `onDeepLinking` here.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `onDeepLinking` | `(data: DeepLinkData) => void` | called after receiving deep link data. `data.status` is one of `'FOUND' \| 'NOT_FOUND' \| 'ERROR'`. |

*Example:*

```javascript
await window.plugins.appsFlyer.registerDeepLinkListener({
  onDeepLinking: (data) => {
    console.log('AppsFlyer DDL ==> ' + JSON.stringify(data));
  }
});
```
---

##### <a id="updateServerUninstallToken"> **`updateServerUninstallToken(params): Promise<void>`**

(Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server.
Can be used for Uninstall Tracking.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `token` | `string` | GCM/FCM Token|

*Example:*

```javascript
await window.plugins.appsFlyer.updateServerUninstallToken({ token });
```

---

##### <a id="getAppsFlyerUID"> **`getAppsFlyerUID(): Promise<string | null>`** (Advanced)

Get AppsFlyer’s proprietary Device ID. The AppsFlyer Device ID is the main ID used by AppsFlyer in Reports and APIs.

*Example:*

```javascript
const uid = await window.plugins.appsFlyer.getAppsFlyerUID();
```

---

##### <a id="setAppInviteOneLinkID"> **`setAppInviteOneLink(params): Promise<void>`** (User Invite / Cross Promotion)

Set AppsFlyer’s OneLink ID. Setting a valid OneLink ID will result in shortened User Invite links, when one is generated. The OneLink ID can be obtained on the AppsFlyer Dashboard.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `oneLinkId` | `string` | OneLink ID |

*Example:*
```javascript
await window.plugins.appsFlyer.setAppInviteOneLink({ oneLinkId: 'Ab1C' });
```

---

##### <a id="generateInviteLink"> **`generateInviteLink(params?): Promise<string>`** (User Invite)

Allowing your existing users to invite their friends and contacts as new users to your app can be a key growth factor for your app. AppsFlyer allows you to track and attribute new installs originating from user invites within your app.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `parameters` | `Object` (optional) | Parameters for the Invite link |
| `awaitResponse` | `boolean` (optional) | |

*Example:*
```javascript
try {
  const link = await window.plugins.appsFlyer.generateInviteLink({
    parameters: {
      channel: 'gmail',
      campaign: 'myCampaign',
      customerID: '1234',
      userParams: {
        myParam: 'newUser',
        anotherParam: 'fromWeb',
        amount: 1
      }
    }
  });
  console.log(link); // Handle Generated Link Here
} catch (err) {
  console.log(err);
}
```

A complete list of supported parameters is available <a  href="https://support.appsflyer.com/hc/en-us/articles/115004480866-User-Invite-Tracking">here</a>.
Custom parameters can be passed using a `userParams{}` nested object, as in the example above.

---

##### <a id="trackCrossPromotionImpression"> **`logCrossPromoteImpression(params): Promise<void>`** (Cross Promotion)

Use this call to track an impression use the following API call. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `appId` | `string` | Promoted Application ID |
| `campaign` | `string` (optional) | Promoted Campaign |
| `userParams` | `Object` (optional) | Additional parameters to track |

*Example:*
```javascript
await window.plugins.appsFlyer.logCrossPromoteImpression({
  appId: 'com.myandroid.app',
  campaign: 'myCampaign'
});
```

For more details about Cross-Promotion tracking please see <a  href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="trackAndOpenStore"> **`logAndOpenStore(params): Promise<void>`** (Cross Promotion)

Use this call to track the click and launch the app store's app page (via Browser)

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `promotedAppId` | `string` | Promoted Application ID |
| `campaign` | `string` (optional) | Promoted Campaign |
| `userParams` | `Object` (optional) | Additional Parameters to track |

*Example:*

```javascript
await window.plugins.appsFlyer.logAndOpenStore({
  promotedAppId: 'com.myandroid.app',
  campaign: 'myCampaign',
  userParams: {
    customerID: '1234',
    myCustomParameter: 'newUser'
  }
});
```

For more details about Cross-Promotion tracking please see <a  href="https://support.appsflyer.com/hc/en-us/articles/115004481946-Cross-Promotion-Tracking">here</a>.

---

##### <a id="getSdkVersion"> **`getSdkVersion(): Promise<string>`**

Get the current SDK version

*Example:*

```javascript
const version = await window.plugins.appsFlyer.getSdkVersion();
```

---

##### <a id="setSharingFilterForPartners"> **`setSharingFilterForPartners(params): Promise<void>`**

Used by advertisers to exclude specified networks/integrated partners from getting data. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `partners` | `string[] \| null` | Array of partners that need to be excluded. Pass `null` to exclude all partners. |

*Example:*

```javascript
let partners = ["facebook_int","googleadwords_int","snapchat_int","doubleclick_int"];

await window.plugins.appsFlyer.setSharingFilterForPartners({ partners });
```

---

##### <a id="validateAndLogInAppPurchase"> **`validateAndLogInAppPurchase(params): Promise<Record<string, unknown>>`**

Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases)

> 📘Note
>
> Before 7.0 this repo had two purchase-validation methods: a deprecated `validateAndLogInAppPurchase` (V1, raw receipt fields — `publicKey`/`signature`/`purchaseData`) and `validateAndLogInAppPurchaseV2`. In 7.0 the V1 raw-receipt shape is gone entirely, and this unqualified name is now V2's successor.
>
> Generates an `af_purchase` in-app event upon successful validation. Sending this event yourself will cause duplicate event reporting.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `purchase` | `Object` | Purchase details — Android: `{purchaseType, productId, purchaseToken}`; iOS: `{purchaseType, productId, transactionId}` |
| `additionalParameters` | `Object` (optional) | Additional parameters to include with the purchase event |

*Purchase parameters:*

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `purchaseType` | `string` | `"subscription"` or `"one_time_purchase"` (see `AFPurchaseType`) |
| `productId` | `string` | The product identifier |
| `purchaseToken` | `string` | The purchase token from Google Play Store. *Android only* |
| `transactionId` | `string` | The purchase transaction Id. *iOS only* |

*Example:*

```javascript
try {
  const result = await window.plugins.appsFlyer.validateAndLogInAppPurchase({
    purchase: {
      purchaseType: AFPurchaseType.subscription,
      productId: 'my-product-id',
      transactionId: '12345-transaction-id' // iOS; use purchaseToken on Android
    },
    additionalParameters: {
      custom_param_1: 'value1',
      custom_param_2: 'value2'
    }
  });
  console.log('Purchase validation successful:', result);
} catch (error) {
  console.log('Purchase validation failed:', error);
}
```

---

##### <a id="setUseReceiptValidationSandbox"> **`setUseReceiptValidationSandbox(params): Promise<void>`**

In app purchase receipt validation Apple environment(production or sandbox)

*Example:*

```javascript
await window.plugins.appsFlyer.setUseReceiptValidationSandbox({ sandbox: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `sandbox` | `boolean` | true if In app purchase is done with sandbox |

---

##### <a id="disableCollectASA"> **`setDisableCollectASA(params): Promise<void>`**
**iOS ONLY**<br>
AppsFlyer SDK dynamically loads the Apple iAd.framework. This framework is required to record and measure the performance of Apple Search Ads in your app.<br>
If you don't want AppsFlyer to dynamically load this framework, set this property to true.<br>
*Example:*

```javascript
await window.plugins.appsFlyer.setDisableCollectASA({ disable: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disable` | `boolean` | If you don't want AppsFlyer to dynamically load iAd.framework, set this property to true |
---
##### <a id="setDisableAdvertisingIdentifier"> **`setDisableAdvertisingIdentifiers(params): Promise<void>`**
Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).<br>
*Example:*

```javascript
await window.plugins.appsFlyer.setDisableAdvertisingIdentifiers({ disable: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disable` | `boolean` |Disable collection of Apple, Google, Amazon and Open advertising ids (IDFA, GAID, AAID, OAID).|
---

##### <a id="setOneLinkCustomDomains"> **`setOneLinkCustomDomain(params): Promise<void>`**
Set Onelink custom/branded domains<br>
Use this API during the SDK Initialization to indicate branded domains. For more information [Learn here](https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links)

*Example:*

```javascript
let domains = ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"];
await window.plugins.appsFlyer.setOneLinkCustomDomain({ domains });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `domains` | `string[]` | String array of branded domains |

---
##### <a id="enableFacebookDeferredApplinks"> **`enableFacebookDeferredApplinks(params): Promise<void>`**
support deferred deep linking from Facebook Ads<br>

**NOTE:** use this api before ```init```.<br>For more information [Learn here](https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration)

*Example:*

```javascript
await window.plugins.appsFlyer.enableFacebookDeferredApplinks({ isEnabled: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `isEnabled` | `boolean` | enable support deferred deep linking from Facebook Ads |

---
##### <a id="setUserEmails"> **`setUserEmail(params): Promise<void>`**
Set a single user email for FB Advanced Matching. Callers previously passing multiple emails need to make one call per email.<br>

*Example:*

```javascript
await window.plugins.appsFlyer.setUserEmail({ email: 'foo@gmail.com' });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `email` | `string` | User email |

---
##### <a id="setPhoneNumber"> **`setUserPhone(params): Promise<void>`**
Set phone number for FB Advanced Matching. Now also requires `countryCode`.<br>

*Example:*

```javascript
await window.plugins.appsFlyer.setUserPhone({ countryCode: '972', phoneNumber: '0548561587' });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `countryCode` | `string` | Country code |
| `phoneNumber` | `string` | Phone number |

---
##### <a id="setHost"> **`setHost(params): Promise<void>`**
Set custom host prefix and host name<br>

*Example:*

```javascript
await window.plugins.appsFlyer.setHost({ hostPrefixName: 'another', hostName: 'host' });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `hostPrefixName` | `string` | host prefix |
| `hostName` | `string` | host name |

---
##### <a id="addPushNotificationDeepLinkPath"> **`addPushNotificationDeepLinkPath(params): Promise<void>`**
The addPushNotificationDeepLinkPath method provides app owners with a flexible interface for configuring how deep links are extracted from push notification payloads. for more information: [here](https://support.appsflyer.com/hc/en-us/articles/207032126-Android-SDK-integration-for-developers#core-apis-65-configure-push-notification-deep-link-resolution)
❗Important❗ addPushNotificationDeepLinkPath must be called before calling `init`

*Example:*

```javascript
let deepLinkPath = ["go", "to", "this", "path"]
await window.plugins.appsFlyer.addPushNotificationDeepLinkPath({ deepLinkPath });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `deepLinkPath` | `string[]` | strings array of the path |

---

##### <a id="setResolveDeepLinkURLs"> **`setResolveDeepLinkURLs(params): Promise<void>`**
Use this API to get the OneLink from click domains that launch the app. Make sure to call this API before SDK initialization.

*Example:*

```javascript
let urls = ['clickdomain.com', 'anotherclickdomain.com'];
await window.plugins.appsFlyer.setResolveDeepLinkURLs({ urls });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `urls` | `string[]` | strings array of domains |

---

##### <a id="disableSKAD"> **`setDisableSKAdNetwork(params): Promise<void>`**
enable or disable SKAdNetwork support. set `disable: true` if you want to disable it!<br>
`setDisableSKAdNetwork` must be called before calling `init` and for iOS ONLY!.

*Example:*

```javascript
await window.plugins.appsFlyer.setDisableSKAdNetwork({ disable: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `disable` | `boolean` | disable or enable SKAdNetwork support |

---
##### <a id="setCurrentDeviceLanguage"> **`setCurrentDeviceLanguage(params): Promise<void>`**
Set the language of the device. The data will be displayed in Raw Data Reports<br>
`setCurrentDeviceLanguage` must be called before calling `init` and for iOS ONLY!.

*Example:*

```javascript
await window.plugins.appsFlyer.setCurrentDeviceLanguage({ language: 'en' });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `language` |  `string` | Set the language of the device. |

---
##### <a id="setAdditionalData"> **`setAdditionalData(params): Promise<void>`**
The setAdditionalData API allows you to add custom data to events sent from the SDK.<br>
Typically it is used to integrate on the SDK level with several external partner platforms.

*Example:*

```javascript
await window.plugins.appsFlyer.setAdditionalData({
  customData: {
    "aa": "cc",
    "af": "cordova",
    "ts": 195659889569,
    "revenue": 15
  }
});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `customData` |  `Object` | Custom data to attach to events sent from the SDK. |

---
##### <a id="setPartnerData"> **`setPartnerData(params): Promise<void>`**
Allows sending custom data for partner integration purposes.

*Example:*

```javascript
await window.plugins.appsFlyer.setPartnerData({
  partnerId: "af_int",
  data: { apps: "Flyer", cuid: "123abc" }
});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `partnerId` |  `string` | ID of the partner (usually suffixed with "_int"). |
| `data` |  `Object` | Customer data, depends on the integration configuration with the specific partner. |

------
##### <a id="sendPushNotificationData"> **`sendPushNotificationData(params): Promise<void>`**
Measure and get data from push-notification campaigns. The old opaque `pushData` object is gone — the new schema requires specific fields.

*Example:*

```javascript
await window.plugins.appsFlyer.sendPushNotificationData({
  campaign: "myCampaign",
  pid: "myMediaSource",
  isRetargeting: true,
  additionalParameters: { someKey: "Some Value" }
});
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `campaign` |  `string` | Campaign name |
| `pid` |  `string` | Media source |
| `isRetargeting` |  `boolean` (optional) | |
| `additionalParameters` |  `Object` (optional) | Additional push-data fields |

---
##### <a id="setDisableNetworkData"> **`setDisableNetworkData(params): Promise<void>`**
Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device.
*Example:*

```javascript
await window.plugins.appsFlyer.setDisableNetworkData({ isDisable: true });
```

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `isDisable` |  `boolean` | If should opt out, default to false|

---

##### <a id="setConsentData"> **`setConsentData(params): Promise<void>`**
When GDPR applies to the user and your app does not use a CMP compatible with TCF v2.2, use this API to provide the consent data directly to the SDK.
`params` has 4 fields (pass a plain object — the `AppsFlyerConsent` class and its `forGDPRUser`/`forNonGDPRUser` factories were removed in 7.0):

| parameter | type           | description                                                                                                                                                                     |
| ----------- |----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `isUserSubjectToGDPR` | `boolean\|null` | Indicates whether GDPR regulations apply to the user (true if the user is a subject of GDPR). It also serves as a flag for compliance with relevant aspects of DMA regulations. |
| `hasConsentForDataUsage` | `boolean\|null` (optional) | Indicates whether the user has consented to use their data for advertising purposes.  This can apply under GDPR, DMA, or other applicable privacy regulations.|
| `hasConsentForAdsPersonalization` | `boolean\|null` (optional) | Indicates whether the user has consented to use their data for personalized advertising.  This can apply under GDPR, DMA, or other applicable privacy regulations.              |
| `hasConsentForAdStorage` | `boolean\|null` (optional) | Indicates whether the user has provided consent for the storage of their advertising data. This can be relevant for GDPR, DMA, or other regulatory compliance purposes.         |

*Example:*

```javascript
await window.plugins.appsFlyer.setConsentData({
  isUserSubjectToGDPR: true,
  hasConsentForDataUsage: true,
  hasConsentForAdsPersonalization: true,
  hasConsentForAdStorage: true
});
```

---

##### <a id="enableTCFDataCollection"> **`enableTCFDataCollection(params): Promise<void>`**
instruct the SDK to collect the TCF data from the device.

| parameter | type | description                                                                            |
| ---------- |-----------------------------|----------------------------------------------------------------------------------------|
| `shouldCollect` |  `boolean` | enable/disable TCF data collection                                                     |

*Example:*

```javascript
await window.plugins.appsFlyer.enableTCFDataCollection({ shouldCollect: true });
```

---

##### <a id="logAdRevenue"> **`logAdRevenue(params): Promise<void>`**
log ad-revenue event. The fields that used to live in a nested `adRevenueData` object are now top-level params; `additionalParameters` moved from a second function argument into the same object.

| parameter        | type     | description                                                                                                                                                                                                                                                |
|------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `monetizationNetwork`  | `string` | Monetization network name |
| `mediationNetwork` | `string` | See `MediationNetwork` in `constants.ts` |
| `currencyIso4217Code` | `string` | Currency in ISO 4217 format |
| `revenue` | `number` | Revenue amount |
| `additionalParameters` | `Object` (optional) | additional Params Data map |


*Example:*

```javascript
let mediationNetwork = MediationNetwork.TOPON;

await window.plugins.appsFlyer.logAdRevenue({
    monetizationNetwork: 'testMonetizationNetwork',
    mediationNetwork: mediationNetwork,
    currencyIso4217Code: 'USD',
    revenue: 15.0,
    additionalParameters: {
        'additionalKey1':'additionalValue1',
        'additionalKey2':'additionalValue2'
    }
});
```

By passing all the required fields, you help ensure accurate tracking within the AppsFlyer platform. This enables you to analyze your ad revenue alongside other user acquisition data to optimize your app's overall monetization strategy.

**Note:**
The `additionalParameters` object is optional. You can add any additional data you want to log with the ad revenue event in this object. This can be useful for detailed analytics or specific event tracking later on. Make sure that the custom parameters follow the data types and structures specified by AppsFlyer in their documentation.
---

##### <a id="disableAppSetId"> **`disableAppSetId(): Promise<void>`**
Disables App Set ID collection (enabled by default). Please look on [App Set ID official documentation](https://developer.android.com/identity/app-set-id)

*Example:*

```javascript
await window.plugins.appsFlyer.disableAppSetId();
```

---

##### <a id="handleOpenUrl"> **`handleOpenUrl(params): Promise<void>`**
**iOS only.** Forward a URL-scheme open to the SDK. See [Deep linking Tracking](#deep-linking-tracking) below for the integration context.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `url` | `string` | The opened URL |
| `options` | `Object` (optional) | Open-URL options, if any |

*Example:*

```javascript
await window.plugins.appsFlyer.handleOpenUrl({ url });
```

---

##### <a id="handleOpenURL"> **`handleOpenURL(params): Promise<void>`**
**iOS only.** Case-variant of [`handleOpenUrl`](#handleOpenUrl), kept as a distinct method for hand-integrated `AppDelegate`s. Same param shape.

| parameter | type | description |
| ----------- |-----------------------------|--------------|
| `url` | `string` | The opened URL |
| `options` | `Object` (optional) | Open-URL options, if any |

*Example:*

```javascript
await window.plugins.appsFlyer.handleOpenURL({ url });
```

---

### <a id="deep-linking-tracking"> Deep linking Tracking

  

#### <a id="dl-android"> Android
In ver. >4.2.5 deeplinking metadata (scheme/host) is sent automatically

#### <a id="dl-ios"> iOS URL Types
Add the following lines to your code to be able to track deeplinks with AppsFlyer attribution data:
for pure Cordova - add a function 'handleOpenUrl' to your root, and call our SDK as shown:

```javascript
await window.plugins.appsFlyer.handleOpenUrl({ url });
```

It appears as follows:

```javascript
var handleOpenURL = async function(url) {
  await window.plugins.appsFlyer.handleOpenUrl({ url });
}
```

You will get the deep link information via [`registerDeepLinkListener`](#registerDeepLink)'s `onDeepLinking` callback.

#### <a id='dl-ul'>Universal Links in iOS
To enable Universal Links in iOS please follow the guide <a  href="https://support.appsflyer.com/hc/en-us/articles/207032266-Setting-Deeplinking-on-iOS9-using-iOS-Universal-Links">here</a>.

##### **Note**: Our plugin uses method swizzeling for

- (BOOL)application:(UIApplication *)application

continueUserActivity:(NSUserActivity *)userActivity

restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler; `

---
