# Adding   cordova-plugin-appsflyer-sdk to your project

- [Installation using CLI](#installation-using-cli)
- [Native dependencies](#native-dependencies)
- [Strict mode for app-kids](#strict-mode-for-app-kids)
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

`cordova plugin add`/`cordova prepare` pulls in the native SDKs automatically; you don't add these yourself.

- **Platform engines**: Requires `cordova-android >= 13.0.0` and `cordova-ios >= 7.1.1` (declared in `plugin.xml`).
- **iOS**: CocoaPods installs the `AppsFlyerRPC` pod (pinned in `plugin.xml`'s `<podspec>` block), which pulls in `AppsFlyerFramework` transitively. **Requires an iOS deployment target of 13.0+** — `AppsFlyerRPC`'s own podspec declares this minimum, and Cordova's default (`12.0`) fails `pod install`. Set it in your app's `config.xml`: `<platform name="ios"><preference name="deployment-target" value="13.0" /></platform>`.
- **Android**: Gradle installs `com.appsflyer:af-android-sdk` via the `af-android-sdk-bom` platform BOM, plus an explicit `com.appsflyer:af-android-plugin-bridge` version pin (see `src/android/cordovaAF.gradle` for the exact pinned versions). **Building the Android side requires JDK 21.**

If you're pinning a specific SDK version yourself (e.g. in a `Podfile`/`build.gradle` override), pin `AppsFlyerRPC` on iOS and `af-android-sdk-bom` + `af-android-plugin-bridge` on Android; not the older single `AppsFlyerFramework` pod or a standalone `af-android-sdk:X.Y.Z@aar` line, both of which predate this plugin's current RPC-core architecture.

## <a id="strict-mode-for-app-kids"> Strict mode for app-kids

To build your app for kids (e.g. COPPA compliance or Google Play Families policy), set `AppsFlyerStrictMode` in your app's `config.xml`:

```xml
<preference name="AppsFlyerStrictMode" value="true" />
```

During `cordova prepare`, the plugin automatically:
- Updates iOS to `AppsFlyerRPC/Strict` (which pulls `AppsFlyerFramework/Strict`) and runs `pod install`.
- Removes the `com.google.android.gms.permission.AD_ID` permission from the prepared Android manifest.

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

3\. Copy appsflyer.js to `www/js/plugins` and reference it in `index.html`:

```html
<script type="text/javascript" src="js/plugins/appsflyer.js"></script>
```

4\. Download the source files and copy them to your project.

##### <a id="manual-installation-ios"> ****iOS:****

Copy:

-  `AppsFlyerPlugin.swift`
-  `AppsFlyerAttribution.swift`
-  `AppsFlyerX+AppController.m`

to `platforms/ios/<ProjectName>/Plugins`. Native SDK binaries come from the `AppsFlyerRPC` CocoaPods dependency; don't copy a static `libAppsFlyerLib.a`.

##### <a id="manual-installation-android"> ****Android:****

Copy `AppsFlyerPlugin.kt` to `platforms/android/app/src/main/kotlin/com/appsflyer/cordova/plugin` (create the folders).

##  <a id="remove-plugin"> Removing the Plugin:

```
$ cordova plugin remove cordova-plugin-appsflyer-sdk
```
