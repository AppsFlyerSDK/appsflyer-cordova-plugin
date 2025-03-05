package com.appsflyer.cordova.plugin;

import static com.appsflyer.cordova.plugin.AppsFlyerConstants.ADDITIONAL_PARAMETERS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_COLLECT_ANDROID_ID;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_COLLECT_IMEI;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_CONVERSION_DATA;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_DEEP_LINK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_DEV_KEY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_IS_DEBUG;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_APP_OPEN_ATTRIBUTION;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_ATTRIBUTION_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_DEEP_LINKING;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.SHOULD_START_SDK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_DATA_LOADED;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_SUCCESS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.CURRENCY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_CAMPAIGN;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_CHANNEL;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_CUSTOMERID;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_DEEPLINK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_FAIL;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_IMAGEURL;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_REFERRER;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.INVITE_BRAND_DOMAIN;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_CUSTOMER_ID;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_DEVKEY_FOUND;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_EVENT_NAME_FOUND;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_PARAMETERS_ERROR;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_VALID_TOKEN;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PRICE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PROMOTE_ID;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PUBLIC_KEY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PURCHASE_DATA;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.SIGNATURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.SUCCESS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.VALIDATE_FAILED;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.VALIDATE_SUCCESS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PLUGIN_VERSION;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerInAppPurchaseValidatorListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;
import com.appsflyer.CreateOneLinkHttpTask;
import com.appsflyer.attribution.AppsFlyerRequestListener;
import com.appsflyer.deeplink.DeepLinkListener;
import com.appsflyer.deeplink.DeepLinkResult;
import com.appsflyer.share.CrossPromotionHelper;
import com.appsflyer.share.LinkGenerator;
import com.appsflyer.share.ShareInviteHelper;
import com.appsflyer.internal.platform_extension.Plugin;
import com.appsflyer.internal.platform_extension.PluginInfo;
import com.appsflyer.AppsFlyerConsent;
import com.appsflyer.MediationNetwork;
import com.appsflyer.AFAdRevenueData;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class AppsFlyerPlugin extends CordovaPlugin {

    private CallbackContext mConversionListener = null;
    private CallbackContext mAttributionDataListener = null;
    private CallbackContext mDeepLinkListener = null;
    private CallbackContext mInviteListener = null;
    private Uri intentURI = null;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    /**
     * Called when the activity receives a new intent.
     */
    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        cordova.getActivity().setIntent(intent);
    }

    /**
     * @param action          The action name to call into.
     * @param args            Arguments to pass into the native environment.
     * @param callbackContext Success and Error function callback (optionally with an error/success parameter)
     * @return
     * @throws JSONException
     */
    @Override
    public boolean execute(final String action, JSONArray args, CallbackContext callbackContext) {
        Log.d("AppsFlyer", "Executing...");
        if ("setCurrencyCode".equals(action)) {
            return setCurrencyCode(args);
        } else if ("registerOnAppOpenAttribution".equals(action)) {
            return registerOnAppOpenAttribution(callbackContext);
        } else if ("registerDeepLink".equals(action)) {
            return registerDeepLink(callbackContext);
        } else if ("setAppUserId".equals(action)) {
            return setAppUserId(args, callbackContext);
        } else if ("getAppsFlyerUID".equals(action)) {
            return getAppsFlyerUID(callbackContext);
        } else if ("anonymizeUser".equals(action)) {
            return anonymizeUser(args);
        } else if ("Stop".equals(action)) {
            return stop(args);
        } else if ("initSdk".equals(action)) {
            return initSdk(args, callbackContext);
        } else if ("startSdk".equals(action)) {
            return startSdk();
        } else if ("logEvent".equals(action)) {
            return logEvent(args, callbackContext);
        } else if ("updateServerUninstallToken".equals(action)) {
            return updateServerUninstallToken(args, callbackContext);
        } else if ("setAppInviteOneLinkID".equals(action)) {
            return setAppInviteOneLinkID(args, callbackContext);
        } else if ("generateInviteLink".equals(action)) {
            return generateInviteLink(args, callbackContext);
        } else if ("logCrossPromotionImpression".equals(action)) {
            return logCrossPromotionImpression(args, callbackContext);
        } else if ("logCrossPromotionAndOpenStore".equals(action)) {
            return logAndOpenStore(args, callbackContext);
        } else if ("getSdkVersion".equals(action)) {
            return getSdkVersion(callbackContext);
        } else if ("setSharingFilterForPartners".equals(action)) {
            return setSharingFilterForPartners(args);
        } else if ("setSharingFilter".equals(action)) {
            return setSharingFilter(args, callbackContext);
        } else if ("setSharingFilterForAllPartners".equals(action)) {
            return setSharingFilterForAllPartners(callbackContext);
        } else if ("validateAndLogInAppPurchase".equals(action)) {
            return validateAndLogInAppPurchase(args, callbackContext);
        } else if ("setOneLinkCustomDomains".equals(action)) {
            return setOneLinkCustomDomains(args, callbackContext);
        } else if ("enableFacebookDeferredApplinks".equals(action)) {
            return enableFacebookDeferredApplinks(args);
        } else if ("setPhoneNumber".equals(action)) {
            return setPhoneNumber(args, callbackContext);
        } else if ("setUserEmails".equals(action)) {
            return setUserEmails(args, callbackContext);
        } else if ("setHost".equals(action)) {
            return setHost(args);
        } else if ("addPushNotificationDeepLinkPath".equals(action)) {
            return addPushNotificationDeepLinkPath(args);
        } else if ("setResolveDeepLinkURLs".equals(action)) {
            return setResolveDeepLinkURLs(args);
        } else if ("setDisableAdvertisingIdentifier".equals(action)) {
            return setDisableAdvertisingIdentifier(args, callbackContext);
        } else if ("setAdditionalData".equals(action)) {
            return setAdditionalData(args);
        } else if ("setPartnerData".equals(action)) {
            return setPartnerData(args);
        } else if ("sendPushNotificationData".equals(action)) {
            return sendPushNotificationData(args);
        } else if ("setDisableNetworkData".equals(action)) {
            return setDisableNetworkData(args);
        } else if ("setConsentData".equals(action)) {
            return setConsentData(args);
        } else if ("enableTCFDataCollection".equals(action)) {
            return enableTCFDataCollection(args);
        } else if ("logAdRevenue".equals(action)) {
            return logAdRevenue(args);
        }
        return false;
    }

        /**
         * log AdRevenue event
         *
         * @param args - event params
         * @return true
         */
        private boolean logAdRevenue(JSONArray args) {
            cordova.getThreadPool().execute(() -> {
                Map<String, Object> additionalParameters = null;
                try {
                    if(!args.get(0).equals(null)){
                        JSONObject afAdRevenueDataJsonObj = args.getJSONObject(0);
                        String monetizationNetwork = afAdRevenueDataJsonObj.optString("monetizationNetwork", null);
                        String mediationNetwork = afAdRevenueDataJsonObj.optString("mediationNetwork", null);
                        String currencyIso4217Code = afAdRevenueDataJsonObj.optString("currencyIso4217Code", null);
                        double revenue = afAdRevenueDataJsonObj.optDouble("revenue", -1);
                        MediationNetwork mediationNetworkEnumVal = null;

                        if(mediationNetwork != null){
                            for(MediationNetwork mediationNetworkEnum: MediationNetwork.values()){
                                if(mediationNetworkEnum.getValue().equals(mediationNetwork)){
                                    mediationNetworkEnumVal = mediationNetworkEnum;
                                    break;
                                }
                            }
                        }

                        if(!args.get(1).equals(null)){
                            JSONObject additionalParametersJson = args.getJSONObject(1);
                            additionalParameters = toObjectMap(additionalParametersJson);
                        }
                        if(mediationNetworkEnumVal != null){
                            AFAdRevenueData afAdRevenueData = new AFAdRevenueData(monetizationNetwork, mediationNetworkEnumVal, currencyIso4217Code, revenue);
                            AppsFlyerLib.getInstance().logAdRevenue(afAdRevenueData, additionalParameters);
                        }
                        else{
                           Log.d("AppsFlyer", "Could not log Ad-Revenue event, bad inputs");
                        }
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            });
            return true;
        }

    /**
     * set consent data according to GDPR if applies or not.
     *
     * @param args - json object that represents consent data object.
     * @return true
     */
    private boolean setConsentData(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                JSONObject consentData = args.getJSONObject(0);
                Boolean isUserSubjectToGDPR = getBooleanOrNull(consentData, "isUserSubjectToGDPR");
                Boolean hasConsentForDataUsage = getBooleanOrNull(consentData, "hasConsentForDataUsage");;
                Boolean hasConsentForAdsPersonalization = getBooleanOrNull(consentData, "hasConsentForAdsPersonalization");;
                Boolean hasConsentForAdStorage = getBooleanOrNull(consentData, "hasConsentForAdStorage");;

                AppsFlyerConsent consent = new AppsFlyerConsent(isUserSubjectToGDPR, hasConsentForDataUsage, hasConsentForAdsPersonalization, hasConsentForAdStorage);
                AppsFlyerLib.getInstance().setConsentData(consent);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        });
        return true;
    }

    private Boolean getBooleanOrNull(JSONObject consentData, String key) {
        try {
            return consentData.getBoolean(key);
        } catch (Throwable ignore) {}
        return null;
    }

    /**
     * set collect tcf data or not.
     *
     * @param args - json object that holds the boolean value.
     * @return true
     */
    private boolean enableTCFDataCollection(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                boolean enable = args.getBoolean(0);
                AppsFlyerLib.getInstance().enableTCFDataCollection(enable);
            } catch (JSONException e) {
                e.printStackTrace();
            }

        });
        return true;
    }

    private boolean setDisableNetworkData(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                boolean disable = args.getBoolean(0);
                AppsFlyerLib.getInstance().setDisableNetworkData(disable);
            } catch (JSONException e) {
                e.printStackTrace();
            }

        });
        return true;
    }

    private boolean sendPushNotificationData(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                JSONObject js = args.getJSONObject(0);
                Intent i = cordova.getActivity().getIntent();
                if (i != null) {
                    i.putExtras(jsonToBundle(js));
                    cordova.getActivity().setIntent(i);
                    AppsFlyerLib.getInstance().sendPushNotificationData(cordova.getActivity());
                }
            } catch (JSONException e) {
                Log.d("AppsFlyer", "Could not parse json to bundle");
            }
        });
        return true;
    }

    /**
     * Disable collection of Google, Amazon and Open advertising ids (GAID, AAID, OAID).
     *
     * @param args
     * @param callbackContext Success callback - called after value is set.
     *                        *                        Error callback - called when error occurs.
     * @return true
     */
    private boolean setDisableAdvertisingIdentifier(JSONArray args, CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    boolean disable = args.getBoolean(0);
                    AppsFlyerLib.getInstance().setDisableAdvertisingIdentifiers(disable);
                    callbackContext.success(SUCCESS);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
        return true;
    }

    /**
     * register listener for unified deep link.
     *
     * @param callbackContext
     * @return
     */
    private boolean registerDeepLink(CallbackContext callbackContext) {
        mDeepLinkListener = callbackContext;
        return true;
    }

    /**
     * Get the deeplink data
     *
     * @param callbackContext Success callback - called after receiving data on App Open Attribution.
     *                        Error callback - called when error occurs.
     * @return
     */
    private boolean registerOnAppOpenAttribution(final CallbackContext callbackContext) {
        mAttributionDataListener = callbackContext;
        return true;
    }

    /**
     * initialize the SDK.
     *
     * @param args            SDK configuration
     * @param callbackContext Success callback - called after successful SDK initialization.
     *                        errorCB: Error callback - called when error occurs during initialization.
     */
    private boolean initSdk(final JSONArray args, final CallbackContext callbackContext) {

        try {
            final JSONObject options = args.getJSONObject(0);

            // assert if AF_DEV_KEY is null/empty string
            String devKey = options.optString(AF_DEV_KEY, "");
            if (devKey.trim().equals("")) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_DEVKEY_FOUND));
            }

            // assign some values
            AppsFlyerConversionListener gcdListener = null;
            AppsFlyerProperties.getInstance().set(AppsFlyerProperties.LAUNCH_PROTECT_ENABLED, false);
            AppsFlyerLib instance = AppsFlyerLib.getInstance();
            boolean isConversionData = options.optBoolean(AF_CONVERSION_DATA, false);
            boolean isDebug = options.optBoolean(AF_IS_DEBUG, false);
            boolean isDeepLinking = options.optBoolean(AF_ON_DEEP_LINKING, false);
            boolean shouldStartSDK = options.optBoolean(SHOULD_START_SDK, true);

            // trigger some setters
            if (options.has(AF_COLLECT_ANDROID_ID)) {
                AppsFlyerLib.getInstance().setCollectAndroidID(options.optBoolean(AF_COLLECT_ANDROID_ID, true));
            }
            if (options.has(AF_COLLECT_IMEI)) {
                AppsFlyerLib.getInstance().setCollectIMEI(options.optBoolean(AF_COLLECT_IMEI, true));
            }
            if (isDeepLinking) {
                instance.subscribeForDeepLink(registerDeepLinkListener());
            }

            setPluginInfo();
            instance.setDebugLog(isDebug);

            if (isDebug) {
                Log.d("AppsFlyer", "Starting Tracking");
            }

            if (isConversionData) {

                if (mConversionListener == null) {
                    mConversionListener = callbackContext;
                }

                gcdListener = registerConversionListener(instance);

            }
            // init appsflyerSDK
            instance.init(devKey, gcdListener, cordova.getActivity());

            if(shouldStartSDK){
                if (mConversionListener == null) {
                    instance.start(cordova.getActivity(), devKey, new AppsFlyerRequestListener() {
                        @Override
                        public void onSuccess() {
                            callbackContext.success(SUCCESS);
                        }

                        @Override
                        public void onError(int i, String s) {
                            callbackContext.error(FAILURE);
                        }
                    });
                }
                else{
                     startSdk();
                }
            }
            if (gcdListener != null) {
                sendPluginNoResult(callbackContext);
            } else {
                callbackContext.success(SUCCESS);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return true;
    }

    /**
     * start the SDK.
     */
    private boolean startSdk() {
        AppsFlyerLib instance = AppsFlyerLib.getInstance();
        instance.start(cordova.getActivity());
        return true;
    }

    /**
     * register unified deep link listener
     *
     * @return deepLink listener
     */
    private DeepLinkListener registerDeepLinkListener() {
        return new DeepLinkListener() {
            @Override
            public void onDeepLinking(@NonNull DeepLinkResult deepLinkResult) {
                try {
                    DeepLinkResult.Error dlError = deepLinkResult.getError();
                    JSONObject deepLinkObj = new JSONObject();
                    deepLinkObj.put("deepLinkStatus", deepLinkResult.getStatus());
                    deepLinkObj.put("type", AF_DEEP_LINK);
                    if (dlError != null) {
                        deepLinkObj.put("status", AF_FAILURE);
                        deepLinkObj.put("data", dlError.toString());
                    } else {
                        deepLinkObj.put("status", AF_SUCCESS);
                        if (deepLinkResult.getStatus() == DeepLinkResult.Status.FOUND) {
                            deepLinkObj.put("data", deepLinkResult.getDeepLink().getClickEvent());
                            deepLinkObj.put("isDeferred", deepLinkResult.getDeepLink().isDeferred());
                        }
                    }
                    sendEvent(deepLinkObj);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };
    }

    /**
     * GCD listener. handles success and errors in conversion data .
     *
     * @param instance
     * @return
     */
    private AppsFlyerConversionListener registerConversionListener(AppsFlyerLib instance) {
        return new AppsFlyerConversionListener() {

            @Override
            public void onConversionDataSuccess(Map<String, Object> conversionData) {
                handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED, conversionData, null);
            }

            @Override
            public void onConversionDataFail(String errorMessage) {
                handleError(AF_ON_INSTALL_CONVERSION_FAILURE, errorMessage);
            }

            @Override
            public void onAppOpenAttribution(Map<String, String> attributionData) {
                handleSuccess(AF_ON_APP_OPEN_ATTRIBUTION, null, attributionData);
            }

            @Override
            public void onAttributionFailure(String errorMessage) {
                handleError(AF_ON_ATTRIBUTION_FAILURE, errorMessage);
            }

        };
    }

    /**
     * Handle error while sending conversion data
     *
     * @param eventType    error type ("onAttributionFailure").
     * @param errorMessage error message ().
     */
    private void handleError(String eventType, String errorMessage) {

        try {
            JSONObject obj = new JSONObject();

            obj.put("status", AF_FAILURE);
            obj.put("type", eventType);
            obj.put("data", errorMessage);

            sendEvent(obj);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    /**
     * Sending success conversion data
     *
     * @param eventType
     * @param conversionData
     * @param attributionData
     */
    private void handleSuccess(String eventType, Map<String, Object> conversionData, Map<String, String> attributionData) {
        JSONObject obj = new JSONObject();

        try {
            JSONObject data = new JSONObject(conversionData == null ? attributionData : conversionData);
            obj.put("status", AF_SUCCESS);
            obj.put("type", eventType);
            obj.put("data", data);

            sendEvent(obj);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    /**
     * send the event as a data object to the JavaScript side
     *
     * @param params
     */
    private void sendEvent(JSONObject params) {

        final String jsonStr = params.toString();

        if (
                (params.optString("type") == AF_ON_ATTRIBUTION_FAILURE
                        || params.optString("type") == AF_ON_APP_OPEN_ATTRIBUTION) && mAttributionDataListener != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
            result.setKeepCallback(true);
            mAttributionDataListener.sendPluginResult(result);
        } else if (
                (params.optString("type") == AF_ON_INSTALL_CONVERSION_DATA_LOADED
                        || params.optString("type") == AF_ON_INSTALL_CONVERSION_FAILURE)
                        && mConversionListener != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
            result.setKeepCallback(true);
            mConversionListener.sendPluginResult(result);
        } else if (
                params.optString("type") == AF_DEEP_LINK
                        && mDeepLinkListener != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
            result.setKeepCallback(true);
            mDeepLinkListener.sendPluginResult(result);
        }
    }

    /**
     * Track rich in-app events
     *
     * @param parameters      eventName: custom event name, is presented in your dashboard.
     *                        eventValue: event details
     * @param callbackContext Success callback - called after successful event tracking.
     *                        Error callback - called when error occurs.
     * @return
     */
    private boolean logEvent(JSONArray parameters, final CallbackContext callbackContext) {
        String eventName;
        Map<String, Object> eventValues = null;
        try {
            eventName = parameters.getString(0);

            if (parameters.length() > 1 && !parameters.get(1).equals(null)) {
                JSONObject jsonEventValues = parameters.getJSONObject(1);
                eventValues = jsonToMap(jsonEventValues.toString());
            }
        } catch (JSONException e) {
            e.printStackTrace();
            return true;
        }

        if (eventName == null || eventName.trim().length() == 0) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_EVENT_NAME_FOUND));
            return true;
        }

        Context c = this.cordova.getActivity().getApplicationContext();
        AppsFlyerLib.getInstance().logEvent(c, eventName, eventValues, callbackContext == null ? null : new AppsFlyerRequestListener() {
            @Override
            public void onSuccess() {
                callbackContext.success(eventName);
            }

            @Override
            public void onError(int i, String s) {
                callbackContext.error(s);
            }
        });

        return true;
    }

    /**
     * Sets new currency code.
     *
     * @param parameters currencyId: ISO 4217 Currency Codes.
     * @return
     */
    private boolean setCurrencyCode(JSONArray parameters) {

        String currencyId = null;
        try {
            currencyId = parameters.getString(0);
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        if (currencyId == null || currencyId.length() == 0) {
            return true; //TODO error
        }
        AppsFlyerLib.getInstance().setCurrencyCode(currencyId);

        return true;
    }

    /**
     * Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs.
     *
     * @param parameters      customerUserId
     * @param callbackContext Success and Error callbacks.
     * @return
     */
    private boolean setAppUserId(JSONArray parameters, CallbackContext callbackContext) {

        try {
            String customeUserId = parameters.getString(0);
            if (customeUserId == null || customeUserId.length() == 0) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_CUSTOMER_ID));
                return true;
            }
            AppsFlyerLib.getInstance().setCustomerUserId(customeUserId);

            PluginResult r = new PluginResult(PluginResult.Status.OK);
            r.setKeepCallback(false);
            callbackContext.sendPluginResult(r);
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }

        return true;
    }

    /**
     * Get the Appsflyer ID
     *
     * @param callbackContext
     * @return
     */
    private boolean getAppsFlyerUID(CallbackContext callbackContext) {

        String id = AppsFlyerLib.getInstance().getAppsFlyerUID(cordova.getActivity().getApplicationContext());
        PluginResult r = new PluginResult(PluginResult.Status.OK, id);
        r.setKeepCallback(false);
        callbackContext.sendPluginResult(r);

        return true;
    }

    /**
     * End User Opt-Out from AppsFlyer analytics.
     *
     * @param parameters boolean isDisabled
     * @return
     */
    private boolean anonymizeUser(JSONArray parameters) {

        try {
            boolean isDisabled = parameters.getBoolean(0);
            AppsFlyerLib.getInstance().anonymizeUser(isDisabled);
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        return true;
    }

    /**
     * Shut down all SDK tracking
     *
     * @param parameters boolean isStopTracking
     * @return
     */
    private boolean stop(JSONArray parameters) {

        try {
            boolean isStop = parameters.getBoolean(0);
            AppsFlyerLib.getInstance().stop(isStop, cordova.getActivity().getApplicationContext());
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        return true;
    }

    /**
     * Converts Json to Map.
     *
     * @param inputString
     * @return
     */
    private static Map<String, Object> jsonToMap(String inputString) {
        Map<String, Object> newMap = new HashMap<String, Object>();

        try {
            JSONObject jsonObject = new JSONObject(inputString);
            Iterator iterator = jsonObject.keys();
            while (iterator.hasNext()) {
                String key = (String) iterator.next();
                newMap.put(key, jsonObject.getString(key));

            }
        } catch (JSONException e) {
            return null;
        }

        return newMap;
    }

    /**
     * (Android) Allows to pass GCM/FCM Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Uninstall Tracking.
     *
     * @param parameters      token
     * @param callbackContext null in this case. We dont use callbacks for this method
     * @return
     */
    private boolean updateServerUninstallToken(JSONArray parameters, CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                String token = parameters.optString(0);
                if (token != null && token.length() > 0) {
                    Context c = cordova.getActivity().getApplicationContext();
                    AppsFlyerLib.getInstance().updateServerUninstallToken(c, token);
                    callbackContext.success(SUCCESS);
                } else {
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_VALID_TOKEN));
                }
            }
        });

        return true;
    }

    // USER INVITE

    /**
     * Set AppsFlyer’s OneLink ID
     *
     * @param parameters      oneLinkID.
     * @param callbackContext null in this case. We dont use callbacks for this method
     * @return
     */
    private boolean setAppInviteOneLinkID(JSONArray parameters, CallbackContext callbackContext) {
        try {
            String oneLinkID = parameters.getString(0);
            if (oneLinkID == null || oneLinkID.length() == 0) {
                callbackContext.error(FAILURE);
                return true;
            }
            AppsFlyerLib.getInstance().setAppInviteOneLink(oneLinkID);
            callbackContext.success(SUCCESS);
        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(FAILURE);
            return true;
        }
        return true;
    }

    /**
     * Allowing your existing users to invite their friends and contacts as new users to your app
     *
     * @param args            Parameters for Invite link
     * @param callbackContext Success callback (generated link) and Error callback.
     * @return
     */
    private boolean generateInviteLink(JSONArray args, CallbackContext callbackContext) {

        String channel = null;
        String campaign = null;
        String referrerName = null;
        String referrerImageUrl = null;
        String customerID = null;
        String baseDeepLink = null;
        String brandDomain = null;

        try {
            final JSONObject options = args.getJSONObject(0);

            channel = options.optString(INVITE_CHANNEL, "");
            campaign = options.optString(INVITE_CAMPAIGN, "");
            referrerName = options.optString(INVITE_REFERRER, "");
            referrerImageUrl = options.optString(INVITE_IMAGEURL, "");
            customerID = options.optString(INVITE_CUSTOMERID, "");
            baseDeepLink = options.optString(INVITE_DEEPLINK, "");
            brandDomain = options.optString(INVITE_BRAND_DOMAIN, "");

            Context context = this.cordova.getActivity().getApplicationContext();
            LinkGenerator linkGenerator = ShareInviteHelper.generateInviteUrl(context);

            if (channel != null && channel != "") {
                linkGenerator.setChannel(channel);
            }
            if (campaign != null && campaign != "") {
                linkGenerator.setCampaign(campaign);
            }
            if (referrerName != null && referrerName != "") {
                linkGenerator.setReferrerName(referrerName);
            }
            if (referrerImageUrl != null && referrerImageUrl != "") {
                linkGenerator.setReferrerImageURL(referrerImageUrl);
            }
            if (customerID != null && customerID != "") {
                linkGenerator.setReferrerCustomerId(customerID);
            }
            if (baseDeepLink != null && baseDeepLink != "") {
                linkGenerator.setBaseDeeplink(baseDeepLink);
            }
            if (brandDomain != null && brandDomain != "") {
                linkGenerator.setBrandDomain(brandDomain);
            }

            if (options.length() > 1 && !options.get("userParams").equals("")) {
                JSONObject jsonCustomValues = options.getJSONObject("userParams");

                Iterator<?> keys = jsonCustomValues.keys();

                while (keys.hasNext()) {
                    String key = (String) keys.next();
                    Object keyvalue = jsonCustomValues.get(key);
                    linkGenerator.addParameter(key, keyvalue.toString());
                }
            }

            linkGenerator.generateLink(context, new inviteCallbacksImpl());
            mInviteListener = callbackContext;
            sendPluginNoResult(mInviteListener);
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, INVITE_FAIL));
        }
        return true;
    }

    /**
     * Callback function for the link generator
     */
    private class inviteCallbacksImpl implements CreateOneLinkHttpTask.ResponseListener {
        @Override
        public void onResponse(String s) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, s);
            result.setKeepCallback(false);
            mInviteListener.sendPluginResult(result);
        }

        @Override
        public void onResponseError(String s) {

        }
    }

    /**
     * Track cross promotion impression. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
     *
     * @param parameters      appId: Promoted Application ID
     *                        campaign: Promoted Campaign
     * @param callbackContext
     * @return
     */
    public boolean logCrossPromotionImpression(JSONArray parameters, CallbackContext callbackContext) {
        String promotedAppId = null;
        String campaign = null;

        try {
            final JSONObject options = parameters.getJSONObject(0);

            promotedAppId = options.optString(PROMOTE_ID, "");
            campaign = options.optString(INVITE_CAMPAIGN, "");

            if (promotedAppId != null && promotedAppId != "") {
                Context context = this.cordova.getActivity().getApplicationContext();
                CrossPromotionHelper.logCrossPromoteImpression(context, promotedAppId, campaign);
            } else {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromoted App ID Not set"));
                return true;
            }

        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromotionImpression Failed"));
        }
        return true;

    }

    /**
     * Use this call to track the click and launch the app store's app page (via Browser)
     *
     * @param parameters      promotedAppId: Promoted Application ID
     *                        campaign: Promoted Campaign
     *                        userParams: Additional Parameters to track
     * @param callbackContext
     * @return
     */
    public boolean logAndOpenStore(JSONArray parameters, CallbackContext callbackContext) {
        String promotedAppId = null;
        String campaign = null;
        Map<String, String> userParams = null;
        try {
            promotedAppId = parameters.getString(0);
            campaign = parameters.getString(1);
            if (promotedAppId != null && promotedAppId != "") {
                Context context = this.cordova.getActivity().getApplicationContext();
                if (!parameters.isNull(2)) {
                    Map<String, String> newUserParams = new HashMap<String, String>();
                    JSONObject usrParams = parameters.optJSONObject(2);
                    Iterator<?> keys = usrParams.keys();
                    while (keys.hasNext()) {
                        String key = (String) keys.next();
                        Object keyvalue = usrParams.get(key);
                        newUserParams.put(key, keyvalue.toString());
                    }
                    userParams = newUserParams;
                }
                CrossPromotionHelper.logAndOpenStore(context, promotedAppId, campaign, userParams);
            } else {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromoted App ID Not set"));
                return true;
            }
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromotion Failed"));
        }
        return true;
    }

    /**
     * Helper function to send a callback with no results.
     *
     * @param callbackContext
     */
    private void sendPluginNoResult(CallbackContext callbackContext) {
        PluginResult pluginResult = new PluginResult(
                PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }

    /**
     * Get the current SDK version
     *
     * @param callbackContext successCB: Success callback that returns the SDK version.
     * @return
     */
    private boolean getSdkVersion(CallbackContext callbackContext) {
        final String version = AppsFlyerLib.getInstance().getSdkVersion();
        final PluginResult result = new PluginResult(PluginResult.Status.OK, version);
        callbackContext.sendPluginResult(result);
        return true;
    }


    private boolean setSharingFilterForPartners(JSONArray parameters) {
        cordova.getThreadPool().execute(() -> {
            String[] networksArray = convertToStringArray(parameters);
            if (networksArray != null && networksArray.length > 0) {
                AppsFlyerLib.getInstance().setSharingFilterForPartners(networksArray);
            }
        });

        return true;
    }


    /**
     * @param parameters      Comma separated array of partners that need to be excluded
     * @param callbackContext
     */
    @Deprecated
    private boolean setSharingFilter(JSONArray parameters, CallbackContext callbackContext) {
        cordova.getThreadPool().execute(() -> {
            String[] networksArray = convertToStringArray(parameters);
            if (networksArray != null && networksArray.length > 0) {
                AppsFlyerLib.getInstance().setSharingFilter(networksArray);
            }
        });

        return true;
    }

    /**
     * Used by advertisers to exclude all networks/integrated partners from getting data
     */
    @Deprecated
    private boolean setSharingFilterForAllPartners(CallbackContext callbackContext) {
        AppsFlyerLib.getInstance().setSharingFilterForAllPartners();
        callbackContext.success(SUCCESS);
        return true;
    }

    /**
     * Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
     * Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases
     */
    public boolean validateAndLogInAppPurchase(JSONArray args, CallbackContext callbackContext) {
        String publicKey = "";
        String signature = "";
        String purchaseData = "";
        String price = "";
        String currency = "";
        Map<String, String> additionalParameters = null;
        JSONObject additionalParametersJson;

        try {
            final JSONObject purchaseInfo = args.getJSONObject(0);

            publicKey = purchaseInfo.optString(PUBLIC_KEY, "");
            signature = purchaseInfo.optString(SIGNATURE, "");
            purchaseData = purchaseInfo.optString(PURCHASE_DATA, "");
            price = purchaseInfo.optString(PRICE, "");
            currency = purchaseInfo.optString(CURRENCY, "");
            if (purchaseInfo.has(ADDITIONAL_PARAMETERS)) {
                additionalParametersJson = purchaseInfo.optJSONObject(ADDITIONAL_PARAMETERS);
                additionalParameters = toMap(additionalParametersJson);
            }

            if (publicKey.isEmpty() || signature.isEmpty() || purchaseData.isEmpty() || price.isEmpty() || currency.isEmpty()) {
                callbackContext.error(NO_PARAMETERS_ERROR);
                return true;
            }
        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(FAILURE);
            return true;
        }
        initInAppPurchaseValidatorListener(callbackContext);
        AppsFlyerLib.getInstance().validateAndLogInAppPurchase(this.cordova.getContext(), publicKey, signature, purchaseData, price, currency, additionalParameters);
        return true;
    }


    public void initInAppPurchaseValidatorListener(final CallbackContext callbackContext) {
        AppsFlyerLib.getInstance().registerValidatorListener(this.cordova.getContext(), new AppsFlyerInAppPurchaseValidatorListener() {
            @Override
            public void onValidateInApp() {
                callbackContext.success(VALIDATE_SUCCESS);

            }

            @Override
            public void onValidateInAppFailure(String error) {
                callbackContext.error(VALIDATE_FAILED + error);

            }
        });
    }

    /**
     * Set Onelink custom/branded domains
     * Use this API during the SDK Initialization to indicate branded domains.
     * For more information please refer to https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links
     *
     * @param parameters      array of strings
     * @param callbackContext success and error callbacks
     * @return
     */
    private boolean setOneLinkCustomDomains(JSONArray parameters, CallbackContext callbackContext) {

        String[] domains = convertToStringArray(parameters);
        if (domains != null && domains.length > 0) {
            AppsFlyerLib.getInstance().setOneLinkCustomDomain(domains);
            callbackContext.success(SUCCESS);
        } else {
            callbackContext.error(FAILURE);
        }
        return true;

    }


    /**
     * use this api If you need deep linking data from Facebook, deferred deep linking, Dynamic Product Ads, or reasons that
     * unrelated to attribution such as authentication, ad monetization, social sharing, user invites, etc.
     * More information here: https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration
     *
     * @param args: boolean value
     * @return
     */
    private boolean enableFacebookDeferredApplinks(JSONArray args) {
        try {
            boolean isEnabled = args.getBoolean(0);
            AppsFlyerLib.getInstance().enableFacebookDeferredApplinks(isEnabled);
            Log.d("AppsFlyer", "set enableFacebookDeferredApplinks to " + isEnabled);
        } catch (JSONException e) {
            e.printStackTrace();
            return true;
        }
        return true;
    }

    /**
     * Facebook Advanced Matching
     *
     * @param args:            Strings array of emails
     * @param callbackContext: success functions
     * @return
     */
    private boolean setUserEmails(JSONArray args, CallbackContext callbackContext) {
        cordova.getThreadPool().execute(() -> {
            try {
                String[] emails = convertToStringArray(args);
                if (emails == null || emails.length == 0) {
                    callbackContext.error(FAILURE);
                    return;
                }
                AppsFlyerLib.getInstance().setUserEmails(AppsFlyerProperties.EmailsCryptType.SHA256, emails);
                callbackContext.success(SUCCESS);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
        return true;
    }

    /**
     * Facebook Advanced Matching
     *
     * @param args:           phone number
     * @param callbackContext
     * @return
     */
    private boolean setPhoneNumber(JSONArray args, CallbackContext callbackContext) {
        try {
            String phoneNumber = args.getString(0);
            AppsFlyerLib.getInstance().setPhoneNumber(phoneNumber);
            Log.d("AppsFlyer", phoneNumber);
            callbackContext.success(SUCCESS);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    /**
     * set custom host prefix and host name
     *
     * @param args: host prefix and host name
     * @return
     */
    private boolean setHost(JSONArray args) {
        try {
            String prefix = args.getString(0);
            String name = args.getString(1);
            AppsFlyerLib.getInstance().setHost(prefix, name);
            Log.d("AppsFlyer", prefix + "." + name);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    private boolean addPushNotificationDeepLinkPath(JSONArray args) {
        try {
            String pathStr = args.getString(0);
            String[] path = convertToStringArray(args);
            if (path != null && path.length > 0) {
                AppsFlyerLib.getInstance().addPushNotificationDeepLinkPath(path);
                Log.d("AppsFlyer", path.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    /**
     * Use this API to get the OneLink from click domains that launch the app. Make sure to call this API before SDK initialization.
     *
     * @param args: urls
     */
    private boolean setResolveDeepLinkURLs(JSONArray args) {
        try {
            String[] urls = convertToStringArray(args);
            if (urls != null && urls.length > 0) {
                AppsFlyerLib.getInstance().setResolveDeepLinkURLs(urls);
                Log.d("AppsFlyer", urls.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    private boolean setAdditionalData(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                Map<String, Object> additionalData = toObjectMap(args.getJSONObject(0));
                AppsFlyerLib.getInstance().setAdditionalData(additionalData);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        });
        return true;
    }

    private boolean setPartnerData(JSONArray args) {
        cordova.getThreadPool().execute(() -> {
            try {
                String partnerId = args.getString(0);
                Map<String, Object> data = toObjectMap(args.getJSONObject(1));
                AppsFlyerLib.getInstance().setPartnerData(partnerId, data);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        });
        return true;
    }

    private void setPluginInfo(){
        PluginInfo pluginInfo = new PluginInfo(Plugin.CORDOVA, PLUGIN_VERSION);
        AppsFlyerLib.getInstance().setPluginInfo(pluginInfo);
    }

    /**
     * takes string representation of a string array and converts it to an array. use this method because old version of cordova cannot pass an array to native.
     * newer versions can, but can break flow to older users
     *
     * @param str
     * @return String array
     */
    private String[] stringToArray(@NonNull String str) {
        String[] realArr = null;
        str = str.substring(1, str.length() - 1);
        str = str.replaceAll(" ", "");
        realArr = str.split("[ ,]");
        for (String el : realArr) {
            el = el.substring(1, el.length() - 1);
            Log.i("element", el);
        }
        return realArr;
    }

    /**
     * this method get a JSONArray of strings and convert it to String array
     *
     * @param json JSONArray object that contains string elements
     * @return the provided JSONArray converted to String array
     * @throws JSONException
     */
    private String[] jsonArrayToStringArray(@NonNull JSONArray json) throws JSONException {
        if (json.length() == 0) {
            return null;
        }
        String[] arr = new String[json.length()];
        for (int i = 0; i < json.length(); i++) {
            arr[i] = json.getString(i);
        }
        return arr;
    }

    /**
     * This method get the JSONArray object from JS and convert it to String array.
     * The first element can be string representation of a string array or JSONArray of strings.
     *
     * @param json JSONArray object from JS.
     * @return String array or null
     */
    private String[] convertToStringArray(JSONArray json) {
        if (json == null || json.length() == 0) {
            return null;
        }

        String[] arr = null;

        try {
            Object obj = json.get(0);
            if (obj instanceof String) {
                arr = stringToArray((String) obj);
            } else if (obj instanceof JSONArray) {
                arr = jsonArrayToStringArray((JSONArray) obj);
            }
        } catch (JSONException | ClassCastException e) {
            e.printStackTrace();
            return null;
        }
        return arr;
    }

    private Map<String, String> toMap(JSONObject jsonobj) throws JSONException {
        Map<String, String> map = new HashMap<String, String>();
        Iterator<String> keys = jsonobj.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            String value = (String) jsonobj.get(key);
            map.put(key, value);
        }
        return map;
    }

    private Map<String, Object> toObjectMap(JSONObject jsonobj) throws JSONException {
        Map<String, Object> map = new HashMap<String, Object>();
        Iterator<String> keys = jsonobj.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            Object value = jsonobj.get(key);
            map.put(key, value);
        }
        return map;
    }

    private Bundle jsonToBundle(JSONObject json) throws JSONException {
        Bundle bundle = new Bundle();
        Iterator<String> iterator = json.keys();
        while (iterator.hasNext()) {
            String key = iterator.next();
            Object value = json.get(key);
            switch (value.getClass().getSimpleName()) {
                case "String":
                    bundle.putString(key, (String) value);
                    break;
                case "Integer":
                    bundle.putInt(key, (Integer) value);
                    break;
                case "Long":
                    bundle.putLong(key, (Long) value);
                    break;
                case "Boolean":
                    bundle.putBoolean(key, (Boolean) value);
                    break;
                case "JSONObject":
                    bundle.putBundle(key, jsonToBundle((JSONObject) value));
                    break;
                case "Float":
                    bundle.putFloat(key, (Float) value);
                    break;
                case "Double":
                    bundle.putDouble(key, (Double) value);
                    break;
                default:
                    bundle.putString(key, value.getClass().getSimpleName());
            }
        }
        return bundle;
        
    }
}
