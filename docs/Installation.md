# Adding   cordova-plugin-appsflyer-sdk to your project

- [Installation using CLI](#installation-using-cli)
- [Manual installation](#manual-installation)
  - [iOS](#manual-installation-ios)
  - [Android](#manual-installation-android)
- [Removing the Plugin](#remove-plugin)

##  <a id="installation-using-cli"> Installation using CLI:

directly from git branch:

```
$ cordova plugin add https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk.git
```

For Google Install referrer support:

Open the build.gradle file for your application. Make sure that the repositories section includes a maven section with the "https://maven.google.com" endpoint. For example:

```
allprojects {
  repositories {
    jcenter()
    maven {
      url "https://maven.google.com"
    }
  }
}
```

##  <a id="manual-installation"> Manual installation:
  
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

Inside the `<aplication>` tag,  add the following receiver:

```xml
<receiver android:exported="true"  android:name="com.appsflyer.MultipleInstallBroadcastReceiver">
<intent-filter>
<action android:name="com.android.vending.INSTALL_REFERRER" />
</intent-filter>
</receiver>
```



3\. Copy appsflyer.js to `www/js/plugins` and reference it in `index.html`:

```html
<script type="text/javascript" src="js/plugins/appsflyer.js"></script>
```

4\. Download the source files and copy them to your project.

##### <a id="manual-installation-ios"> ****iOS:****

Copy:

-  `AppsFlyerPlugin.h`
-  `AppsFlyerPlugin.m`
-  `AppsFlyerCrossPromotionHelper.h`
-  `AppsFlyerLib.h`
-  `AppsFlyerLinkGenerator.h`
-  `AppsFlyerShareInviteHelper.h`
-  `AppsFlyerX+AppController.h`
-  `AppsFlyerX+AppController.m`
-  `libAppsFlyerLib.a`
-  `AppsFlyerAttribution.h`
-  `AppsFlyerAttribution.m`

to `platforms/ios/<ProjectName>/Plugins`

##### <a id="manual-installation-android"> ****Android:****

Copy `AppsFlyerPlugin.java` to `platforms/android/src/com/appsflyer/cordova/plugins` (create the folders)

##  <a id="remove-plugin"> Removing the Plugin:

```
$ cordova plugin remove cordova-plugin-appsflyer-sdk
```
