import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';

import { AppsFlyerRpcError, CordovaTransport } from '../cordova-transport';

type ExecSuccess = (data: unknown) => void;
type ExecFail = (err: unknown) => void;
type ExecCall = [ExecSuccess, ExecFail, string, string, unknown[]];

describe('CordovaTransport', () => {
  const execMock = vi.fn<(...args: ExecCall) => void>();

  beforeEach(() => {
    execMock.mockReset();
    vi.stubGlobal('cordova', { platformId: 'android', exec: execMock });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('reports the cordova platform', () => {
    const transport = new CordovaTransport();
    expect(transport.platform).toBe('android');
  });

  it('does not throw on construction when the global cordova does not exist yet', () => {
    // The module-level `AppsFlyer` singleton (index.ts) constructs this at import time, which can race cordova.js — only `.platform`, read lazily, may touch the bare `cordova` global.
    vi.unstubAllGlobals();
    expect(() => new CordovaTransport()).not.toThrow();
    vi.stubGlobal('cordova', { platformId: 'android', exec: execMock });
  });

  it('does not throw on construction when cordova.platformId is outside ios|android', () => {
    // Construction must never fail: `AppsFlyer` is a module-level singleton (index.ts), so throwing here would crash on import for an unsupported target like Cordova's 'browser' platform.
    vi.stubGlobal('cordova', { platformId: 'browser', exec: execMock });
    const transport = new CordovaTransport();
    expect(transport.platform).toBe('browser');
  });

  it('serializes method+params and resolves data on success', async () => {
    execMock.mockImplementation((success, _fail, service, action, args) => {
      expect(service).toBe('AppsFlyerPlugin');
      expect(action).toBe('executeRpc');
      expect(args).toEqual([{ requestJson: JSON.stringify({ method: 'getAppsFlyerUID', params: {} }) }]);
      success(JSON.stringify({ success: true, data: { uid: 'abc' } }));
    });
    const transport = new CordovaTransport();

    const result = await transport.call('getAppsFlyerUID', {});

    expect(result).toEqual({ uid: 'abc' });
  });

  it('rejects with an AppsFlyerRpcError on failure', async () => {
    execMock.mockImplementation((success) => {
      success(JSON.stringify({ success: false, error: { code: 500, message: 'boom' } }));
    });
    const transport = new CordovaTransport();

    await expect(transport.call('start')).rejects.toMatchObject(new AppsFlyerRpcError(500, 'boom'));
  });

  it('rejects with a clear error on malformed (non-JSON) native response', async () => {
    execMock.mockImplementation((success) => success('not json'));
    const transport = new CordovaTransport();

    await expect(transport.call('start')).rejects.toThrow(/Malformed RPC response/);
  });

  it('rejects with a clear error on well-formed JSON missing the required success field', async () => {
    execMock.mockImplementation((success) => success(JSON.stringify({ data: {} })));
    const transport = new CordovaTransport();

    await expect(transport.call('start')).rejects.toThrow(/Malformed RPC response/);
  });

  it('rejects when the native exec call itself fails (bridge-level failure)', async () => {
    execMock.mockImplementation((_success, fail) => fail(new Error('bridge unavailable')));
    const transport = new CordovaTransport();

    await expect(transport.call('start')).rejects.toThrow('bridge unavailable');
  });

  it('wraps a bare-string native failure in a real Error instance', async () => {
    execMock.mockImplementation((_success, fail) => fail('bridge unavailable'));
    const transport = new CordovaTransport();

    await expect(transport.call('start')).rejects.toBeInstanceOf(Error);
    await expect(transport.call('start')).rejects.toThrow('bridge unavailable');
  });

  it('subscribe parses the envelope JSON and forwards RpcEvent objects', () => {
    let handler: ExecSuccess | undefined;
    execMock.mockImplementation((success, _fail, service, action) => {
      expect(service).toBe('AppsFlyerPlugin');
      expect(action).toBe('subscribeRpcEvents');
      handler = success;
    });
    const transport = new CordovaTransport();
    const received: unknown[] = [];

    transport.subscribe((event) => received.push(event));
    handler?.(JSON.stringify({ event: 'onConversionDataSuccess', data: { af_status: 'Organic' } }));

    expect(received).toEqual([{ event: 'onConversionDataSuccess', data: { af_status: 'Organic' } }]);
  });

  it('drops a malformed (non-JSON) rpcEvent payload instead of throwing', () => {
    const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    let handler: ExecSuccess | undefined;
    execMock.mockImplementation((success) => {
      handler = success;
    });
    const transport = new CordovaTransport();
    const listener = vi.fn();

    transport.subscribe(listener);
    expect(() => handler?.('not json')).not.toThrow();

    expect(listener).not.toHaveBeenCalled();
    expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('Malformed rpcEvent payload'));
    warnSpy.mockRestore();
  });

  it('drops a well-formed JSON payload missing the required event field', () => {
    const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    let handler: ExecSuccess | undefined;
    execMock.mockImplementation((success) => {
      handler = success;
    });
    const transport = new CordovaTransport();
    const listener = vi.fn();

    transport.subscribe(listener);
    handler?.(JSON.stringify({ data: { af_status: 'Organic' } }));

    expect(listener).not.toHaveBeenCalled();
    expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('Malformed rpcEvent payload'));
    warnSpy.mockRestore();
  });

  it('opens only one native subscription for a second subscribe() on the same instance', () => {
    execMock.mockImplementation(() => undefined);
    const transport = new CordovaTransport();

    transport.subscribe(() => undefined);
    transport.subscribe(() => undefined);

    // Only one native slot ever opens — the second subscribe() registers a second *local* listener instead (see the two-listeners test below).
    expect(execMock).toHaveBeenCalledTimes(1);
  });

  it('does not re-subscribe natively after remove() (no native unsubscribe primitive exists)', () => {
    execMock.mockImplementation(() => undefined);
    const transport = new CordovaTransport();

    const handle = transport.subscribe(() => undefined);
    handle.remove();
    transport.subscribe(() => undefined);

    expect(execMock).toHaveBeenCalledTimes(1);
  });

  it('dispatches one native event to every registered listener, and remove() only drops its own', () => {
    let handler: ExecSuccess | undefined;
    execMock.mockImplementation((success) => {
      handler = success;
    });
    const transport = new CordovaTransport();
    const listener1 = vi.fn();
    const listener2 = vi.fn();

    const handle1 = transport.subscribe(listener1);
    transport.subscribe(listener2);
    handler?.(JSON.stringify({ event: 'onConversionDataSuccess', data: { af_status: 'Organic' } }));

    expect(listener1).toHaveBeenCalledTimes(1);
    expect(listener2).toHaveBeenCalledTimes(1);

    handle1.remove();
    handler?.(JSON.stringify({ event: 'onConversionDataSuccess', data: { af_status: 'Organic' } }));

    // listener1 was removed -- still only 1 call; listener2 is unaffected and gets the second event.
    expect(listener1).toHaveBeenCalledTimes(1);
    expect(listener2).toHaveBeenCalledTimes(2);
  });
});
