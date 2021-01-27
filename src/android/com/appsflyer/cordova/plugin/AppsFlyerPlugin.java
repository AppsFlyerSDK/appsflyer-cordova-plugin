package com.appsflyer.cordova.plugin;

import android.net.Uri;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.EmptyStackException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerProperties;
import com.appsflyer.CreateOneLinkHttpTask;
import com.appsflyer.attribution.AppsFlyerRequestListener;
import com.appsflyer.deeplink.DeepLinkListener;
import com.appsflyer.deeplink.DeepLinkResult;
import com.appsflyer.share.CrossPromotionHelper;
import com.appsflyer.share.LinkGenerator;
import com.appsflyer.share.ShareInviteHelper;
import com.appsflyer.AppsFlyerInAppPurchaseValidatorListener;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.util.Log;

import static com.appsflyer.cordova.plugin.AppsFlyerConstants.*;

public class AppsFlyerPlugin extends CordovaPlugin {

    private CallbackContext mConversionListener = null;
    private CallbackContext mAttributionDataListener = null;
    private CallbackContext mDeepLinkListener = null;
    //    private Map<String, String> mAttributionData = null;
    private CallbackContext mInviteListener = null;
    private Uri intentURI = null;
    //    private Uri newIntentURI = null;
    private Activity c;

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
    public boolean execute(final String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
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
        }

        return false;
    }

    /**
     * register listener for unified deep link.
     *
     * @param callbackContext
     * @return
     */
    private boolean registerDeepLink(CallbackContext callbackContext) {
        if (mDeepLinkListener == null) {
            mDeepLinkListener = callbackContext;
        }
        return true;
    }


    /**
     * check if the app was launched from deep link after init()
     */
    private void trackAppLaunch() {
        c = this.cordova.getActivity();
        intentURI = cordova.getActivity().getIntent().getData();
        if (intentURI != null) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        AppsFlyerLib.getInstance().performOnAppAttribution(cordova.getContext(), new URI(intentURI.toString()));
                    } catch (URISyntaxException e) {
                        e.printStackTrace();
                    }
                }
            });
        }
        AppsFlyerLib.getInstance().logEvent(c, null, null);
    }

    /**
     * Get the deeplink data
     *
     * @param callbackContext Success callback - called after receiving data on App Open Attribution.
     *                        Error callback - called when error occurs.
     * @return
     */
    private boolean registerOnAppOpenAttribution(final CallbackContext callbackContext) {
        if (mAttributionDataListener == null) {
            mAttributionDataListener = callbackContext;
        }
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
        String devKey = null;
        boolean isConversionData;
        boolean isDebug = false;
        boolean isDeepLinking;
        AppsFlyerConversionListener gcdListener = null;

        AppsFlyerProperties.getInstance().set(AppsFlyerProperties.LAUNCH_PROTECT_ENABLED, false);
        AppsFlyerLib instance = AppsFlyerLib.getInstance();

        try {
            final JSONObject options = args.getJSONObject(0);

            devKey = options.optString(AF_DEV_KEY, "");
            isConversionData = options.optBoolean(AF_CONVERSION_DATA, false);

            if (devKey.trim().equals("")) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_DEVKEY_FOUND));
            }

            isDebug = options.optBoolean(AF_IS_DEBUG, false);

            if (options.has(AF_COLLECT_ANDROID_ID)) {
                AppsFlyerLib.getInstance().setCollectAndroidID(options.optBoolean(AF_COLLECT_ANDROID_ID, true));
            }
            if (options.has(AF_COLLECT_IMEI)) {
                AppsFlyerLib.getInstance().setCollectIMEI(options.optBoolean(AF_COLLECT_IMEI, true));
            }
            isDeepLinking = options.optBoolean(AF_ON_DEEP_LINKING, false);
            if (isDeepLinking) {
                instance.subscribeForDeepLink(registerDeepLinkListener());
            }

            instance.setDebugLog(isDebug);

            if (isDebug == true) {
                Log.d("AppsFlyer", "Starting Tracking");
            }

            if (isConversionData == true) {

                if (mConversionListener == null) {
                    mConversionListener = callbackContext;
                }

                gcdListener = registerConversionListener(instance);
            } else {
                //callbackContext.success(SUCCESS);
            }

            instance.init(devKey, gcdListener, cordova.getActivity());

            trackAppLaunch();


            if (mConversionListener == null) {
                instance.start(c.getApplication(), devKey, new AppsFlyerRequestListener() {
                    @Override
                    public void onSuccess() {
                        callbackContext.success(SUCCESS);
                    }

                    @Override
                    public void onError(int i, String s) {
                        callbackContext.error(FAILURE);
                    }
                });
            } else {
                instance.start(c.getApplicationContext());
            }


            instance.start(c.getApplicationContext());

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
                        deepLinkObj.put("data", deepLinkResult.getDeepLink().toString());
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
            result.setKeepCallback(false);
            mConversionListener.sendPluginResult(result);
            mConversionListener = null;
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

        try {
            final JSONObject options = args.getJSONObject(0);

            channel = options.optString(INVITE_CHANNEL, "");
            campaign = options.optString(INVITE_CAMPAIGN, "");
            referrerName = options.optString(INVITE_REFERRER, "");
            referrerImageUrl = options.optString(INVITE_IMAGEURL, "");
            customerID = options.optString(INVITE_CUSTOMERID, "");
            baseDeepLink = options.optString(INVITE_DEEPLINK, "");

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

    /**
     * @param parameters      Comma separated array of partners that need to be excluded
     * @param callbackContext
     */
    private boolean setSharingFilter(JSONArray parameters, CallbackContext callbackContext) {
        try {
            String partners = parameters.getString(0);
            if (partners.equals("null") || parameters.length() == 0) {
                callbackContext.error(FAILURE);
                return true;
            }
            partners = partners.substring(1, partners.length() - 1);
            partners = partners.replaceAll(" ", "");

            String[] networksArray = partners.split("[ ,]");
            for (String partner : networksArray) {
                partner = partner.substring(1, partner.length() - 1);
            }
            AppsFlyerLib.getInstance().setSharingFilter(networksArray);
            callbackContext.success(SUCCESS);

        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(FAILURE);
        }

        return true;
    }

    /**
     * Used by advertisers to exclude all networks/integrated partners from getting data
     */
    private boolean setSharingFilterForAllPartners(CallbackContext callbackContext) {
        AppsFlyerLib.getInstance().setSharingFilterForAllPartners();
        callbackContext.success(SUCCESS);
        return true;
    }

    /**
     * Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
     * Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases
     *
     * @param purchase info, success and failure callbacks
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

            if (publicKey == "" || signature == "" || purchaseData == "" || price == "" || currency == "") {
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
        try {
            String str = parameters.getString(0);
            String[] domains = stringToArray(str);
            if (domains.length == 0 || parameters.length() == 0) {
                callbackContext.error(FAILURE);
                return true;
            }
            AppsFlyerLib.getInstance().setOneLinkCustomDomain(domains);
            callbackContext.success(SUCCESS);

        } catch (JSONException e) {
            e.printStackTrace();
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
        try {
            String str = args.getString(0);
            String[] emails = stringToArray(str);
            AppsFlyerLib.getInstance().setUserEmails(emails);
            callbackContext.success(SUCCESS);
        } catch (Exception e) {
            e.printStackTrace();
        }

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
            String[] path = stringToArray(pathStr);
            AppsFlyerLib.getInstance().addPushNotificationDeepLinkPath(path);
            Log.d("AppsFlyer", path.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    /**
     * takes string representation of a string array and converts it to an array. use this method because old version of cordova cannot pass an array to native.
     * newer versions can, but can break flow to older users
     *
     * @param str
     * @return String array
     */
    private String[] stringToArray(String str) {
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

}
