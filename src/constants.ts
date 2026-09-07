// Local enums @appsflyer-sdk/js-core-plugin does not export -- re-exported from src/index.ts.
// See RENAME_AUDIT.md for the MediationNetwork wire-value decision (kept as this repo's existing
// values for backward compat; do not "fix" the casing to match the reference plugin's without
// confirming against the native RPC schema first).

export enum AFPurchaseType {
  oneTimePurchase = 'one_time_purchase',
  subscription = 'subscription',
}

// Wire values (right-hand strings) intentionally preserve this repo's pre-migration values from
// the old www/appsflyer.js, NOT the appsflyer-capacitor-plugin reference's values -- see
// RENAME_AUDIT.md "MediationNetwork wire-value discrepancy" for the full comparison and why this
// was not silently changed.
export enum MediationNetwork {
  IRONSOURCE = 'ironsource',
  APPLOVIN_MAX = 'applovinmax',
  GOOGLE_ADMOB = 'googleadmob',
  FYBER = 'fyber',
  APPODEAL = 'appodeal',
  ADMOST = 'Admost',
  TOPON = 'Topon',
  TRADPLUS = 'Tradplus',
  YANDEX = 'Yandex',
  CHARTBOOST = 'chartboost',
  UNITY = 'Unity',
  TOPON_PTE = 'toponpte',
  CUSTOM_MEDIATION = 'customMediation',
  DIRECT_MONETIZATION_NETWORK = 'directMonetizationNetwork',
}
