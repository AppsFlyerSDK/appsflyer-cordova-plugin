import { describe, expect, it } from 'vitest';
import { RPC_MAP } from '@appsflyer-sdk/js-core-plugin/dist/generated/rpc-map';
import { resolveRpc } from '@appsflyer-sdk/js-core-plugin/dist/rpc-resolver';

import { MediationNetwork } from '../constants';

// resolveRpc applies rpc-map's valueMap only when the value it receives is a key of that map, and
// falls back to a near-identity transform otherwise. A MediationNetwork value that isn't a key
// therefore reaches the native SDK unmapped, with no error anywhere -- exactly how iOS once got
// 'customMediation' instead of 'custom'.
const NATIVE_SPELLINGS: ReadonlyArray<readonly [value: string, android: string, ios: string]> = [
  [MediationNetwork.IRONSOURCE, 'ironsource', 'ironsource'],
  [MediationNetwork.APPLOVIN_MAX, 'applovin_max', 'applovin_max'],
  [MediationNetwork.GOOGLE_ADMOB, 'google_admob', 'google_admob'],
  [MediationNetwork.FYBER, 'fyber', 'fyber'],
  [MediationNetwork.APPODEAL, 'appodeal', 'appodeal'],
  [MediationNetwork.ADMOST, 'admost', 'admost'],
  [MediationNetwork.TOPON, 'topon', 'topon'],
  [MediationNetwork.TRADPLUS, 'tradplus', 'tradplus'],
  [MediationNetwork.YANDEX, 'yandex', 'yandex'],
  [MediationNetwork.CHARTBOOST, 'chartboost', 'chartboost'],
  [MediationNetwork.UNITY, 'unity', 'unity'],
  [MediationNetwork.TOPON_PTE, 'topon_pte', 'topon_pte'],
  [MediationNetwork.CUSTOM_MEDIATION, 'custom_mediation', 'custom'],
  [MediationNetwork.DIRECT_MONETIZATION_NETWORK, 'direct_monetization_network', 'directmonetization'],
];

describe('MediationNetwork', () => {
  it('only exposes networks the RPC schema maps', () => {
    const schemaValues = Object.keys(
      RPC_MAP.logAdRevenue.android!.mappings['/mediationNetwork'].valueMap!,
    );
    expect(schemaValues).toEqual(expect.arrayContaining(Object.values(MediationNetwork)));
  });

  it('has a native spelling assertion for every exposed network', () => {
    expect(new Set(NATIVE_SPELLINGS.map(([value]) => value))).toEqual(
      new Set(Object.values(MediationNetwork)),
    );
  });

  it.each(NATIVE_SPELLINGS)('%s reaches the SDK as %s on Android and %s on iOS', (value, android, ios) => {
    expect(resolveRpc('logAdRevenue', { mediationNetwork: value }, 'android').params.mediationNetwork).toBe(android);
    expect(resolveRpc('logAdRevenue', { mediationNetwork: value }, 'ios').params.mediationNetwork).toBe(ios);
  });
});
