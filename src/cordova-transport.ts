import type { RpcTransport, RpcEvent, ListenerHandle } from '@appsflyer-sdk/js-core-plugin';

const EXECUTE_RPC_ACTION = 'executeRpc';
const SUBSCRIBE_RPC_EVENTS_ACTION = 'subscribeRpcEvents';
const PLUGIN_SERVICE = 'AppsFlyerPlugin';

type RpcSuccess<T> = { success: true; data: T };
// code is always a number on the wire -- both native normalizers emit an Int/number, never a string.
type RpcFailure = { success: false; error: { code: number; message: string } };

export class AppsFlyerRpcError extends Error {
  constructor(
    public readonly code: number,
    message: string,
  ) {
    super(message);
    this.name = 'AppsFlyerRpcError';
  }
}

function isRpcResponse(value: unknown): value is RpcSuccess<unknown> | RpcFailure {
  return typeof value === 'object' && value !== null && typeof (value as { success?: unknown }).success === 'boolean';
}

function isRpcEvent(value: unknown): value is RpcEvent {
  return typeof value === 'object' && value !== null && typeof (value as { event?: unknown }).event === 'string';
}

export class CordovaTransport implements RpcTransport {
  // `as` is an intentional type-lie for any non-ios/android cordova.platformId (e.g. 'browser'). Lazy getter, not a constructor field read: `AppsFlyer` is a module-level singleton (index.ts) built at import time, before cordova.js may have run — reading the bare `cordova` global eagerly would throw before any consumer gets to wait for deviceready.
  get platform(): 'ios' | 'android' {
    return (typeof cordova !== 'undefined' ? cordova.platformId : 'ios') as 'ios' | 'android';
  }

  call<T = void>(method: string, params: Record<string, unknown> = {}): Promise<T> {
    const requestJson = JSON.stringify({ method, params });
    return new Promise<T>((resolve, reject) => {
      // esbuild bundles this with --bundle for the browser, so `require('cordova/exec')` would resolve as a real module and fail the build; fall back to the documented global instead, same as `platform` above.
      cordova.exec(
        (responseJson: string) => {
          let parsed: unknown;
          try {
            parsed = JSON.parse(responseJson);
          } catch {
            parsed = undefined;
          }
          if (!isRpcResponse(parsed)) {
            reject(new Error(`Malformed RPC response for ${method}: ${responseJson}`));
            return;
          }
          if (!parsed.success) {
            reject(new AppsFlyerRpcError(parsed.error.code, parsed.error.message));
            return;
          }
          resolve((parsed as RpcSuccess<T>).data);
        },
        // Native failure callback can hand back a generic Error or a bare string; normalize so every rejection from this transport is a real Error instance.
        (err: unknown) => reject(typeof err === 'string' ? new Error(err) : err),
        PLUGIN_SERVICE,
        EXECUTE_RPC_ACTION,
        [{ requestJson }],
      );
    });
  }

  // No native "unsubscribeRpcEvents" primitive: both native plugins latch onto the FIRST subscribeRpcEvents call's callbackId for the app's life (Cordova's keepCallback) and never unsubscribe it, so this registry does the real add/remove, fanning the single native slot out to whatever's in `listeners` — otherwise subscribe(cb1) -> remove() -> subscribe(cb2) would orphan cb2 while stale cb1 kept firing.
  private listeners: Array<(event: RpcEvent) => void> = [];
  private nativeSubscribed = false;

  subscribe(listener: (event: RpcEvent) => void): ListenerHandle {
    this.listeners.push(listener);

    if (!this.nativeSubscribed) {
      this.nativeSubscribed = true;
      cordova.exec(
        // Both native shims send the raw JSON string directly (same shape as call()'s responseJson), not an { envelopeJson } object — destructuring it as one silently read `envelopeJson` off a string (always undefined), dropping every native event as "malformed".
        (envelopeJson: string) => {
          let parsed: unknown;
          try {
            parsed = JSON.parse(envelopeJson);
          } catch {
            parsed = undefined;
          }
          if (!isRpcEvent(parsed)) {
            // eslint-disable-next-line no-console -- never log the envelope itself, rpcEvent carries deep-link URLs with PII query params.
            console.warn('[AppsFlyer] Malformed rpcEvent payload, dropping.');
            return;
          }
          for (const registered of this.listeners) {
            registered(parsed);
          }
        },
        // eslint-disable-next-line no-console -- native rejecting subscribeRpcEvents means the
        // bridge is gone; nothing meaningful to do but avoid an unhandled failure.
        (error: unknown) => console.warn('[AppsFlyer] subscribeRpcEvents failed:', error),
        PLUGIN_SERVICE,
        SUBSCRIBE_RPC_EVENTS_ACTION,
        [],
      );
    }

    return {
      remove: () => {
        this.listeners = this.listeners.filter((registered) => registered !== listener);
      },
    };
  }
}
