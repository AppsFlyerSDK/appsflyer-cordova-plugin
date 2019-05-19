
<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="600">

# Cordova AppsFlyer plugin for Android and iOS. 

[![npm version](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk.svg)](https://badge.fury.io/js/cordova-plugin-appsflyer-sdk) [![Build Status](https://travis-ci.org/AppsFlyerSDK/cordova-plugin-appsflyer-sdk.svg?branch=master)](https://travis-ci.org/AppsFlyerSDK/cordova-plugin-appsflyer-sdk)

----------
**❗️Important** <br>
Cordova AppsFlyer plugin version **4.4.0** and higher are meant to be used with **cordova-android@7.0.0**
<br>For lower versions of cordova-android please use plugin version 4.3.3 available @ https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/tree/4.3.3

----------
🛠 In order for us to provide optimal support, we would kindly ask you to submit any issues to support@appsflyer.com

*When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , production steps, code snippets, logs, and any additional relevant information.*

----------



## Table of content

- [SDK versions](#plugin-build-for)
- [Installation](#installation)
- [Guides](#guides)
- [Setup](#setup)
- [API](#api) 
- [Demo](#demo)  


### <a id="plugin-build-for"> This plugin is built for

- iOS AppsFlyerSDK **v4.9.0**
- Android AppsFlyerSDK **v4.9.0**


## <a id="installation">📲Installation

```
$ cordova plugin add cordova-plugin-appsflyer-sdk
```

To install cordova manually check out the doc [here](/docs/Installation.md).

 ## <a id="guides"> 📖 Guides

Great installation and setup guides can be viewed [here](/docs/Guides.md).
- [init SDK Guide](/docs/Guides.md#init-sdk)
- [Deeplinking Guide](/docs/Guides.md#deeplinking)
- [Uninstall Guide](/docs/Guides.md#uninstall)


## <a id="setup"> 🚀 Setup

####  Set your App_ID (iOS only), Dev_Key and enable AppsFlyer to detect installations, sessions (app opens) and updates.  
> This is the minimum requirement to start tracking your app installs and is already implemented in this plugin. You **MUST** modify this call and provide:  
 **devKey** - Your application devKey provided by AppsFlyer.<br>
**appId**  - ***For iOS only.*** Your iTunes Application ID.


Add the following lines to your code to be able to initialize tracking with your own AppsFlyer dev key:


```javascript
document.addEventListener('deviceready', function() {

  var options = {
    devKey: '**********spwL', // your AppsFlyer devKey
    isDebug: false,
  };

  var userAgent = window.navigator.userAgent.toLowerCase();
  if (/iphone|ipad|ipod/.test( userAgent )) {
    options.appId = '123456789'; // your ios app id in app store        
  }
   
  var onSuccess = function(result) {
    console.log(result);
  };
  
  function onError(err) {
    console.log(err);
  }
  
  window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
  
}, false);
```

---


## <a id="api"> 📑 API
  
See the full [API](/docs/API.md) available for this plugin.


## <a id="demo"> 📱 Demo
  
  Check out the demo for this project [here](docs/Guides.md#demo).
