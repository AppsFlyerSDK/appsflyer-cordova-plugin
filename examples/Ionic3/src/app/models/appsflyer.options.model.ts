export class AppsFlyerInitOptions {
  public devKey: string;
  public appId?: string;
  public isDebug?: boolean;
  public onInstallConversionDataListener?: boolean;
}

export class AppsFlyerTrackEventOptions {
  public eventName: string;
  public eventValues: Object;
}

export class AppsFlyerConstants {
  public static DEV_KEY: string = 'WdpTVAcYwmxsaQ4WeTspmh';
  public static APP_ID: string = '819999999';
}


export class AppsFlyerCallbackModel {
  onInstallConversionData:Object = {};
  onAppOpenAttribution:Object = {};

  constructor() {
    //Object.assign(this, onInstallConversionData, onAppOpenAttribution);
  }
}
