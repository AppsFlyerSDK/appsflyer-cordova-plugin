# Cordova Appsflyer Plugin Guides

<img src="https://massets.appsflyer.com/wp-content/uploads/2016/06/26122512/banner-img-ziv.png"  width="300">

## Table of content

- [Init SDK](#init-sdk)
- [DeepLinking](#deeplinking)
    - [Deferred Deep Linking (Get Conversion Data)](#deferred-deep-linking)
    - [Direct Deeplinking](#handle-deeplinking)
    - [Android Deeplink Setup](#android-deeplink)
    - [iOS Deeplink Setup](#ios-deeplink)
- [Uninstall](#uninstall)
    - [Android Uninstall Setup](#android-uninstall)
    - [iOS Uninstall Setup](#ios-uninstall)
- [Demo](#demo)


##  <a id="init-sdk"> Init SDK
    
To initialize the AppsFlyer SDK you need to call `initSdk()`. To see a full list of the `options` check our the API doc [here](./API.md#initSdk). 
    
Example:
    
    
```javascript
var onSuccess = function(result) {
// handle result  
};

function onError(err) {
// handle error
}

var options = {
    devKey: 'd3********wL',
    appId: '1******9',
    isDebug: false,
};

window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
```


##  <a id="deeplinking"> Deep Linking
    
![alt text](https://massets.appsflyer.com/wp-content/uploads/2018/03/21101417/app-installed-Recovered.png "")


#### The 2 Deep Linking Types:
Since users may or may not have the mobile app installed, there are 2 types of deep linking:

1. Deferred Deep Linking - Serving personalized content to new or former users, directly after the installation. 
2. Direct Deep Linking - Directly serving personalized content to existing users, which already have the mobile app installed.

For more info please check out the [OneLink™ Deep Linking Guide](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#Intro).

###  <a id="deferred-deep-linking"> 1. Deferred Deep Linking (Get Conversion Data)

Check out the deferred deeplinkg guide from the AppFlyer knowledge base [here](https://support.appsflyer.com/hc/en-us/articles/207032096-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deeplinking-#Introduction)

Code Sample to handle the conversion data:

```javascript
function onSuccess(result) {
    var conversionData = JSON.parse(result);

    if (conversionData.data.is_first_launch === true) {
    
        if(conversionData.data.af_status === 'Non-organic') {
        
            var media_source = conversionData.data.media_source;
            var campaign = conversionData.data.campaign;
            
            console.log('This is a Non-Organic install. Media source: ' + media_source + ' Campaign: ' + campaign);
            
        } else if(af_status === 'Organic'){
            console.log('Organic Install');
        }

    } else if (conversionData.data.is_first_launch === false) {
        // Not first launch 
    }
}

function onError(err) {
    console.log(err);
}

var options = {
    devKey:  'K2aMGPY3SkC9WckYUgHJ99',
    isDebug: true,
    appId: "4166357985",
    onInstallConversionDataListener: true  // required for get conversion data             
};

window.plugins.appsFlyer.initSdk(options , onSuccess , onError);
```




###  <a id="handle-deeplinking"> 2. Direct Deeplinking
    
When a deeplink is clicked on the device the AppsFlyer SDK will return the link in the [onAppOpenAttribution](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#deep-linking-data-the-onappopenattribution-method-) method.



```javascript
window.plugins.appsFlyer.registerOnAppOpenAttribution(function(res) {

    console.log(res);
    var deeplinkData = JSON.parse(res);
    
    if(deeplinkData.type === 'onAppOpenAttribution'){
    
        var link = deeplinkData.data.link;
        console.log(link);
        // redirect here
        
    } else {
        console.log('onAppOpenAttribution error');
    }
}, 
function onAppOpenAttributionError(err){
    console.log(err);
});

```


###  <a id="android-deeplink"> Android Deeplink Setup
    
    
    
#### URI Scheme
In your app’s manifest add the following intent-filter to your relevant activity:
```xml 
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="your unique scheme" />
</intent-filter>
```


#### App Links
For more on App Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/115005314223-Deep-Linking-Users-with-Android-App-Links#what-are-android-app-links).


###  <a id="ios-deeplink"> iOS Deeplink Setup
For more on Universal Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#setups-universal-links).
    
Essentially, the Universal Links method links between an iOS mobile app and an associate website/domain, such as AppsFlyer’s OneLink domain (xxx.onelink.me). To do so, it is required to:

1. Configure OneLink sub-domain and link to mobile app (by hosting the ‘apple-app-site-association’ file - AppsFlyer takes care of this part in the onelink setup on your dashboard)
2. Configure the mobile app to register approved domains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>com.apple.developer.associated-domains</key>
        <array>
            <string>applinks:test.onelink.me</string>
        </array>
    </dict>
</plist>
```


##  <a id="uninstall"> Uninstall Measurement

###  <a id="android-uninstall"> Android Uninstall Setup
    
For more info on Android Uninstall setup check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/210289286-Uninstall-Measurement#android-uninstall-android-uninstall-measurement).   


A third party plugin is required to fetch the token and pass it to AppsFlyer. <br>
A known plugin is [cordova-plugin-firebase](https://arnesson.github.io/cordova-plugin-firebase/).

Set-up Steps:<br>
1 . Add the plugin -  `cordova plugin add cordova-plugin-firebase --save`<br>
2. Download the google-services.json from firebase, and place them in the root folder of your cordova project<br>
3. Send the token to AppsFlyer by calling `updateServerUninstallToken`.<br>

```javascript
window.plugins.appsFlyer.initSdk(options , onSuccess , onError);

var senderID = "52*******84";
window.plugins.appsFlyer.enableUninstallTracking(senderID, onSuccess, onError);


window.FirebasePlugin.onTokenRefresh(function(token) {
    // send the token to AppsFlyer 
    window.plugins.appsFlyer.updateServerUninstallToken(token);
}, function(error) {
    console.error(error);
});
   
```

###  <a id="ios-uninstall"> iOS Uninstall Setup
    
##### Option 1 - Send the token to AppsFlyer natively

Code sample for Classes/AppDelegate.m:

```objectivec
#import "AppDelegate.h"
#import "MainViewController.h"
#import "AppsFlyerPlugin.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    self.viewController = [[MainViewController alloc] init];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[AppsFlyerTracker sharedTracker] registerUninstall:deviceToken];
}


@end
```    
    
##### Option 2 - Pass the token to AppsFlyer in the js code

Note : If you use this method you will need to collect the APNs token using a third party platform of your choice. 

```javascript
window.plugins.appsFlyer.registerUninstall("token");
```


##  <a id="demo"> Demo


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

![demo printscreen](../examples/demo_example.png?raw=true)
