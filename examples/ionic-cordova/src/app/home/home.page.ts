import {Component} from '@angular/core';
import {Platform} from '@ionic/angular';

declare var window;

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {

  constructor(public platform: Platform) {
    this.platform.ready().then(() => {
      window.plugins.appsFlyer.registerOnAppOpenAttribution(
        function (res) {
          // handle deep link values
          console.log('onAppOpenAttribution ~~> ' + res);
          alert('onAppOpenAttribution ~~> ' + res);
        },
        function (err) {
          console.log(err);
        });

      //if onDeepLinkListener: false or undefined, the sdk will ignore it
      window.plugins.appsFlyer.registerDeepLink(function (res) {
        console.log('DDL ~~> ' + res);
        alert('DDL ~~> ' + res);
      });

      let options = {
        devKey: 'UsXxXxed',
        isDebug: true, //debug mode for tests only
        appId: '7XxXx1',
        onInstallConversionDataListener: true,
        waitForATTUserAuthorization: 10 //for iOS 14, tells the sdk to wait before sending launch
        // onDeepLinkListener: true // if true, it will override onAppOpenAttribution
      };

      window.plugins.appsFlyer.initSdk(
        options,
        function (res) {//success listener
          //do something with GCD
          console.log('GCD ~~>' + res);
          alert('GCD ~~> ' + res);


        }, function (err) {//failure listener
          console.log('GCD ~~> ' + err);
        });
    });
  }

  logEvent() {
    let eventName = 'af_ionic_purchase';
    let eventValues = {af_revenue: '10', af_data: 'data', af_currency: 'USD'};
    window.plugins.appsFlyer.logEvent(eventName, eventValues, function (res) {
      alert('logEvent: ' + res);
    }, function (res) {
      alert('logEvent: ' + res);
    });
  }

  brandedDomains() {
    let domains = ['promotion.greatapp.com', 'click.greatapp.com'];
    window.plugins.appsFlyer.setOneLinkCustomDomains(domains, null, null);
  }

  ResolveDeepLinksUrls() {
    let urls = ['clickdomain.com', 'anotherclickdomain.com'];
    window.plugins.appsFlyer.setResolveDeepLinkURLs(urls);

  }

  getSDKVersion() {
    window.plugins.appsFlyer.getSdkVersion(function (res) {
      alert('the version is: ' + res);
    });
  }

}
