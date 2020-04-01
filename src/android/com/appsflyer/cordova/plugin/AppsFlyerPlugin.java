package com.appsflyer.cordova.plugin;

import android.net.Uri;

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
import com.appsflyer.share.CrossPromotionHelper;
import com.appsflyer.share.LinkGenerator;
import com.appsflyer.share.ShareInviteHelper;
import com.appsflyer.AppsFlyerTrackingRequestListener;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;


import static com.appsflyer.cordova.plugin.AppsFlyerConstants.*;

public class AppsFlyerPlugin extends CordovaPlugin {

    private CallbackContext mConversionListener = null;
    private CallbackContext mAttributionDataListener = null;
    private Map<String, String> mAttributionData = null;
    private CallbackContext mInviteListener = null;
    private Uri intentURI = null;
    private Uri newIntentURI = null;
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
        cordova.getActivity().setIntent(intent);
        AppsFlyerLib.getInstance().sendDeepLinkData(cordova.getActivity());
    }

    @Override
    public boolean execute(final String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d("AppsFlyer", "Executing...");
        if ("setCurrencyCode".equals(action)) {
            return setCurrencyCode(args);
        } else if ("registerOnAppOpenAttribution".equals(action)) {
            return registerOnAppOpenAttribution(callbackContext);
        } else if ("setAppUserId".equals(action)) {
            return setAppUserId(args, callbackContext);
        } else if ("getAppsFlyerUID".equals(action)) {
            return getAppsFlyerUID(callbackContext);
        } else if ("setDeviceTrackingDisabled".equals(action)) {
            return setDeviceTrackingDisabled(args);
        } else if ("stopTracking".equals(action)) {
            return stopTracking(args);
        } else if ("initSdk".equals(action)) {
            return initSdk(args, callbackContext);
        } else if ("trackEvent".equals(action)) {
            return trackEvent(args, callbackContext);
        } else if ("setGCMProjectID".equals(action)) {
            return setGCMProjectNumber(args);
        } else if ("enableUninstallTracking".equals(action)) {
            return enableUninstallTracking(args, callbackContext);
        } else if ("updateServerUninstallToken".equals(action)) {
            return updateServerUninstallToken(args, callbackContext);
        } else if ("setAppInviteOneLinkID".equals(action)) {
            return setAppInviteOneLinkID(args, callbackContext);
        } else if ("generateInviteLink".equals(action)) {
            return generateInviteLink(args, callbackContext);
        } else if ("trackCrossPromotionImpression".equals(action)) {
            return trackCrossPromotionImpression(args, callbackContext);
        } else if ("trackAndOpenStore".equals(action)) {
            return trackAndOpenStore(args, callbackContext);
        } else if ("resumeSDK".equals(action)) {
            return onResume(args, callbackContext);
        }

        return false;
    }

    private void trackAppLaunch() {
        c = this.cordova.getActivity();
        AppsFlyerLib.getInstance().sendDeepLinkData(c);
        AppsFlyerLib.getInstance().trackEvent(c, null, null);
    }

    private boolean registerOnAppOpenAttribution(final CallbackContext callbackContext) {

        if (mAttributionDataListener == null) {
            mAttributionDataListener = callbackContext;
        }

        return true;
    }

    /**
     * @param args
     * @param callbackContext
     */
    private boolean initSdk(final JSONArray args, final CallbackContext callbackContext) {


        String devKey = null;
        boolean isConversionData;
        boolean isDebug = false;
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


            instance.setDebugLog(isDebug);

            if (isDebug == true) {
                Log.d("AppsFlyer", "Starting Tracking");
            }

            if (isConversionData == true) {

//				if(mAttributionDataListener == null) {
//					mAttributionDataListener = callbackContext;
//				}

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
                instance.startTracking(c.getApplication(), devKey, new AppsFlyerTrackingRequestListener() {
                    @Override
                    public void onTrackingRequestSuccess() {
                        callbackContext.success(SUCCESS);
                    }

                    @Override
                    public void onTrackingRequestFailure(String s) {
                        callbackContext.success(FAILURE);
                    }
                });
            } else {
                instance.startTracking(c.getApplication());
            }


            instance.startTracking(c.getApplication());

            if (gcdListener != null) {
                sendPluginNoResult(callbackContext);
            } else {
                //callbackContext.success(SUCCESS);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return true;
    }

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
                mAttributionData = attributionData;
                intentURI = c.getIntent().getData();

                handleSuccess(AF_ON_APP_OPEN_ATTRIBUTION, null, mAttributionData);

            }

            @Override
            public void onAttributionFailure(String errorMessage) {
                handleError(AF_ON_ATTRIBUTION_FAILURE, errorMessage);
            }


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

            private void sendEvent(JSONObject params) {

                final String jsonStr = params.toString();

                if (
                        (params.optString("type") == AF_ON_ATTRIBUTION_FAILURE
                                || params.optString("type") == AF_ON_APP_OPEN_ATTRIBUTION)
                                && mAttributionDataListener != null) {
                    PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
                    result.setKeepCallback(false);

                    mAttributionDataListener.sendPluginResult(result);
                    mAttributionDataListener = null;
                } else if (
                        (params.optString("type") == AF_ON_INSTALL_CONVERSION_DATA_LOADED
                                || params.optString("type") == AF_ON_INSTALL_CONVERSION_FAILURE)
                                && mConversionListener != null) {
                    PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
                    result.setKeepCallback(false);

                    mConversionListener.sendPluginResult(result);
                    mConversionListener = null;
                }
            }
        };
    }

    private boolean trackEvent(JSONArray parameters, final CallbackContext callbackContext) {
        String eventName;
        Map<String, Object> eventValues = null;
        try {
            eventName = parameters.getString(0);
            Log.i("Event name amit:", eventName + "");

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
        AppsFlyerLib.getInstance().trackEvent(c, eventName, eventValues);

        return true;
    }

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

    private boolean setAppUserId(JSONArray parameters, CallbackContext callbackContext) {

        try {
            String customeUserId = parameters.getString(0);
            if (customeUserId == null || customeUserId.length() == 0) {
                return true; //TODO error
            }
//            AppsFlyerLib.getInstance().setAppUserId(customeUserId);
            //5.2.0 - setAppUserId replaced with setCustomerUserId
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

    private boolean getAppsFlyerUID(CallbackContext callbackContext) {

        String id = AppsFlyerLib.getInstance().getAppsFlyerUID(cordova.getActivity().getApplicationContext());
        PluginResult r = new PluginResult(PluginResult.Status.OK, id);
        r.setKeepCallback(false);
        callbackContext.sendPluginResult(r);

        return true;
    }

    private boolean setDeviceTrackingDisabled(JSONArray parameters) {

        try {
            boolean isDisabled = parameters.getBoolean(0);
            AppsFlyerLib.getInstance().setDeviceTrackingDisabled(isDisabled);
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        return true;
    }

    private boolean stopTracking(JSONArray parameters) {

        try {
            boolean isStopTracking = parameters.getBoolean(0);
            AppsFlyerLib.getInstance().stopTracking(isStopTracking, cordova.getActivity().getApplicationContext());
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        return true;
    }

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

    @Deprecated
    private boolean setGCMProjectNumber(JSONArray parameters) {
        String gcmProjectId = null;
        try {
            gcmProjectId = parameters.getString(0);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        if (gcmProjectId == null || gcmProjectId.length() == 0) {
            return true;//TODO error
        }
        Context c = this.cordova.getActivity().getApplicationContext();
        //5.2.0 - use updateServerUninstallToken
        AppsFlyerLib.getInstance().updateServerUninstallToken(c, gcmProjectId);


        return true;
    }

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
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Not a valid token"));
                }
            }
        });

        return true;
    }

    private boolean enableUninstallTracking(JSONArray parameters, CallbackContext callbackContext) {

        String gcmProjectNumber = parameters.optString(0);

        if (gcmProjectNumber == null || gcmProjectNumber.length() == 0) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_GCM_PROJECT_NUMBER_PROVIDED));
            return true;
        }
//        AppsFlyerLib.getInstance().enableUninstallTracking(gcmProjectNumber);
        //new addition 5.2.0 - start
        Context c = cordova.getActivity().getApplicationContext();
        AppsFlyerLib.getInstance().updateServerUninstallToken(c, gcmProjectNumber);
        //new addition 5.2.0 - end
        callbackContext.success(SUCCESS);
        return true;
    }

    private boolean onResume(JSONArray parameters, CallbackContext callbackContext) {
        Intent intent = cordova.getActivity().getIntent();
        newIntentURI = intent.getData();

        if (newIntentURI != intentURI) {
            if (mAttributionData != null) {
                PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject(mAttributionData).toString());
                callbackContext.sendPluginResult(r);
                mAttributionData = null;
            } else {
                mAttributionDataListener = callbackContext;
                sendPluginNoResult(callbackContext);
            }

            intentURI = newIntentURI;
        }
        return true;
    }

    // USER INVITE
    private boolean setAppInviteOneLinkID(JSONArray parameters, CallbackContext callbackContext) {
        try {
            String oneLinkID = parameters.getString(0);
            if (oneLinkID == null || oneLinkID.length() == 0) {
                return true; //TODO error
            }
            AppsFlyerLib.getInstance().setAppInviteOneLink(oneLinkID);
            callbackContext.success(SUCCESS);
        } catch (JSONException e) {
            e.printStackTrace();
            return true; //TODO error
        }
        return true;
    }

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

    // CROSS PROMOTION
    public boolean trackCrossPromotionImpression(JSONArray parameters, CallbackContext callbackContext) {
        String promotedAppId = null;
        String campaign = null;

        try {
            final JSONObject options = parameters.getJSONObject(0);

            promotedAppId = options.optString(PROMOTE_ID, "");
            campaign = options.optString(INVITE_CAMPAIGN, "");

            if (promotedAppId != null && promotedAppId != "") {
                Context context = this.cordova.getActivity().getApplicationContext();
                CrossPromotionHelper.trackCrossPromoteImpression(context, promotedAppId, campaign);
            } else {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromoted App ID Not set"));
                return true;
            }

        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromotionImpression Failed"));
        }
        return true;

    }

    public boolean trackAndOpenStore(JSONArray parameters, CallbackContext callbackContext) {
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
                CrossPromotionHelper.trackAndOpenStore(context, promotedAppId, campaign, userParams);
            } else {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromoted App ID Not set"));
                return true;
            }
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "CrossPromotion Failed"));
        }
        return true;
    }

    private void sendPluginNoResult(CallbackContext callbackContext) {
        PluginResult pluginResult = new PluginResult(
                PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }
}
