import { AppsFlyerSDK } from '@appsflyer-sdk/js-core-plugin';

import { CordovaTransport, AppsFlyerRpcError } from './cordova-transport';
import { version } from './version';

export * from '@appsflyer-sdk/js-core-plugin';
export * from './constants';
export { AppsFlyerRpcError };

const AppsFlyer = new AppsFlyerSDK(new CordovaTransport(), {
  plugin: 'cordova',
  pluginVersion: version,
});

// cordova-plugin-customurlscheme expects a global handleOpenURL; AppsFlyerPlugin.kt forwards deep links natively so the handler is just a no-op guard against ReferenceError.
// Install whenever window exists — index.ts can load before cordova.js, so gating on `cordova` would skip Android.
if (typeof window !== 'undefined') {
  (window as unknown as { handleOpenURL?: (url: string) => void }).handleOpenURL ??= () => {};
}

export { AppsFlyer };
export default AppsFlyer;
