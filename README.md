<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="200">

# Cordova AppsFlyer plugin for Android and iOS. 

[![npm version](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk.svg)](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk) [![Build Status](https://travis-ci.org/AppsFlyerSDK/cordova-plugin-appsflyer-sdk.svg?branch=master)](https://travis-ci.org/AppsFlyerSDK/cordova-plugin-appsflyer-sdk)



## Table of content

- [Supported Platforms](#supported-platforms)
- [SDK versions](#plugin-build-for)
- [Installation using CLI](#installation-using-cli)
- [Manual installation](#manual-installation)
  - [iOS](#manual-installation-ios)
  - [Android](#manual-installation-android)
- [Usage](#usage)
 - [for pure Cordova](#usage-pure) 
 - [For Ionic](#usage-ionic1)
- [API Methods](#api-methods) 
 - [initSdk](#initSdk) 
 - [trackEvent](#trackEvent)
 - [setCurrencyCode](#setCurrencyCode)
 - [setAppUserId](#setAppUserId)
 - [setGCMProjectID](#setGCMProjectID)
 - [getAppsFlyerUID](#getAppsFlyerUID)
- [Deep linking Tracking](#deep-linking-tracking) 
 - [Android](#dl-android)
 - [iOS](#dl-ios)
- [Sample App](#sample-app)  

## <a id="supported-platforms"> Supported Platforms

- Android
- iOS 8+



### <a id="plugin-build-for"> This plugin is built for

- iOS AppsFlyerSDK **v4.5.12**
- Android AppsFlyerSDK **v4.6.1**


## <a id="installation-using-cli"> Installation using CLI:

```
$ cordova plugin add cordova-plugin-appsflyer-sdk
```
or directly from git:

```
$ cordova plugin add https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk.git
```

## <a id="manual-installation"> Manual installation:

1\. Add the following xml to your `config.xml` in the root directory of your `www` folder:
```xml
<!-- for iOS -->
<feature name="AppsFlyerPlugin">
  <param name="ios-package" value="AppsFlyerPlugin" />
</feature>
```
```xml
<!-- for Android -->
<feature name="AppsFlyerPlugin">
  <param name="android-package" value="com.appsflyer.cordova.plugin.AppsFlyerPlugin" />
</feature>
```
2\. For Android, add the following xml to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
3\. Copy appsflyer.js to `www/js/plugins` and reference it in `index.html`:
```html
<script type="text/javascript" src="js/plugins/appsflyer.js"></script>
```
4\. Download the source files and copy them to your project.

##### <a id="manual-installation-ios"> **iOS:** 
Copy:

 - `AppsFlyerPlugin.h`
 - `AppsFlyerPlugin.m`
 - `AppsFlyerTracker.h`
 - `libAppsFlyerLib.a`
to `platforms/ios/<ProjectName>/Plugins`

##### <a id="manual-installation-android"> **Android:** 

Copy `AppsFlyerPlugin.java` to `platforms/android/src/com/appsflyer/cordova/plugins` (create the folders)
        
## <a id="usage"> Usage:

#### 1\. Set your App_ID (iOS only), Dev_Key and enable AppsFlyer to detect installations, sessions (app opens) and updates.  
> This is the minimum requirement to start tracking your app installs and is already implemented in this plugin. You **MUST** modify this call and provide:  
 **-devKey** - Your application devKey provided by AppsFlyer.
**-appId**  - ***For iOS only.*** Your iTunes Application ID.



Add the following lines to your code to be able to initialize tracking with your own AppsFlyer dev key:

##### <a id="usage-pure"> **for pure Cordova:**
```javascript
document.addEventListener("deviceready", function(){
    
   var options = {
             devKey:  'xxXXXXXxXxXXXXxXXxxxx8'// your AppsFlyer devKey               
           };

    var userAgent = window.navigator.userAgent.toLowerCase();
                          
    if (/iphone|ipad|ipod/.test( userAgent )) {
        options.appId = "123456789";            // your ios app id in app store        
    }
    window.plugins.appsFlyer.initSdk(options);
}, false);
```

##### <a id="usage-ionic1"> **For Ionic 1**

```javascript
  $ionicPlatform.ready(function() {      
    
    var options = {
           devKey:  'xxXXXXXxXxXXXXxXXxxxx8'// your AppsFlyer devKey               
         };
                              
    if (ionic.Platform.isIOS()) {
        options.appId = "123456789";            // your ios app id in app store 
    }

      window.plugins.appsFlyer.initSdk(options);      
  });
```


##<a id="api-methods"> API Methods

---

##### <a id="initSdk"> **`initSdk(options, onSuccess, onError): void`**

initialize the SDK.

| parameter   | type                        | description  |
| ----------- |-----------------------------|--------------|
| `options`   | `Object`                    |   SDK configuration           |
| `onSuccess` | `(message: string)=>void` | Success callback - called after successfull SDK initialization. (optional)|
| `onError`   | `(message: string)=>void` | Error callback - called when error occurs during initialization. (optional)|

**`options`**

| name       | type    | default | description            |
| -----------|---------|---------|------------------------|
| `devKey`   |`string` |         |   [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android)    |
| `appId`    |`string` |        | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |
| `isDebug`  |`boolean`| `false` | debug mode (optional)|
| `onInstallConversionDataListener`  |`boolean`| `false` | Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](http://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](http://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data in `onSuccess` callback. 

*Example:*

```javascript
var onSuccess = function(result) {
     //handle result
};

function onError(err) {
    // handle error
}
var options = {
               devKey:  'd3Ac9qPardVYZxfWmCspwL',
               appId: '123456789',
               isDebug: false,
               onInstallConversionDataListener: true
             };
window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
```

---

##### <a id="trackEvent"> **`trackEvent(eventName, eventValues): void`** (optional)


- These in-app events help you track how loyal users discover your app, and attribute them to specific 
campaigns/media-sources. Please take the time define the event/s you want to measure to allow you 
to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `eventName` | `String`                    | custom event name, is presented in your dashboard.  See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/platform/ios/AppsFlyerTracker.h)  |
| `eventValue` | `Object`                    | event details |

*Example:*

```javascript
var eventName = "af_add_to_cart";
var eventValues = {
           "af_content_id": "id123",
           "af_currency":"USD",
           "af_revenue": "2"
           };
window.plugins.appsFlyer.trackEvent(eventName, eventValues);
```

---


##### <a id="setCurrencyCode"> **`setCurrencyCode(currencyId): void`**


| parameter   | type                  | Default     | description |
| ----------- |-----------------------|-------------|-------------|
| `currencyId`| `String`              |   `USD`     |  [ISO 4217 Currency Codes](http://www.xe.com/iso4217.php)           |

*Examples:*

```javascript
window.plugins.appsFlyer.setCurrencyCode("USD");
window.plugins.appsFlyer.setCurrencyCode("GBP"); // British Pound
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


##### <a id="setGCMProjectID"> **`setGCMProjectID(GCMProjectNumber): void`**

AppsFlyer requires a Google Project Number to enable uninstall tracking.
<a href="https://support.appsflyer.com/hc/en-us/articles/208004986-Android-Uninstall-Tracking">More Information</a>


| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `GCMProjectNumber`   | `String`                      | |


##### <a id="registerUninstall"> **`registerUninstall(token): void`** 

Enables app uninstall tracking.
<a href="https://support.appsflyer.com/hc/en-us/articles/211211963-iOS-Uninstall-Tracking">More Information</a>

| parameter   | type                        | description |
| ----------- |-----------------------------|--------------|
| `token`   | `String`                      | |


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


### <a id="deep-linking-tracking"> Deep linking Tracking

#### <a id="dl-android"> Android
In ver. 4.2.5 deeplinking metadata (scheme/host) is sent automatically

#### <a id="dl-ios"> iOS

Open in Xcode `AppDelegate.m`, add `#import "AppsFlyerTracker.h"` and add the following method under `application: openURL` :

```objective-c
[[AppsFlyerTracker sharedTracker] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
```

It appears as follows:

```objective-c
-(BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    [[AppsFlyerTracker sharedTracker] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
    return YES;
}
```

---

##Demo

This plugin has a `examples` folder with `demoA` (Angular 1)  and `demoC` (Cordova) projects bundled with it. To give it a try , clone this repo and from root a.e. `cordova-plugin-appsflyer-sdk` execute the following:

For Cordova:
```sh
npm run setup_c 
```
-  `npm run demo_c.ra` - runs Android
-  `npm run demo_c.ba` - builds Android
-  `npm run demo_c.ri` - runs iOS
-  `npm run demo_c.bi` - builds iOS


For Angular:
```sh
npm run setup_a
```
-  `npm run demo_a.ra` - runs Android
-  `npm run demo_a.ba` - builds Android
-  `npm run demo_a.ri` - runs iOS
-  `npm run demo_a.bi` - builds iOS



![demo printscreen](examples/demo_example.png?raw=true)
