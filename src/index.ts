import { AppsFlyerSDK } from '@appsflyer-sdk/js-core-plugin';

import { CordovaTransport, AppsFlyerRpcError } from './cordova-transport';
import { version } from './version';

// Re-exports every RPC method's param/return types and the RpcTransport/RpcEvent contract.
export * from '@appsflyer-sdk/js-core-plugin';
// js-core-plugin does not export AFPurchaseType/MediationNetwork equivalents.
export * from './constants';
// Typed RPC failure shape (transport rejects with this on {success:false}) — export it, or
// `catch (e) { if (e instanceof AppsFlyerRpcError) }` is unreachable for every consumer.
export { AppsFlyerRpcError };

const AppsFlyer = new AppsFlyerSDK(new CordovaTransport(), {
  plugin: 'cordova',
  pluginVersion: version,
});

// cordova-plugin-customurlscheme's Android bridge (LaunchMyApp.js) delivers every custom-scheme
// URL by calling a global `window.handleOpenURL(url)` it expects the app/a plugin to define --
// there is no native OS callback for this on Android the way there is on iOS (which AppsFlyerX+
// AppController.m already swizzles directly, so it must not also go through this path or the
// deep link would fire twice). `handleOpenURL` isn't in the RPC schema for android; the schema's
// android-supported equivalent is performDeepLinking.
if (cordova.platformId === 'android' && typeof window !== 'undefined') {
  (window as unknown as { handleOpenURL?: (url: string) => void }).handleOpenURL = (url: string) => {
    AppsFlyer.performDeepLinking({ url }).catch((error: unknown) => {
      // eslint-disable-next-line no-console -- surfaces a bridge-not-ready/malformed-url failure;
      // never log `url` itself, it carries the OneLink's query-param PII.
      console.warn('[AppsFlyer] performDeepLinking failed:', error);
    });
  };
}

export { AppsFlyer };
export default AppsFlyer;
