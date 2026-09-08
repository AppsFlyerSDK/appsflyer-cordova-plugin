import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';

const { AppsFlyerSDKMock } = vi.hoisted(() => ({
  AppsFlyerSDKMock: vi.fn(),
}));

vi.mock('@appsflyer-sdk/js-core-plugin', () => ({
  AppsFlyerSDK: AppsFlyerSDKMock,
}));

describe('index', () => {
  beforeEach(() => {
    vi.resetModules();
    AppsFlyerSDKMock.mockClear();
    AppsFlyerSDKMock.prototype.performDeepLinking = vi.fn().mockResolvedValue(undefined);
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

  it('chains window.handleOpenURL instead of clobbering a pre-existing handler', async () => {
    // No jsdom in this workspace (vitest's default 'node' environment, see vitest.config.mts) — a plain object stub is all production's `typeof window !== 'undefined'` guard requires.
    // Only guards against a ReferenceError in cordova-plugin-customurlscheme's `loadUrl("javascript:handleOpenURL(...)")` call — AppsFlyerPlugin.kt's onNewIntent forwards the deep link natively, so this doesn't call performDeepLinking itself.
    const previousHandler = vi.fn();
    vi.stubGlobal('window', { handleOpenURL: previousHandler });

    await import('../index');
    (window as unknown as { handleOpenURL: (url: string) => void }).handleOpenURL('scheme://deep-link');

    expect(previousHandler).toHaveBeenCalledWith('scheme://deep-link');
  });
});
