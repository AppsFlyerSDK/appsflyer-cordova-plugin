import { Component } from '@angular/core';
import { NavController } from 'ionic-angular';

@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {

  public items: Array<string>;

  constructor(public navCtrl: NavController) {
    this.items = ["item1", "item2", "item3"]
  }

  public open(event, item) {

    let eventName = "af_add_to_cart";
    let eventValues = {
      "af_content_id": "id123",
      "af_currency":"USD",
      "af_revenue": "2"
    };
    window['plugins'].appsFlyer.trackEvent(eventName, eventValues);
  }

}
