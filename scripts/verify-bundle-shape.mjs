#!/usr/bin/env node
// Guards plugin.xml's <clobbers target="window.plugins.appsFlyer"/>: it must land the callable AppsFlyerSDK instance itself, not a {AppsFlyer, default, ...} namespace object, since every pre-migration call site does `window.plugins.appsFlyer.init(...)` directly.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

// Stub the minimum CordovaTransport touches at require-time (it reads global `cordova`) so this can run under plain Node, off-device.
globalThis.cordova ??= { platformId: 'android', exec: () => {} };
globalThis.window ??= { plugins: {} };

const bundle = createRequire(root)(path.join(root, 'www/appsflyer.js'));

assert.equal(typeof bundle.AppsFlyerRpcError, 'function', 'AppsFlyerRpcError must be reachable off the global');
assert.ok(bundle.AFPurchaseType, 'AFPurchaseType constants must be reachable off the global');
assert.equal(bundle, bundle.default, 'bundle must equal its own default export (no namespace-object wrapping)');

// The build footer's `Object.assign(module.exports.default, module.exports)` is an untyped merge `tsc` can't check: a same-named export would silently overwrite a bound AppsFlyerSDK.prototype method. Check every prototype method generically so any future collision fails the build.
assert.ok(typeof bundle.AppsFlyerSDK === 'function', 'AppsFlyerSDK class must be reachable off the global');
const methodNames = Object.getOwnPropertyNames(bundle.AppsFlyerSDK.prototype).filter(
  (name) => name !== 'constructor',
);
assert.ok(methodNames.length > 10, 'sanity check: AppsFlyerSDK.prototype should expose its RPC methods');
for (const name of methodNames) {
  assert.equal(
    typeof bundle[name],
    'function',
    `named export collision: "${name}" on window.plugins.appsFlyer is no longer the bound AppsFlyerSDK method`,
  );
}

console.log('[verify-bundle-shape] OK — window.plugins.appsFlyer stays directly callable');
