import { Component } from "@angular/core";
import { ToastController } from "@ionic/angular";

import { Appsflyer } from "@ionic-native/appsflyer/ngx";
import { ThrowStmt } from "@angular/compiler";

@Component({
  selector: "app-home",
  templateUrl: "home.page.html",
  styleUrls: ["home.page.scss"]
})
export class HomePage {
  constructor(
    public toastController: ToastController,
    private appsflyer: Appsflyer
  ) {
    const options = { devKey: "enteryourkey", isDebug: true };
    this.appsflyer.initSdk(options);
    this.appsflyer
      .registerOnAppOpenAttribution()
      .then(res => {
        this.presentToast(res);
      })
      .catch(err => {
        this.presentToast(err);
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
      message: "Clicked",
      duration: 2000
    });
    toast.present();
  }
}
