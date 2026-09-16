// Local enums @appsflyer-sdk/js-core-plugin does not export -- re-exported from src/index.ts.

export enum AFPurchaseType {
  oneTimePurchase = 'one_time_purchase',
  subscription = 'subscription',
}

// Wire values must match @appsflyer-sdk/js-core-plugin LogAdRevenueParams['mediationNetwork']
// camelCase strings so rpc-map can transform them to native enum/integers.
export enum MediationNetwork {
  IRONSOURCE = 'ironSource',
  APPLOVIN_MAX = 'applovinMax',
  GOOGLE_ADMOB = 'googleAdMob',
  FYBER = 'fyber',
  APPODEAL = 'appodeal',
  ADMOST = 'admost',
  TOPON = 'topon',
  TRADPLUS = 'tradplus',
  YANDEX = 'yandex',
  CHARTBOOST = 'chartboost',
  UNITY = 'unity',
  TOPON_PTE = 'toponPte',
  CUSTOM_MEDIATION = 'customMediation',
  DIRECT_MONETIZATION_NETWORK = 'directMonetizationNetwork',
}
