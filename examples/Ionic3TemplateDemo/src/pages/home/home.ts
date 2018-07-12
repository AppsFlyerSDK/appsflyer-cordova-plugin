import { Component } from '@angular/core';
import { NavController } from 'ionic-angular';
import { Events } from 'ionic-angular';

@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {



  constructor(public navCtrl: NavController, public events: Events) {

    navCtrl.onInstallConversionData = {};
    navCtrl.onAppOpenAttribution = {};

    events.subscribe('onInstallConversionData', (res) => {
      navCtrl.onInstallConversionData = res.data;
      alert("onInstallConversionData: " +  JSON.stringify(res.data));
    });

    events.subscribe('onAppOpenAttribution', (res) => {
      navCtrl.onAppOpenAttribution = res.data;
      alert("onAppOpenAttribution: " +  JSON.stringify(res.data));
    });
  }

}
