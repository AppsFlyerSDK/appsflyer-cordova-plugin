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
  // RpcTransport requires 'ios' | 'android'; `as` is an intentional type-lie for any other
  // cordova.platformId value (e.g. 'browser') -- construction must never fail since `AppsFlyer`
  // is a module-level singleton (index.ts) built at import time. An unsupported platform surfaces
  // per-call instead, the same way cordova.exec itself would fail to reach a real native handler.
  readonly platform = cordova.platformId as 'ios' | 'android';

  call<T = void>(method: string, params: Record<string, unknown> = {}): Promise<T> {
    const requestJson = JSON.stringify({ method, params });
    return new Promise<T>((resolve, reject) => {
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
        reject,
        PLUGIN_SERVICE,
        EXECUTE_RPC_ACTION,
        [{ requestJson }],
      );
    });
  }

  // Guards against a second native listener: two would each dispatch every RPC event once,
  // double-firing every registered callback (conversion data, deep links, ...). js-core-plugin's
  // own AppsFlyerSDK already calls subscribe() at most once per instance, but this class
  // implements the public RpcTransport interface, so nothing stops a second caller from calling
  // it again on the same transport instance.
  private subscribed = false;

  subscribe(listener: (event: RpcEvent) => void): ListenerHandle {
    if (this.subscribed) {
      // eslint-disable-next-line no-console -- misuse (double subscribe), not debug noise
      console.warn('[AppsFlyer] subscribe() called more than once on the same transport instance — ignoring.');
      // eslint-disable-next-line @typescript-eslint/no-empty-function -- ignored second subscription has nothing to remove
      return { remove: () => {} };
    }
    this.subscribed = true;

    cordova.exec(
      // Both native shims send the raw JSON string as the plugin result message (same shape as
      // call()'s responseJson above) -- not an { envelopeJson } object. Destructuring it as one
      // silently reads `envelopeJson` off a string (always undefined), so JSON.parse(undefined)
      // throws and every native event -- including onSessionReady -- got dropped as "malformed".
      (envelopeJson: string) => {
        let parsed: unknown;
        try {
          parsed = JSON.parse(envelopeJson);
        } catch {
          parsed = undefined;
        }
        if (!isRpcEvent(parsed)) {
          // eslint-disable-next-line no-console -- a malformed native event is unexpected but
          // shouldn't crash the listener callback; surface it instead of throwing. Never log the
          // envelope itself -- rpcEvent carries deep-link URLs with PII query params.
          console.warn('[AppsFlyer] Malformed rpcEvent payload, dropping.');
          return;
        }
        listener(parsed);
      },
      // eslint-disable-next-line no-console -- native rejecting subscribeRpcEvents means the
      // bridge is gone; nothing meaningful to do but avoid an unhandled failure.
      (error: unknown) => console.warn('[AppsFlyer] subscribeRpcEvents failed:', error),
      PLUGIN_SERVICE,
      SUBSCRIBE_RPC_EVENTS_ACTION,
      [],
    );

    return {
      // There is no native "unsubscribeRpcEvents" primitive (native re-sends via Cordova's
      // keepCallback on the one callbackId registered above for the life of the app) -- remove()
      // can only reset the local guard so a legitimate subscribe -> remove -> subscribe sequence
      // still works, not actually unregister the native callback.
      remove: () => {
        this.subscribed = false;
      },
    };
  }
}
