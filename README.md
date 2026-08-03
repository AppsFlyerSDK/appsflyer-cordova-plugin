
  
<img src="https://raw.githubusercontent.com/AppsFlyerSDK/appsflyer-capacitor-plugin/main/assets/AFLogo_primary.png"  width="600">  
  
# Cordova AppsFlyer plugin for Android and iOS.   
[![npm version](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk.svg)](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk)  
[![Build Status](https://travis-ci.org/AppsFlyerSDK/appsflyer-cordova-plugin.svg?branch=master)](https://travis-ci.org/AppsFlyerSDK/appsflyer-cordova-plugin)  
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)   
[![Downloads](https://img.shields.io/npm/dm/cordova-plugin-appsflyer-sdk.svg)](https://www.npmjs.com/package/cordova-plugin-appsflyer-sdk)  
  ----------  
🛠 In order for us to provide optimal support, please contact AppsFlyer support through the Customer Assistant Chatbot for assistance with troubleshooting issues or product guidance. </br>
To do so, please follow [this article](https://support.appsflyer.com/hc/en-us/articles/23583984402193-Using-the-Customer-Assistant-Chatbot)
  
----------  
###  <a id="capacitornote"> <img src="https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_capacitor_icon_130703.png"  width="30">    <img src="https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_capacitor_icon_130703.png"  width="30"> ⚠️ Note for Capacitor users  ⚠️  <img src="https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_capacitor_icon_130703.png" width="30">  <img src="https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_capacitor_icon_130703.png"  width="30">  <br>  
**Please check out our brand new [Capacitor plugin](https://github.com/AppsFlyerSDK/appsflyer-capacitor-plugin).** <br>  
This plugin is not 100% compatible for use with Capacitor! To use this plugin with Capacitor, you have to make changes and customize the code by yourself. (Feel free to fork the project)

----------  
**❗️Important** <br>  
- Cordova AppsFlyer plugin version **4.4.0** and higher are meant to be used with **cordova-android@7.0.0** and up <br>  
For lower versions of cordova-android please use plugin version 4.3.3 available @ https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/tree/4.3.3 <br>  
- From version **6.1.10** the plugin uses cocoapods(NOT StaticLib) in order to support iOS app-kids Strict mode. <br>  
You can read more [here](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk)
- From version **6.10.2** the plugin requires using the implementation 'org.jetbrains.kotlin:kotlin-stdlib:1.6.20' in Android.
- From version **6.14.3** the plugin requires Target version 12 and higher in iOS.
- From version **6.15.11** the plugin requires adding the value '/usr/lib/swift' to Build Settings 'RunPath Search Paths' key in iOS.
----------  

  
## Table of content  
  
- [SDK versions](#plugin-build-for)  
- [V7 Breaking Changes](#v7BreakingChanges)  
- [Migration guide (v6 → v7)](/docs/MIGRATION.md)  
- [V6 Breaking Changes](#breakingChanges)  
- [Installation](#installation)  
- [Add or Remove Strict mode for App-kids](#appKids)  
- [Guides](#guides)  
- [Setup](#setup)  
- [API](#api)   
- [Demo](#demo)    
- [Ionic](#ionic)  
  
  
### <a id="plugin-build-for"> This plugin is built for  
  
- iOS AppsFlyerSDK **v7.0.1** (via CocoaPods: `AppsFlyerFramework` + `AppsFlyerRPC`)  
- Android AppsFlyerSDK **v7.0.1** (via Gradle BOM: `af-android-sdk-bom` + `af-android-plugin-bridge`)

### <a id="v7BreakingChanges"> ❗v7 Breaking Changes

Version **7.0.1** is a major release. Read the full **[v6 → v7 migration guide](/docs/MIGRATION.md)** before upgrading.

**Summary:**

| Area | v6 | v7 |
|------|----|----|
| Native bridge | Per-method Cordova actions | Single **`executeRpc`** action (JSON-RPC plugin bridge) |
| `initSdk` options | Many flags (`isDebug`, listeners, `shouldStartSdk`, …) | **Only `devKey` and `appId`** — use dedicated APIs for everything else |
| Start flow | `initSdk` then `startSdk()` | `initSdk` → config → listeners → **`registerSessionReadyListener`** → `startSdk()` |
| Deep linking | `registerOnAppOpenAttribution` + init flags | **`registerDeepLink`** with unified `onDeepLinking` (`found` / `failure` / `notFound`) |
| Conversion data | `onInstallConversionDataListener: true` in init | **`registerConversionDataListener(success, error)`** |
| Debug mode | `isDebug` in init | **`setDebugLog(true)`** after init |
| User PII | `setUserEmails`, `setPhoneNumber` | **`setUserEmail`, `setUserPhone`, …** (hashed on-device) |
| Sharing filter | `setSharingFilter`, `setSharingFilterForAllPartners` | **`setSharingFilterForPartners` only** |

**iOS:** Plugin native code is now **Swift** + CocoaPods (`AppsFlyerFramework` **7.0.1**, `AppsFlyerRPC` **7.0.1**). Run Path Search Paths must include `/usr/lib/swift`.

**Android:** Uses Gradle BOM **`com.appsflyer:af-android-sdk-bom:7.0.1`** with `af-android-plugin-bridge`.

### <a id="breakingChanges"> ❗v6.15.11 Breaking Changes

iOS platform:
The plugin requires adding the value '/usr/lib/swift' to Build Settings 'RunPath Search Paths' key in iOS, Otherwise there might be some compilation errors.
  
### <a id="breakingChanges"> ❗v6.14.3 Breaking Changes  

Android platform: 
In order to receive data regarding install-referrer from AppGallery now, there is a need to add implementation to the gradle file. <br>
following the instructions in [this](https://dev.appsflyer.com/hc/docs/install-android-sdk#huawei-install-referrer) link. <br>
please follow also these Cordova doc guidlines [here](https://cordova.apache.org/docs/en/11.x/guide/platforms/android/#extending-buildgradle).


### <a id="breakingChanges"> ❗v6 Breaking Changes  
  
We have renamed the following APIs:  
  
| Old API | New API |  
|---------|---------|  
|trackEvent      |  logEvent|  
|stopTracking      |  Stop|  
|trackCrossPromotionImpression |  logCrossPromotionImpression|  
|trackAndOpenStore      |  logCrossPromotionAndOpenStore|  
|setDeviceTrackingDisabled      |  anonymizeUser|  
  
  
## <a id="installation">📲Installation  
  
```  
$ cordova plugin add cordova-plugin-appsflyer-sdk  
```  
To install cordova manually check out the doc [here](/docs/Installation.md).  
  
> **_NOTE:_** for Ionic installation see [this](#ionic) section  

  
## ⚠️ Adding AD_ID permission for Android ⚠️
In v6.8.0 of the AppsFlyer SDK, we added the normal permission `com.google.android.gms.permission.AD_ID` to the SDK's AndroidManifest, 
to allow the SDK to collect the Android Advertising ID on apps targeting API 33.
If your app is targeting children, you need to revoke this permission to comply with Google's Data policy.
You can read more about it [here](https://dev.appsflyer.com/hc/docs/install-android-sdk#the-ad_id-permission). </br>

## <a id="appKids">👨‍👩‍👧‍👦 Add or Remove Strict mode for App-kids  
Starting from version **6.1.10** iOS SDK comes in two variants: **Strict** mode and **Regular** mode. Please read more [here](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk)  
***Change to Strict mode***<br>  
After you [installed](#installation) the AppsFlyer plugin, go to the `ios` folder inside `platform` folder:  
```  
cd platform/ios  
```  
open the `Podfile` and replace `pod 'AppsFlyerFramework', '6.1.1'` with `pod 'AppsFlyerFramework/Strict', '6.1.1'`  
  
Run `pod install` inside the `ios` folder  
  
inside xcode, go to your target and define Preprocessor Macro `AFSDK_NO_IDFA=1`  
![Add Preprocessor macro](https://github.com/amit-kremer93/resources/blob/main/preprocessorMacro.png) <br>  
* You can add the Preprocessor Macro using our [Hooks](/docs/Hooks.md).  
  
***Change to Regular mode***<br>  
Go to the `ios` folder inside `platform` folder:  
```  
cd platform/ios  
```  
open the `Podfile` and replace `pod 'AppsFlyerFramework/Strict', '6.1.1'` with `pod 'AppsFlyerFramework', '6.1.1'`  
  
Run `pod install` inside the `ios` folder  
  
inside xcode, go to your target and remove the Preprocessor Macro `AFSDK_NO_IDFA=1`  
  
  ## <a id="guides"> 📖 Guides  
  
Great installation and setup guides can be viewed [here](/docs/Guides.md).  
- [init SDK Guide](/docs/Guides.md#init-sdk)  
- [Deeplinking Guide](/docs/Guides.md#deeplinking)  
- [Uninstall Guide](/docs/Guides.md#uninstall)  
- [Set plugin for IOS 14](/docs/Guides.md#ios14)  
- [Send SKAN postback copies for IOS 15](/docs/Guides.md#skanPostback)  
  
  
## <a id="setup"> 🚀 Setup  
  
####  Set your **devKey** (required) and **appId** (iOS only), then follow the SDK 7 lifecycle: initialize → configure → register listeners → wait for session ready → start.  
  
 **devKey** - Your application devKey provided by AppsFlyer.<br>  
**appId**  - ***For iOS only.*** Your iTunes Application ID.<br>  
  
Add the following to initialize tracking with your AppsFlyer dev key:  
  
  
```javascript  
document.addEventListener('deviceready', function() {  
  
  var af = window.plugins.appsFlyer;

  af.initSdk({
    devKey: 'K2***************99',
    appId: '41*****44' // iOS only
  }, function () {
    af.setDebugLog(false);
    af.registerDeepLink(function (res) { console.log('Deep link:', res); });
    af.registerConversionDataListener(function (gcd) { console.log('GCD:', gcd); }, console.error);
    af.registerSessionReadyListener(function () {
      af.startSdk(function (result) { console.log(result); }, console.error);
    });
  }, console.error);

}, false);  
```  

See the **[v6 → v7 migration guide](/docs/MIGRATION.md)** if upgrading from plugin v6.
---  
  
  
## <a id="api"> 📑 API  
  See the full [API](/docs/API.md) available for this plugin.  
  
  
## <a id="demo"> 📱 Demo  
Check out the demo for this project [here](docs/Guides.md#demo).<br>  
There is 1 demo project called ```demoC```, run ```npm run setup_c``` in the appsflyer-cordova-plugin folder and then open the ios project in Xcode to see implementation for IOS 14.<br>  
Check out our Sample-App  **Let's cook!** [here](https://github.com/AppsFlyerSDK/appsflyer-cordova-app) if you want to implement our SDK inside React-Cordova app  
## <a id="ionic"> 📍 Ionic  
***NOTICE!*** In AppsFlyer Cordova plugin version 6.x.x we replaced the word ``track`` with ``log`` from all our api but Ionic-Navite Appsflyer plugin still uses ``track``<br>  
So the latest version that can work with Ionic-Native for now is **5.4.30**<br>  
  
###  Using the `window` object directly  
Install the cordova plugin:  
```  
$ ionic cordova plugin add cordova-plugin-appsflyer-sdk  
```  
In your main ts file, declare a window variable:  
```javascript  
declare var window;  
```  
Now you can use the AppsFlyer plugin directly from cordova:  
```javascript  
import {Component} from '@angular/core';  
import {Platform} from '@ionic/angular';  
  
declare var window;  
...  
export class HomePage {  
  constructor(public platform: Platform) {  
  this.platform.ready().then(() => {  
  window.plugins.appsFlyer.initSdk(options, success, error);  
 }); }}  
```  
  

Check out the full [API](/docs/API.md) for more information
