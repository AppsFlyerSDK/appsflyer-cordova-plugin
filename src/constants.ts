// Local enums @appsflyer-sdk/js-core-plugin does not export -- re-exported from src/index.ts.

import type { LogAdRevenueParams } from '@appsflyer-sdk/js-core-plugin';

export enum AFPurchaseType {
  oneTimePurchase = 'one_time_purchase',
  subscription = 'subscription',
}

// Values must be the keys of rpc-map's logAdRevenue `mediationNetwork` valueMap -- that map is what
// turns them into each platform's native spelling (customMediation -> 'custom_mediation' on Android,
// 'custom' on iOS). A value that isn't a key silently skips the map and reaches the SDK unmapped.
// `satisfies` pins that: LogAdRevenueParams['mediationNetwork'] is generated from the same schema,
// so a drifting value fails the build. A const object rather than an enum because TypeScript won't
// assign a string enum member to a string literal union (TS2820), which made passing a member to
// logAdRevenue an error callers had to cast away.
export const MediationNetwork = {
  IRONSOURCE: 'ironSource',
  APPLOVIN_MAX: 'applovinMax',
  GOOGLE_ADMOB: 'googleAdMob',
  FYBER: 'fyber',
  APPODEAL: 'appodeal',
  ADMOST: 'admost',
  TOPON: 'topon',
  TRADPLUS: 'tradplus',
  YANDEX: 'yandex',
  CHARTBOOST: 'chartboost',
  UNITY: 'unity',
  TOPON_PTE: 'toponPte',
  CUSTOM_MEDIATION: 'customMediation',
  DIRECT_MONETIZATION_NETWORK: 'directMonetizationNetwork',
} as const satisfies Record<string, LogAdRevenueParams['mediationNetwork']>;

export type MediationNetwork = (typeof MediationNetwork)[keyof typeof MediationNetwork];
