import { Component,NgZone } from '@angular/core';
import { NavController } from 'ionic-angular';
import { Events } from 'ionic-angular';


@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {

  onInstallConversionData:Object = {};
  onAppOpenAttribution:Object = {};

  constructor(private _ngZone: NgZone, public navCtrl: NavController, public events: Events) {


    events.subscribe('onInstallConversionData', (res) => {

      this.onInstallConversionData = {};

      alert("onInstallConversionData: " +  JSON.stringify(res));

      this._ngZone.run(() => {
        this.onInstallConversionData = res;
      });
    });

    events.subscribe('onAppOpenAttribution', (res) => {

      this.onAppOpenAttribution = {};

      alert("onAppOpenAttribution: " +  JSON.stringify(res));

      this._ngZone.run(() => {
        this.onAppOpenAttribution = res;
      });
    });
     }
}
