import { Component } from "@angular/core";
import { ToastController } from "@ionic/angular";

import { Appsflyer } from "@ionic-native/appsflyer/ngx";

// declare var window;

@Component({
  selector: "app-home",
  templateUrl: "home.page.html",
  styleUrls: ["home.page.scss"]
})
export class HomePage {
  oaoa = "open the app from a deep link";
  gcd = "loading...";

  constructor(
    public toastController: ToastController,
    private appsflyer: Appsflyer
  ) {
    const options = {
      devKey: "enteryourkey",
      isDebug: true,
      onInstallConversionDataListener: true
    };
    this.appsflyer
      .initSdk(options)
      .then(res => {
        console.log("INIT SDK");
        this.gcd = res.data;
        console.log(res);
      })
      .catch(err => {
        console.log(err);
      });
    this.appsflyer
      .registerOnAppOpenAttribution()
      .then(res => {
        console.log("OAOA");
        this.oaoa = res.data;
        console.log(res);
      })
      .catch(err => {
        console.log(err);
      });
  }

  async trackEvent() {
    var eventName = "af_add_to_cart";
    var eventValues = {
      af_content_id: "id123",
      af_currency: "USD",
      af_revenue: "2"
    };
    this.appsflyer.trackEvent(eventName, eventValues);
    await this.presentToast("Event was sent successfully");
  }

  async presentToast(message) {
    const toast = await this.toastController.create({
      message: message,
      duration: 2000
    });
    toast.present();
  }
}
