package com.appsflyer.cordova.plugin;

/**
 * Constants used by the Android plugin (RPC event types, plugin info).
 */

public class AppsFlyerConstants {

    final static String PLUGIN_VERSION = "6.17.5";

    /** Event type: install conversion data loaded */
    final static String AF_ON_INSTALL_CONVERSION_DATA_LOADED = "onInstallConversionDataLoaded";
    /** Event type: install conversion failure */
    final static String AF_ON_INSTALL_CONVERSION_FAILURE = "onInstallConversionFailure";
    /** Event type: deep link */
    final static String AF_DEEP_LINK = "onDeepLinking";
    /** Event type: session ready */
    final static String AF_ON_SESSION_READY = "onSessionReady";
    /** Status value for event payloads */
    final static String AF_SUCCESS = "success";
}
