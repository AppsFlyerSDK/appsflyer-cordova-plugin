import { Component } from '@angular/core';
import { Platform, IonApp, IonHeader, IonToolbar, IonTitle, IonContent, IonButton } from '@ionic/angular';
import { AF_CONFIG } from './af-config';

declare var window: any;

// RPC results/events are objects -- string-concatenating one directly renders "[object Object]".
function fmt(value: unknown): string {
  return typeof value === 'object' && value !== null ? JSON.stringify(value) : String(value);
}

// Every API call below alerts on both success and failure -- any answer must be visible,
// not just logged.
function notify(promise: Promise<unknown>, label: string): void {
  promise.then((res) => {
    alert(`${label} -> ${res === undefined ? 'OK' : fmt(res)}`);
  }).catch((err) => {
    alert(`${label} failed -> ${fmt(err)}`);
  });
}

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.scss',
  imports: [IonApp, IonHeader, IonToolbar, IonTitle, IonContent, IonButton],
})
export class App {

  constructor(public platform: Platform) {
    this.platform.ready().then(async () => {
      // registerOnAppOpenAttribution removed -- folded into registerDeepLinkListener's onDeepLinking.
      // Must be registered before init() per the new SDK's sequencing model.
      await window.plugins.appsFlyer.registerDeepLinkListener({
        onDeepLinking: function (res: unknown) {
          console.log('DDL ~~> ' + fmt(res));
          alert('DDL ~~> ' + fmt(res));
        }
      }).catch((err: unknown) => {
        console.log(err);
      });

      let options = {
        devKey: AF_CONFIG.devKey,
        appId: AF_CONFIG.appId,
        // isDebug -> enableDebug() below; onInstallConversionDataListener -> registerConversionListener
        // below; onDeepLinkListener -> registerDeepLinkListener above (folding onAppOpenAttribution in
        // too). waitForATTUserAuthorization has NO equivalent anywhere in js-core-plugin's RPC method
        // schema (see RENAME_AUDIT.md) -- dropped, flagged for a human, not guessed.
      };

      try {
        await window.plugins.appsFlyer.init(options);
      } catch (err) {
        alert('init failed -> ' + fmt(err));
        return;
      }

      window.plugins.appsFlyer.enableDebug({ enabled: true }).catch((err: unknown) => {
        console.log(err);
      });

      // init()'s own success/error callback used to double as the GCD delivery path
      // (onInstallConversionDataListener: true) -- that's now this standalone listener.
      window.plugins.appsFlyer.registerConversionListener({
        onConversionDataSuccess: (data: unknown) => {
          console.log('GCD ~~>' + fmt(data));
          alert('GCD ~~> ' + fmt(data));
        },
        onConversionDataFail: (err: unknown) => {
          console.log('GCD ~~> ' + err);
        }
      }).catch((err: unknown) => {
        console.log(err);
      });

      // ponytail: session-ready is native-driven and could in principle never fire (e.g. init
      // rejected silently upstream) -- this timeout is just a visible bounded fallback for a
      // manual test app, not a retry/recovery strategy.
      let sessionReady = false;
      // start() must be called from inside registerSessionReadyListener's callback per SDK 7's
      // manual startup model (see RENAME_AUDIT.md) -- no longer fired unconditionally after init.
      window.plugins.appsFlyer.registerSessionReadyListener(() => {
        sessionReady = true;
        window.plugins.appsFlyer.start().catch((err: unknown) => {
          alert('start failed -> ' + fmt(err));
        });
      }).catch((err: unknown) => {
        console.log(err);
      });
      setTimeout(() => {
        if (!sessionReady) {
          console.log('[AF] session-ready never fired within 10s -- start() was not called.');
        }
      }, 10000);
    });
  }

  logEvent() {
    let eventValues = { af_revenue: '10', af_data: 'data', af_currency: 'USD' };
    notify(window.plugins.appsFlyer.logEvent({ eventName: 'af_purchase', eventValues: eventValues }), 'logEvent');
  }

  brandedDomains() {
    let domains = ['promotion.greatapp.com', 'click.greatapp.com'];
    notify(window.plugins.appsFlyer.setOneLinkCustomDomain({ domains: domains }), 'setOneLinkCustomDomain');
  }

  resolveDeepLinksUrls() {
    let urls = ['clickdomain.com', 'anotherclickdomain.com'];
    notify(window.plugins.appsFlyer.setResolveDeepLinkURLs({ urls: urls }), 'setResolveDeepLinkURLs');
  }

  getSDKVersion() {
    notify(window.plugins.appsFlyer.getSdkVersion(), 'getSdkVersion');
  }

  getAppsFlyerUID() {
    notify(window.plugins.appsFlyer.getAppsFlyerUID(), 'getAppsFlyerUID');
  }

  setCustomerUserId() {
    notify(window.plugins.appsFlyer.setCustomerUserId({ customerId: '887788778' }), 'setCustomerUserId');
  }

  setCurrency() {
    notify(window.plugins.appsFlyer.setCurrencyCode({ currencyCode: 'USD' }), 'setCurrencyCode');
  }

  generateInviteLink() {
    let args = {
      campaign: 'testCampaign',
      referrerName: 'testReferrer',
      baseDeepLink: 'testBaseDeepLink',
      brandDomain: 'noakogonia.afsdktests.com',
      userParams: { a: 'b' }
    };
    notify(window.plugins.appsFlyer.generateInviteLink({ parameters: args }), 'generateInviteLink');
  }

  logAndOpenStore() {
    notify(window.plugins.appsFlyer.logAndOpenStore({
      promotedAppId: '1528937655',
      campaign: 'test',
      userParams: { custom_param: 'custom_value' },
    }), 'logAndOpenStore');
  }

  logAdRevenue() {
    let mediationNetwork = window.plugins.appsFlyer.MediationNetwork.TOPON;
    notify(window.plugins.appsFlyer.logAdRevenue({
      monetizationNetwork: 'testMonetizationNetwork',
      mediationNetwork: mediationNetwork,
      currencyIso4217Code: 'USD',
      revenue: 15.0,
      additionalParameters: { additionalKey1: 'additionalValue1' }
    }), 'logAdRevenue');
  }

  validateAndLogInAppPurchase() {
    const afDetails = {
      purchaseType: window.plugins.appsFlyer.AFPurchaseType.subscription,
      purchaseToken: 'abcd',
      productId: 'product1'
    };
    notify(window.plugins.appsFlyer.validateAndLogInAppPurchase({
      purchase: afDetails,
      additionalParameters: { param1: 'value1' }
    }), 'validateAndLogInAppPurchase');
  }

  disableAppSetId() {
    notify(window.plugins.appsFlyer.disableAppSetId(), 'disableAppSetId');
  }

}
