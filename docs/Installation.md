# Adding   cordova-plugin-appsflyer-sdk to your project

- [Installation using CLI](#installation-using-cli)
- [Native dependencies](#native-dependencies)
- [Manual installation](#manual-installation)
  - [iOS](#manual-installation-ios)
  - [Android](#manual-installation-android)
- [Removing the Plugin](#remove-plugin)

##  <a id="installation-using-cli"> Installation using CLI:

directly from git branch:

```
$ cordova plugin add https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk.git
```

##  <a id="native-dependencies"> Native dependencies

`cordova plugin add`/`cordova prepare` pulls in the native SDKs automatically — you don't add these yourself.

- **iOS**: CocoaPods installs the `AppsFlyerRPC` pod (pinned in `plugin.xml`'s `<podspec>` block), which pulls in `AppsFlyerFramework` transitively. **Requires an iOS deployment target of 13.0+** — `AppsFlyerRPC`'s own podspec declares this minimum, and Cordova's default (`12.0`) fails `pod install`. Set it in your app's `config.xml`: `<platform name="ios"><preference name="deployment-target" value="13.0" /></platform>`.
- **Android**: Gradle installs `com.appsflyer:af-android-sdk` via the `af-android-sdk-bom` platform BOM, plus an explicit `com.appsflyer:af-android-plugin-bridge` version pin (see `src/android/cordovaAF.gradle` for the exact pinned versions).

If you're pinning a specific SDK version yourself (e.g. in a `Podfile`/`build.gradle` override), pin `AppsFlyerRPC` on iOS and `af-android-sdk-bom` + `af-android-plugin-bridge` on Android — not the older single `AppsFlyerFramework` pod or a standalone `af-android-sdk:X.Y.Z@aar` line, both of which predate this plugin's current RPC-core architecture.

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
