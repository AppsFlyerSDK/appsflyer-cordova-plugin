//$ ionic serve
//ionic cordova build android

import { Component } from '@angular/core';
import { Platform } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';

import { HomePage } from '../pages/home/home';

@Component({
  templateUrl: 'app.html'
})


//interface Options { devKey: string; appId: string }

export class MyApp {



  rootPage:any = HomePage;

  constructor(platform: Platform, statusBar: StatusBar, splashScreen: SplashScreen) {
    platform.ready().then(() => {

      let options = {
        devKey: 'xxXXXXXxXxXXXXxXXxxxx8'// your AppsFlyer devKey;
      }


      console.log("platform.is('ios')", platform.is('ios'));
      console.log("platform.is('android')", platform.is('android'));

      if (platform.is('ios') || platform.is('android')) {
        window['plugins'].appsFlyer.initSdk(options);
      }




      statusBar.styleDefault();
      splashScreen.hide();
    });
  }
}

