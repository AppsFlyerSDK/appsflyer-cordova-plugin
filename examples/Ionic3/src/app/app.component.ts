//http://fessapp.onelink.me/apple-app-site-association

import { Component } from '@angular/core';
import { Platform } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';

import { TabsPage } from '../pages/tabs/tabs';
import { Events } from 'ionic-angular';

import { AppsFlyerInitOptions, AppsFlyerConstants } from "./models/appsflyer.options.model";

declare var window: any;

@Component({
  templateUrl: 'app.html'
})
export class MyApp {
  rootPage:any = TabsPage;

  constructor(
    platform: Platform,
    statusBar: StatusBar,
    splashScreen: SplashScreen,
    public events: Events)
  {
    platform.ready().then(() => {

      // init AppsFlyer
      const options = new AppsFlyerInitOptions();
      options.devKey = AppsFlyerConstants.DEV_KEY;
      options.isDebug = true;
      options.onInstallConversionDataListener = true;

      if (platform.is('ios')){
        options.appId = AppsFlyerConstants.APP_ID;
      }

      try {
        const onSuccess: Function = (res: any) => {
          this.events.publish('onInstallConversionData', JSON.parse(res));
        };
        const onError: Function = (err: any) => {
          this.events.publish('onInstallConversionData', JSON.parse(err));
        };

        const onAppOpenAttributionSuccess: Function = (res: any) => {
          this.events.publish('onAppOpenAttribution', JSON.parse(res));
        };
        const onAppOpenAttributionError: Function = (err: any) => {
          this.events.publish('onAppOpenAttribution', JSON.parse(err));
        };

        window.plugins.appsFlyer.registerOnAppOpenAttribution(onAppOpenAttributionSuccess, onAppOpenAttributionError);

        window.plugins.appsFlyer.initSdk(options, onSuccess, onError);
      }
      catch (e) {
        console.error("ERROR: AppsFlyer not initiated", e);
      }

      statusBar.styleDefault();
      splashScreen.hide();
    });
  }
}
