import { describe, expect, it } from 'vitest';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const {
  isStrictModeEnabled,
  updatePodfile,
  updateAndroidManifest,
} = require('../../hooks/af_strict_mode');

describe('af_strict_mode hook', () => {
  describe('isStrictModeEnabled', () => {
    it('returns true when preference name and value="true" exist', () => {
      const xml = `
        <widget id="com.example.app">
          <preference name="AppsFlyerStrictMode" value="true" />
        </widget>
      `;
      expect(isStrictModeEnabled(xml)).toBe(true);
    });

    it('returns true when attribute order is reversed', () => {
      const xml = '<preference value="true" name="AppsFlyerStrictMode" />';
      expect(isStrictModeEnabled(xml)).toBe(true);
    });

    it('handles case-insensitivity', () => {
      const xml = '<preference name="appsflyerstrictmode" value="TRUE" />';
      expect(isStrictModeEnabled(xml)).toBe(true);
    });

    it('returns false when value="false"', () => {
      const xml = '<preference name="AppsFlyerStrictMode" value="false" />';
      expect(isStrictModeEnabled(xml)).toBe(false);
    });

    it('returns false when preference is absent', () => {
      const xml = '<widget id="com.example.app"><name>Test</name></widget>';
      expect(isStrictModeEnabled(xml)).toBe(false);
    });

    it('returns false for empty or null content', () => {
      expect(isStrictModeEnabled('')).toBe(false);
      expect(isStrictModeEnabled(null)).toBe(false);
    });
  });

  describe('updatePodfile', () => {
    it('switches pod AppsFlyerRPC to AppsFlyerRPC/Strict when strict mode is enabled', () => {
      const initial = `
        target 'MyApp' do
          pod 'AppsFlyerRPC', '7.0.13'
        end
      `;
      const updated = updatePodfile(initial, true);
      expect(updated).toContain("pod 'AppsFlyerRPC/Strict', '7.0.13'");
      expect(updated).not.toContain("pod 'AppsFlyerRPC',");
    });

    it('supports double-quoted pod declaration', () => {
      const initial = 'pod "AppsFlyerRPC", "7.0.13"';
      const updated = updatePodfile(initial, true);
      expect(updated).toBe('pod "AppsFlyerRPC/Strict", "7.0.13"');
    });

    it('does not duplicate Strict if already present', () => {
      const initial = "pod 'AppsFlyerRPC/Strict', '7.0.13'";
      const updated = updatePodfile(initial, true);
      expect(updated).toBe(initial);
    });

    it('reverts AppsFlyerRPC/Strict back to AppsFlyerRPC when strict mode is disabled', () => {
      const initial = "pod 'AppsFlyerRPC/Strict', '7.0.13'";
      const updated = updatePodfile(initial, false);
      expect(updated).toBe("pod 'AppsFlyerRPC', '7.0.13'");
    });
  });

  describe('updateAndroidManifest', () => {
    it('removes com.google.android.gms.permission.AD_ID when strict mode is enabled', () => {
      const manifest = `
        <manifest xmlns:android="http://schemas.android.com/apk/res/android">
          <uses-permission android:name="android.permission.INTERNET" />
          <uses-permission android:name="com.google.android.gms.permission.AD_ID" />
          <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
        </manifest>
      `;
      const updated = updateAndroidManifest(manifest, true);
      expect(updated).not.toContain('com.google.android.gms.permission.AD_ID');
      expect(updated).toContain('android.permission.INTERNET');
      expect(updated).toContain('android.permission.ACCESS_NETWORK_STATE');
    });

    it('preserves manifest when strict mode is disabled', () => {
      const manifest = '<uses-permission android:name="com.google.android.gms.permission.AD_ID" />';
      const updated = updateAndroidManifest(manifest, false);
      expect(updated).toBe(manifest);
    });
  });
});
