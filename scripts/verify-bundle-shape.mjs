#!/usr/bin/env node
// Guards the one thing a bundler/config change could silently break: plugin.xml's
// <clobbers target="window.plugins.appsFlyer"/> must land the callable AppsFlyerSDK instance
// itself, not a {AppsFlyer, default, ...} namespace object — every pre-migration call site does
// `window.plugins.appsFlyer.init(...)` directly.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

// CordovaTransport's constructor reads the global `cordova` object (platformId) — stub the
// minimum the bundle touches at require-time so this can run under plain Node, off-device.
globalThis.cordova ??= { platformId: 'android', exec: () => {} };
globalThis.window ??= { plugins: {} };

const bundle = createRequire(root)(path.join(root, 'www/appsflyer.js'));

assert.equal(typeof bundle.init, 'function', 'window.plugins.appsFlyer.init must be callable directly');
assert.equal(typeof bundle.start, 'function', 'window.plugins.appsFlyer.start must be callable directly');
assert.equal(typeof bundle.AppsFlyerRpcError, 'function', 'AppsFlyerRpcError must be reachable off the global');
assert.ok(bundle.AFPurchaseType, 'AFPurchaseType constants must be reachable off the global');
assert.equal(bundle, bundle.default, 'bundle must equal its own default export (no namespace-object wrapping)');

console.log('[verify-bundle-shape] OK — window.plugins.appsFlyer stays directly callable');
