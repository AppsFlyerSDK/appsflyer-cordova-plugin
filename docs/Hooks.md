# Hooks

The plugin uses Cordova lifecycle hooks to automate build settings and native dependency management during `cordova prepare`.

## Automated hooks

These hooks are registered in `plugin.xml` and run automatically on `after_prepare`. You do not need to copy them or configure them manually:

- **`af_strict_mode.js`**: Runs after prepare on both iOS and Android. When `<preference name="AppsFlyerStrictMode" value="true" />` is set in `config.xml`:
  - **iOS:** Switches the CocoaPods dependency to `AppsFlyerRPC/Strict` (which pulls `AppsFlyerFramework/Strict`) and runs `pod install`.
  - **Android:** Removes the `com.google.android.gms.permission.AD_ID` permission from the prepared `AndroidManifest.xml`.
- **`af_set_swift_version.js`**: Runs on `after_prepare` for iOS. Sets `SWIFT_VERSION = 5.0` in the generated Xcode project if the project does not already define one.

## Disable AppDelegate swizzling

The plugin resolves deep links through AppDelegate swizzling by default. To turn that off, add the `AFSDK_DISABLE_APP_DELEGATE=1` preprocessor macro in Xcode build settings (Preprocessor Macros / `GCC_PREPROCESSOR_DEFINITIONS`).

After you disable swizzling, wire deep links yourself in `AppDelegate` (see [Guides.md](./Guides.md#ios-deeplink)).
