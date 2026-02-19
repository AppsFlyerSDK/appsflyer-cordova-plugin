package com.appsflyer.cordova.plugin;

import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_COLLECT_ANDROID_ID;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_CONVERSION_DATA;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_DEEP_LINK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_DEV_KEY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_IS_DEBUG;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_DATA_LOADED;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_SESSION_READY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_SUCCESS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_DEVKEY_FOUND;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_EVENT_NAME_FOUND;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.NO_PARAMETERS_ERROR;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PLUGIN_VERSION;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.SHOULD_START_SDK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.SUCCESS;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.appsflyer.AppsFlyerLib;
import com.appsflyer.pluginbridge.handler.AppsFlyerRpcHandler;
import com.appsflyer.pluginbridge.model.RpcResponse;
import com.appsflyer.pluginbridge.parser.JsonRpcRequestParser;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;
import com.appsflyer.share.AFAdRevenueData;
import com.appsflyer.share.AFPurchaseDetails;
import com.appsflyer.share.AFPurchaseType;
import com.appsflyer.share.AppsFlyerConversionListener;
import com.appsflyer.share.AppsFlyerInAppPurchaseValidationCallback;
import com.appsflyer.share.MediationNetwork;
import com.appsflyer.share.attribution.AppsFlyerRequestListener;
import com.appsflyer.share.platform_extension.Plugin;
import com.appsflyer.share.platform_extension.PluginInfo;

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
    private CallbackContext mSessionReadyListener = null;
    private Uri intentURI = null;

    private AppsFlyerRpcHandler rpcHandler;

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
        if ("registerOnAppOpenAttribution".equals(action)) {
            return registerOnAppOpenAttribution(callbackContext);
        } else if ("initSdk".equals(action)) {
            return initSdk(args, callbackContext);
        } else if ("logEvent".equals(action)) {
            return logEvent(args, callbackContext);
        } else if ("validateAndLogInAppPurchaseV2".equals(action)) {
            return validateAndLogInAppPurchaseV2(args, callbackContext);
        } else if ("enableFacebookDeferredApplinks".equals(action)) {
            return enableFacebookDeferredApplinks(args);
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
        } else if ("enableTCFDataCollection".equals(action)) {
            return enableTCFDataCollection(args);
        } else if ("logAdRevenue".equals(action)) {
            return logAdRevenue(args);
        } else if ("disableAppSetId".equals(action)) {
            return disableAppSetId();
        } else if ("executeRpc".equals(action)) {
            return executeRpc(args, callbackContext);
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

    public boolean executeRpc(JSONArray args, final CallbackContext callbackContext) {
        try {
            // 1. Extract method and params
            JSONObject options = args.length() > 0 ? args.getJSONObject(0) : new JSONObject();
            String method = options.optString("method", null);
            JSONObject paramsJson = options.optJSONObject("params");
            if (paramsJson == null) {
                paramsJson = new JSONObject();
            }

            // Methods that register callbacks
            if ("registerSessionReadyListener".equals(method)) {
                return handleRegisterSessionReadyListener(callbackContext);
            }
            if ("subscribeForDeepLink".equals(method)) {
                mDeepLinkListener = callbackContext;
            }

            // 2. Build JSON-RPC request string and execute (all methods, including subscribeForDeepLink)
            JSONObject jsonRequest = new JSONObject();
            jsonRequest.put("method", method);
            jsonRequest.put("params", paramsJson);
            String jsonRequestString = jsonRequest.toString();

            AppsFlyerRpcHandler handler = getOrCreateRpcHandler();
            RpcResponse response = handler.execute(jsonRequestString);

            // 3. Handle response
            boolean isCallbackRegistrationOnly = "subscribeForDeepLink".equals(method);
            handleRpcResponse(response, callbackContext, isCallbackRegistrationOnly);
        } catch (JSONException e) {
            Log.e("AppsFlyer", "executeRpc JSON error", e);
            callbackContext.error("PARSE_ERROR" + e.getMessage());
        } catch (IllegalArgumentException e) {
            Log.e("AppsFlyer", "executeRpc invalid request", e);
            callbackContext.error("INVALID_PARAMETERS" + e.getMessage());
        } catch (Throwable t) {
            Log.e("AppsFlyer", "executeRpc error", t);
            callbackContext.error("INTERNAL_ERROR" + (t.getMessage() != null ? t.getMessage() : "Unknown error"));
        }
        return true;
    }

    /**
     * Sends the RPC response to the Cordova callback. Success with Map is serialized to JSON string;
     * other success results use toString(). VoidSuccess is sent as success() or, when
     * isCallbackRegistrationOnly is true, as NO_RESULT with keepCallback (for callback registration).
     */
    private void handleRpcResponse(RpcResponse response, CallbackContext callbackContext,
            boolean isCallbackRegistrationOnly) throws JSONException {
        if (response instanceof RpcResponse.Success) {
            Object result = ((RpcResponse.Success<?>) response).getResult();
            if (result instanceof Map) {
                JSONObject jsonObject = new JSONObject((Map) result);
                String jsonString = jsonObject.toString();
                callbackContext.success(jsonString);
            } else {
                callbackContext.success(result != null ? result.toString() : "");
            }
        } else if (response instanceof RpcResponse.VoidSuccess) {
            if (isCallbackRegistrationOnly) {
                sendPluginNoResult(callbackContext);
            } else {
                callbackContext.success();
            }
        } else if (response instanceof RpcResponse.Error) {
            RpcResponse.Error error = (RpcResponse.Error) response;
            callbackContext.error(error.getCode() + error.getMessage());
        }
    }

    /**
     * Lazily creates and returns the RPC handler. Bridge events (e.g. conversion data, deep link)
     * are forwarded to the plugin via RpcEventNotifier and sent to JS through sendEvent.
     */
    private AppsFlyerRpcHandler getOrCreateRpcHandler() {
        if (rpcHandler == null) {
            Context context = cordova.getActivity().getApplicationContext();
            rpcHandler = new AppsFlyerRpcHandler(
                    context,
                    createRpcEventNotifier(),
                    AppsFlyerLib.getInstance(),
                    new JsonRpcRequestParser()
            );
        }
        return rpcHandler;
    }

    /**
     * Creates a notifier (Kotlin (String) -> Unit) that forwards bridge events to the plugin.
     * Bridge sends JSON with "event", "data", "timestamp", "origin"; we map "event" to "type"
     * for sendEvent routing and pass the payload to JS.
     */
    private Function1<String, Unit> createRpcEventNotifier() {
        return eventJson -> {
            try {
                JSONObject obj = new JSONObject(eventJson);
                Log.i("AppsFlyer", "Received event notification " + obj.toString());
                String event = obj.optString("event", "");
                // Map bridge event names to plugin type names for sendEvent routing
                if ("onConversionDataSuccess".equals(event)) {
                    obj.put("type", AF_ON_INSTALL_CONVERSION_DATA_LOADED);
                } else if ("onConversionDataFail".equals(event)) {
                    obj.put("type", AF_ON_INSTALL_CONVERSION_FAILURE);
                } else {
                    obj.put("type", event);
                }
                obj.put("status", AF_SUCCESS);
                sendEvent(obj);
            } catch (JSONException e) {
                Log.e("AppsFlyer", "RpcEventNotifier failed", e);
            }
            return Unit.INSTANCE;
        };
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
        cordova.getThreadPool().execute(() -> {
            try {
                boolean disable = args.getBoolean(0);
                AppsFlyerLib.getInstance().setDisableAdvertisingIdentifiers(disable);
                callbackContext.success(SUCCESS);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        });
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
            AppsFlyerLib instance = AppsFlyerLib.getInstance();
            boolean isConversionData = options.optBoolean(AF_CONVERSION_DATA, false);
            boolean isDebug = options.optBoolean(AF_IS_DEBUG, false);
            boolean shouldStartSDK = options.optBoolean(SHOULD_START_SDK, true);

            // trigger some setters
            if (options.has(AF_COLLECT_ANDROID_ID)) {
                AppsFlyerLib.getInstance().setCollectAndroidID(options.optBoolean(AF_COLLECT_ANDROID_ID, true));
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

                gcdListener = registerConversionListener();

            }
            // init appsflyerSDK
            instance.init(devKey, gcdListener, cordova.getActivity());

            if (shouldStartSDK) {
                if (mConversionListener == null) {
                    instance.start(new AppsFlyerRequestListener() {
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
                    instance.start();
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
     * GCD listener. handles success and errors in conversion data .
     *
     * @return
     */
    private AppsFlyerConversionListener registerConversionListener() {
        return new AppsFlyerConversionListener() {

            @Override
            public void onConversionDataSuccess(Map<String, Object> conversionData) {
                handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED, conversionData, null);
            }

            @Override
            public void onConversionDataFail(String errorMessage) {
                handleError(AF_ON_INSTALL_CONVERSION_FAILURE, errorMessage);
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
     * Sends the event to the JavaScript side. Runs on the UI thread so Cordova can deliver
     * the result to the WebView (the bridge may invoke the notifier from a background thread).
     */
    private void sendEvent(JSONObject params) {
        final String jsonStr = params.toString();
        final String type = params.optString("type", "");

        Runnable send = () -> {
            if ((AF_ON_INSTALL_CONVERSION_DATA_LOADED.equals(type)
                    || AF_ON_INSTALL_CONVERSION_FAILURE.equals(type))
                    && mConversionListener != null) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
                result.setKeepCallback(true);
                mConversionListener.sendPluginResult(result);
            } else if (AF_DEEP_LINK.equals(type) && mDeepLinkListener != null) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
                result.setKeepCallback(true);
                mDeepLinkListener.sendPluginResult(result);
            } else if (AF_ON_SESSION_READY.equals(type) && mSessionReadyListener != null) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
                result.setKeepCallback(true);
                mSessionReadyListener.sendPluginResult(result);
            }
        };

        if (cordova.getActivity() != null) {
            cordova.getActivity().runOnUiThread(send);
        } else {
            send.run();
        }
    }

    /**
     * Registers a callback to be notified when the SDK is ready to trigger a new session.
     * Invoked via RPC method "registerSessionReadyListener". When the session is ready,
     * the JS callback receives an event with type {@link AppsFlyerConstants#AF_ON_SESSION_READY}.
     */
    private boolean handleRegisterSessionReadyListener(final CallbackContext callbackContext) {
        mSessionReadyListener = callbackContext;
        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        AppsFlyerLib.getInstance().registerSessionReadyListener(() -> {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", AF_ON_SESSION_READY);
                obj.put("status", AF_SUCCESS);
                sendEvent(obj);
            } catch (JSONException e) {
                Log.e("AppsFlyer", "SessionReadyListener failed", e);
            }            });
        return true;
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

    // USER INVITE

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

    private boolean validateAndLogInAppPurchaseV2(JSONArray args, final CallbackContext callbackContext) {
        try {
            JSONObject purchaseDetails = args.getJSONObject(0);
            String purchaseType = purchaseDetails.optString("purchaseType", "");
            String purchaseToken = purchaseDetails.optString("purchaseToken", "");
            String productId = purchaseDetails.optString("productId", "");
            JSONObject additionalParametersJson = args.getJSONObject(1);
            Map<String, String> additionalParameters = null;

            if (purchaseType.isEmpty() || purchaseToken.isEmpty() || productId.isEmpty()) {
                callbackContext.error(NO_PARAMETERS_ERROR);
                return true;
            }

            if (additionalParametersJson != null) {
                additionalParameters = toMap(additionalParametersJson);
            }

            AFPurchaseDetails details = new AFPurchaseDetails(
                    purchaseType.equals("subscription") ? AFPurchaseType.SUBSCRIPTION : AFPurchaseType.ONE_TIME_PURCHASE,
                    purchaseToken,
                    productId
            );

            AppsFlyerLib.getInstance().validateAndLogInAppPurchase(details, additionalParameters, new AppsFlyerInAppPurchaseValidationCallback() {
                @Override
                public void onInAppPurchaseValidationFinished(@NonNull Map<String, ?> validationResult) {
                    JSONObject jsonObject = new JSONObject(validationResult);
                    String jsonString = jsonObject.toString();
                    callbackContext.success(jsonString);
                }

                @Override
                public void onInAppPurchaseValidationError(@NonNull Map<String, ?> validationError) {
                    JSONObject jsonObject = new JSONObject(validationError);
                    String jsonString = jsonObject.toString();
                    callbackContext.error(jsonString);
                }
            });

        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(FAILURE);
            return true;
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

    private boolean disableAppSetId(){
        AppsFlyerLib.getInstance().disableAppSetId();
        return true;
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
