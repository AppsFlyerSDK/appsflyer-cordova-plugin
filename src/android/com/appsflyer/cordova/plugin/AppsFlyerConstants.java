package com.appsflyer.cordova.plugin;

/**
 * Created by maxim on 11/24/16
 */

public class AppsFlyerConstants {

    final static String PLUGIN_VERSION = "6.16.2";
    final static String NO_DEVKEY_FOUND = "AppsFlyer 'devKey' is missing or empty";
    final static String NO_GCM_PROJECT_NUMBER_PROVIDED = "No GCM Project number provided";
    final static String SUCCESS = "Success";
    final static String FAILURE = "Failure";
    final static String NO_EVENT_NAME_FOUND   = "No 'eventName' found or its empty";
    final static String NO_EVENT_VALUES_FOUND = "No 'eventValues' found or Dictionary its empty";
    final static String EVENT_SENT_SUCCESSFULY = "Event sent successfully!";
    final static String NO_VALID_TOKEN = "Not a valid token";
    final static String NO_CUSTOMER_ID = "No customer id found";


    final static String AF_IS_DEBUG = "isDebug";

    final static String AF_COLLECT_IMEI = "collectIMEI";
    final static String AF_COLLECT_ANDROID_ID = "collectAndroidID";

    final static String AF_DEV_KEY = "devKey";
    final static String AF_CONVERSION_DATA = "onInstallConversionDataListener";
    final static String AF_ON_INSTALL_CONVERSION_DATA = "onInstallConversionDataN";
    final static String SHOULD_START_SDK = "shouldStartSdk";

    final static String AF_SUCCESS ="success";
    final static String AF_FAILURE ="failure";
    final static String AF_ON_DEEP_LINKING = "onDeepLinkListener";
    final static String AF_DEEP_LINK = "onDeepLinking";
    final static String AF_ON_ATTRIBUTION_FAILURE ="onAttributionFailure";
    final static String AF_ON_APP_OPEN_ATTRIBUTION ="onAppOpenAttribution";
    final static String AF_ON_INSTALL_CONVERSION_FAILURE ="onInstallConversionFailure";
    final static String AF_ON_INSTALL_CONVERSION_DATA_LOADED ="onInstallConversionDataLoaded";
    final static String NO_DOMAINS = "no domains in the domains array";


    final static String INVITE_FAIL = "Could not create invite link";
    final static String INVITE_CHANNEL = "channel";
    final static String INVITE_CAMPAIGN = "campaign";
    final static String INVITE_REFERRER = "referrerName";
    final static String INVITE_IMAGEURL = "referrerImageURL";
    final static String INVITE_CUSTOMERID = "customerID";
    final static String INVITE_DEEPLINK = "baseDeepLink";
    final static String INVITE_BRAND_DOMAIN = "brandDomain";
    final static String PROMOTE_ID = "promotedAppId";

    //RECEIPT VALIDATION
    final static String PUBLIC_KEY = "publicKey";
    final static String SIGNATURE = "signature";
    final static String PURCHASE_DATA = "purchaseData";
    final static String PRICE = "price";
    final static String CURRENCY = "currency";
    final static String ADDITIONAL_PARAMETERS = "additionalParameters";
    final static String NO_PARAMETERS_ERROR = "Please provide purchase parameters";
    final static String VALIDATE_SUCCESS = "In-App Purchase Validation success";
    final static String VALIDATE_FAILED = "In-App Purchase Validation failed with error: ";
}
