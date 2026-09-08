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

// cordova-plugin-customurlscheme's Android native layer calls `loadUrl("javascript:handleOpenURL(...)")` directly, expecting a global `handleOpenURL` function — without it the WebView throws `ReferenceError: handleOpenURL is not defined`. AppsFlyerPlugin.kt's onNewIntent forwards the deep link natively now, so this only needs to exist to not crash; chains to any pre-existing handler rather than clobbering it.
if (typeof cordova !== 'undefined' && cordova.platformId === 'android' && typeof window !== 'undefined') {
  const globalWindow = window as unknown as { handleOpenURL?: (url: string) => void };
  const previousHandleOpenURL = globalWindow.handleOpenURL;
  globalWindow.handleOpenURL = (url: string) => {
    previousHandleOpenURL?.(url);
  };
}

export { AppsFlyer };
export default AppsFlyer;
