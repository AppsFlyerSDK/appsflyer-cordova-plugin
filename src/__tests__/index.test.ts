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

  it('preserves a pre-existing window.handleOpenURL instead of clobbering it', async () => {
    const previousHandler = vi.fn();
    vi.stubGlobal('window', { handleOpenURL: previousHandler });

    await import('../index');
    (window as unknown as { handleOpenURL: (url: string) => void }).handleOpenURL('scheme://deep-link');

    expect(previousHandler).toHaveBeenCalledWith('scheme://deep-link');
  });

  it('installs a no-op window.handleOpenURL when none exists on Android', async () => {
    vi.stubGlobal('window', {});

    await import('../index');
    const handleOpenURL = (window as unknown as { handleOpenURL?: (url: string) => void }).handleOpenURL;

    expect(typeof handleOpenURL).toBe('function');
    expect(() => handleOpenURL?.('scheme://deep-link')).not.toThrow();
    expect(AppsFlyerSDKMock.prototype.performDeepLinking).not.toHaveBeenCalled();
  });
});
