import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';

const { AppsFlyerSDKMock } = vi.hoisted(() => ({
  AppsFlyerSDKMock: vi.fn(),
}));

vi.mock('@appsflyer-sdk/js-core-plugin', () => ({
  AppsFlyerSDK: AppsFlyerSDKMock,
}));

describe('index', () => {
  beforeEach(() => {
    vi.stubGlobal('cordova', { platformId: 'android', exec: vi.fn() });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('constructs AppsFlyerSDK with a CordovaTransport and this package’s plugin identity', async () => {
    const { AppsFlyer } = await import('../index');
    const { CordovaTransport } = await import('../cordova-transport');
    const { version } = await import('../version');

    expect(AppsFlyerSDKMock).toHaveBeenCalledTimes(1);
    const [transport, identity] = AppsFlyerSDKMock.mock.calls[0];
    expect(transport).toBeInstanceOf(CordovaTransport);
    expect(identity).toEqual({ plugin: 'cordova', pluginVersion: version });
    expect(AppsFlyer).toBeInstanceOf(AppsFlyerSDKMock);
  });

  it('exports the same instance as both the named and default export', async () => {
    const indexModule = await import('../index');
    expect(indexModule.default).toBe(indexModule.AppsFlyer);
  });
});
