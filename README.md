
<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="600">

# Cordova AppsFlyer plugin for Android and iOS. 

[![npm version](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk.svg)](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk)
[![Build Status](https://travis-ci.org/AppsFlyerSDK/appsflyer-cordova-plugin.svg?branch=master)](https://travis-ci.org/AppsFlyerSDK/appsflyer-cordova-plugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) 
[![Downloads](https://img.shields.io/npm/dm/cordova-plugin-appsflyer-sdk.svg)](https://www.npmjs.com/package/cordova-plugin-appsflyer-sdk)

----------
**❗️Important** <br>
- Cordova AppsFlyer plugin version **4.4.0** and higher are meant to be used with **cordova-android@7.0.0** and up <br>
For lower versions of cordova-android please use plugin version 4.3.3 available @ https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/tree/4.3.3 <br>
- From version **6.1.10** the plugin uses cocoapods(NOT StaticLib) in order to support iOS app-kids Strict mode. <br>
You can read more [here](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk)
----------
🛠 In order for us to provide optimal support, we would kindly ask you to submit any issues to support@appsflyer.com

*When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , reproduction steps, code snippets, logs, and any additional relevant information.*

----------

## Table of content

- [SDK versions](#plugin-build-for)
- [V6 Breaking Changes](#breakingChanges)
- [Installation](#installation)
- [Add or Remove Strict mode for App-kids](#appKids)
- [Guides](#guides)
- [Setup](#setup)
- [API](#api) 
- [Demo](#demo)  
- [Ionic](#ionic)


### <a id="plugin-build-for"> This plugin is built for

- iOS AppsFlyerSDK **v6.2.4**
- Android AppsFlyerSDK **v6.2.0**

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
![Add Preprocessor macro](https://github.com/amit-kremer93/resources/blob/main/preprocessorMacro.png)


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


## <a id="setup"> 🚀 Setup

####  Set your App_ID (iOS only), Dev_Key and enable AppsFlyer to detect installations, sessions (app opens) and updates.  
> This is the minimum requirement to start tracking your app installs and is already implemented in this plugin. You **MUST** modify this call and provide:  
 **devKey** - Your application devKey provided by AppsFlyer.<br>
**appId**  - ***For iOS only.*** Your iTunes Application ID.<br>
**waitForATTUserAuthorization**  - ***For iOS14 only.*** Time for the sdk to wait before launch.


Add the following lines to your code to be able to initialize tracking with your own AppsFlyer dev key:


```javascript
document.addEventListener('deviceready', function() {

   window.plugins.appsFlyer.initSdk({
      devKey: 'K2***************99', // your AppsFlyer devKey
      isDebug: false,
      appId: '41*****44', // your ios appID
      waitForATTUserAuthorization: 10, //time for the sdk to wait before launch - IOS 14 ONLY!
    },
      (result) => {
        console.log(result);
      },
      (error) => {
        console.error(error);
      }
    );
  
}, false);
```
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

In case you are using Ionic framework, you have 2 options:
###  1. Using the `window` object directly
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
        });
    }
}
```

### 2 - Using Ionic native plugin
####  Ionic 4
run this commands:
**With Cordova**:
```
$ ionic cordova plugin add cordova-plugin-appsflyer-sdk
$ npm install @ionic-native/appsflyer
```
**With Capacitor**:
```
$ npm install cordova-plugin-appsflyer-sdk
$ npm install @ionic-native/appsflyer
ionic cap sync
```
Then add the following to `app.module.ts`
```
import { Appsflyer } from "@ionic-native/appsflyer/ngx";
...
providers: [
Appsflyer,
...,
]
```
and in your main ts file:
```
import { Appsflyer } from '@ionic-native/appsflyer/ngx';
import {Platform} from '@ionic/angular';

constructor(private appsflyer: Appsflyer, public platform: Platform) { 
...
this.platform.ready().then(() => {
            this.appsflyer.initSdk(options);
        });
}
```
####  Ionic 2/3
If you're using Ionic 2/3, you'd need to install a previous version of the Ionic Native dependency (notice the **@4** at the end of the npm install command):
```
$ ionic cordova plugin add cordova-plugin-appsflyer-sdk
$ npm install @ionic-native/appsflyer@4
```
Then add the following to `app.module.ts`(with no **/ngx**)
```
import { Appsflyer } from "@ionic-native/appsflyer";
...
providers: [
Appsflyer,
...,
]
```
And finally in your main ts file:
```
import { Appsflyer } from '@ionic-native/appsflyer';
```
Check out the full [API](/docs/API.md) for more information
