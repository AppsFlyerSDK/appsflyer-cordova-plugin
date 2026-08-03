# Migration guide: Cordova plugin v6 → v7

This guide covers breaking changes when upgrading from **cordova-plugin-appsflyer-sdk v6.x** to **v7.0.1**, which ships with **AppsFlyer Android SDK 7.0.1** and **AppsFlyer iOS SDK 7.0.1**.

For API details see [API.md](./API.md). For setup examples see [Guides.md](./Guides.md).

---

## Overview

Version 7 is a **major release** with two layers of change:

1. **Native SDK 7.x** — new initialization lifecycle, unified deep linking, hashed PII APIs, and other SDK-level breaking changes.
2. **Cordova plugin architecture** — all JavaScript calls are routed through a single native **`executeRpc`** entry point backed by the AppsFlyer plugin bridge (`AppsFlyerRpcHandler` on Android, `AppsFlyerRPC` on iOS).

The public JavaScript API surface is largely preserved, but **how you initialize the SDK and register listeners has changed**.

---

## Upgrade steps

1. Update the plugin:

   ```bash
   cordova plugin remove cordova-plugin-appsflyer-sdk
   cordova plugin add cordova-plugin-appsflyer-sdk@7.0.1
   ```

2. Rebuild native projects:

   ```bash
   cordova platform rm android ios
   cordova platform add android ios
   ```

3. On **iOS**, run `pod install` in `platforms/ios` (Cordova may do this automatically). The plugin now requires two CocoaPods: `AppsFlyerFramework` **7.0.1** and `AppsFlyerRPC` **7.0.1**.

4. Refactor your integration using the sections below — especially **Initialization** and **Deep linking**.

---

## Architecture: RPC-based native bridge

| v6 | v7 |
|----|-----|
| Each JS method maps to its own Cordova native action (`initSdk`, `logEvent`, …) | All methods go through one Cordova action: **`executeRpc`** |
| Android: direct `AppsFlyerLib` calls in Java | Android: JSON-RPC via `af-android-plugin-bridge` |
| iOS: Objective-C `AppsFlyerPlugin.m` + vendored headers | iOS: Swift `AppsFlyerPlugin.swift` + CocoaPods (`AppsFlyerFramework` + `AppsFlyerRPC`) |
| Android: `com.appsflyer:af-android-sdk:X@aar` | Android: BOM `com.appsflyer:af-android-sdk-bom:7.0.1` + `af-android-plugin-bridge` |

You do **not** call `executeRpc` from application code — it is internal to the plugin. Your app continues to use `window.plugins.appsFlyer.*` as before.

---

## Initialization (breaking change)

### v6 pattern (removed)

```javascript
window.plugins.appsFlyer.initSdk({
  devKey: 'YOUR_DEV_KEY',
  appId: 'YOUR_APP_ID',           // iOS only
  isDebug: true,
  onInstallConversionDataListener: true,
  onDeepLinkListener: true,
  shouldStartSdk: false,
  waitForATTUserAuthorization: 10 // iOS 14+
}, onSuccess, onError);

window.plugins.appsFlyer.startSdk();
```

Options such as `isDebug`, `onInstallConversionDataListener`, `onDeepLinkListener`, `shouldStartSdk`, `waitForATTUserAuthorization`, `collectIMEI`, and `collectAndroidID` are **no longer read** from `initSdk`. Use dedicated APIs instead.

### v7 pattern (required)

```javascript
document.addEventListener('deviceready', function () {
  var af = window.plugins.appsFlyer;

  // 1. Initialize — only devKey and appId are forwarded to native SDK
  af.initSdk({ devKey: 'YOUR_DEV_KEY', appId: 'YOUR_APP_ID' }, function () {
    console.log('SDK initialized');

    // 2. Post-init configuration
    af.setDebugLog(true);

    // 3. Register listeners (before start)
    af.registerDeepLink(onDeepLink);
    af.registerConversionDataListener(onConversionSuccess, onConversionError);

    // 4. Wait for session ready, then start
    af.registerSessionReadyListener(function () {
      af.startSdk(onStartSuccess, onStartError);
    });
  }, function (err) {
    console.error('initSdk failed', err);
  });
}, false);
```

### Recommended call order

| Step | API | Notes |
|------|-----|-------|
| 1 | `initSdk({ devKey, appId })` | **Only** these two fields are sent to native |
| 2 | Config APIs | `setDebugLog`, `disableSKAD`, `setCollectAndroidID`, etc. |
| 3 | `registerDeepLink(callback)` | Unified deep link / UDL — call before or right after init |
| 4 | `registerConversionDataListener(success, error)` | Replaces `onInstallConversionDataListener: true` |
| 5 | `registerSessionReadyListener(callback)` | **New** — session must be ready before start |
| 6 | `startSdk(successCB, errorCB)` | Optional callbacks; pass `awaitResponse` internally when callbacks are provided |

---

## Deep linking (breaking change)

| Removed (v6) | Replacement (v7) |
|--------------|------------------|
| `registerOnAppOpenAttribution(success, error)` | `registerDeepLink(callback)` |
| `onAppOpenAttribution` / `onAppOpenAttributionFailure` callbacks | Unified `onDeepLinking` with `status`: `found` \| `failure` \| `notFound` |
| `onDeepLinkListener: true` in `initSdk` options | `registerDeepLink()` |

Example:

```javascript
window.plugins.appsFlyer.registerDeepLink(function (res) {
  var payload = typeof res === 'string' ? JSON.parse(res) : res;
  if (payload.status === 'found') {
    console.log('Deep link:', payload.data.deepLink);
  } else if (payload.status === 'failure') {
    console.log('Error:', payload.data.error);
  }
});
```

Call `registerDeepLink` **before** `initSdk` when possible.

---

## Conversion data / deferred deep linking

| Removed (v6) | Replacement (v7) |
|--------------|------------------|
| `onInstallConversionDataListener: true` in `initSdk` | `registerConversionDataListener(successCB, errorCB)` |
| GCD delivered via `initSdk` success callback | GCD delivered via conversion listener callbacks |

```javascript
window.plugins.appsFlyer.registerConversionDataListener(
  function (res) { console.log('Conversion data:', res); },
  function (err) { console.error('Conversion error:', err); }
);
```

Unregister with `unregisterConversionDataListener()`.

---

## User identity / PII (breaking change)

| Removed (v6) | Replacement (v7) |
|--------------|------------------|
| `setUserEmails(...)` | `setUserEmail(email)` |
| `setUserEmailsWithCryptType(...)` | Hashed PII APIs (see below) |
| `setPhoneNumber(...)` | `setUserPhone(countryCode, phoneNumber)` |

New hashed PII APIs (values normalized and hashed on-device):

- `setUserEmail(email)`
- `setUserPhone(countryCode, phoneNumber)`
- `setUserFirstName(firstName)`
- `setUserLastName(lastName)`
- `setUserFbLoginId(fbLoginId)`
- `clearUserPii()`

---

## Sharing filter (breaking change)

| Removed (v6) | Replacement (v7) |
|--------------|------------------|
| `setSharingFilter(partners)` | Removed |
| `setSharingFilterForAllPartners()` | Removed |
| — | `setSharingFilterForPartners(partners)` only |

To exclude all partners, pass an empty array or consult SDK docs for the recommended approach.

---

## In-app purchase validation

| Removed (v6) | Replacement (v7) |
|--------------|------------------|
| Separate `validateAndLogInAppPurchaseV2(...)` | Consolidated into `validateAndLogInAppPurchase(AFPurchaseDetails, additionalParameters, success, error)` |

Use the `AFPurchaseDetails` class:

```javascript
var purchase = new AFPurchaseDetails('subscription', 'purchase-token', 'product-id');
window.plugins.appsFlyer.validateAndLogInAppPurchase(purchase, { custom: 'param' }, success, error);
```

---

## New APIs in v7

| API | Purpose |
|-----|---------|
| `setDebugLog(isEnabled)` | Enable/disable debug logs (replaces `isDebug` in init options) |
| `registerConversionDataListener(success, error)` | Install conversion / GCD callbacks |
| `unregisterConversionDataListener()` | Remove conversion listener |
| `registerSessionReadyListener(callback)` | Notify when SDK session is ready to start |
| `unregisterSessionReadyListener()` | Remove session-ready listener |
| `isSessionReady(success, error)` | Query session-ready state |

---

## Platform-specific notes

### Android

- Dependencies use the **BOM** pattern: `com.appsflyer:af-android-sdk-bom:7.0.1` with `af-android-sdk`, `af-android-sdk-base`, and `af-android-plugin-bridge`.
- Kotlin stdlib is still required (`org.jetbrains.kotlin:kotlin-stdlib:1.6.20`).
- Plugin sets `AF_LAUNCH_PROTECT_ENABLED=false` in the manifest.

### iOS

- Native plugin is **Swift** — ensure **Run Path Search Paths** includes `/usr/lib/swift` (required since v6.15.11).
- Two CocoaPods are installed: `AppsFlyerFramework` and `AppsFlyerRPC`, both at **7.0.1**.
- Vendored `AppsFlyerLib.h` headers from older plugin versions are **no longer bundled** — they come from the framework pod.
- `unregisterConversionDataListener`, `unregisterSessionReadyListener`, and `unsubscribeForDeepLink` clear Cordova callbacks locally on iOS; there is no matching native RPC unsubscribe for some of these.

---

## Quick reference: removed APIs

The following JavaScript methods were **removed** from the public API in v7:

- `registerOnAppOpenAttribution(success, error)`
- `setUserEmails(...)` / `setUserEmailsWithCryptType(...)`
- `setPhoneNumber(...)`
- `setSharingFilter(partners)`
- `setSharingFilterForAllPartners()`
- `validateAndLogInAppPurchaseV2(...)` (use `validateAndLogInAppPurchase` instead)

The following **`initSdk` options** are ignored in v7 (use dedicated APIs):

- `isDebug` → `setDebugLog()`
- `onInstallConversionDataListener` → `registerConversionDataListener()`
- `onDeepLinkListener` → `registerDeepLink()`
- `shouldStartSdk` → always initialize first, then call `startSdk()` explicitly after `registerSessionReadyListener`
- `waitForATTUserAuthorization`, `useUninstallSandbox`, `collectIMEI`, `collectAndroidID` → use platform-specific SDK APIs where available

---

## Need help?

- [API reference](./API.md)
- [Integration guides](./Guides.md)
- [AppsFlyer Android SDK 7 docs](https://dev.appsflyer.com/hc/docs/install-android-sdk)
- [AppsFlyer iOS SDK 7 docs](https://dev.appsflyer.com/hc/docs/install-ios-sdk)
