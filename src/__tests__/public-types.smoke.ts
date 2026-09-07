// Type-only smoke test: src/index.ts's public surface is a blind `export * from
// '@appsflyer-sdk/js-core-plugin'`. Nothing else in this repo checks that package still exports
// these names -- if a future @appsflyer-sdk/js-core-plugin bump renames or drops one, this file
// fails `tsc` here instead of only surfacing in a downstream consumer's build.
import type {
  AppsFlyerError,
  ConversionCallbacks,
  ConversionData,
  DeepLinkCallbacks,
  DeepLinkData,
  ListenerHandle,
  PluginIdentity,
  RpcEvent,
  RpcTransport,
} from '../index';

// Referencing each type keeps `noUnusedLocals`/import-elision from silently dropping the check.
export type PublicTypesSmokeTest = [
  AppsFlyerError,
  ConversionCallbacks,
  ConversionData,
  DeepLinkCallbacks,
  DeepLinkData,
  ListenerHandle,
  PluginIdentity,
  RpcEvent,
  RpcTransport,
];
