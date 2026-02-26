package com.appsflyer.cordova.plugin;

import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_DEEP_LINK;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_DATA_LOADED;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_INSTALL_CONVERSION_FAILURE;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_ON_SESSION_READY;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.AF_SUCCESS;
import static com.appsflyer.cordova.plugin.AppsFlyerConstants.PLUGIN_VERSION;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.appsflyer.AppsFlyerLib;
import com.appsflyer.pluginbridge.handler.AppsFlyerRpcHandler;
import com.appsflyer.pluginbridge.model.RpcResponse;
import com.appsflyer.pluginbridge.parser.JsonRpcRequestParser;
import com.appsflyer.share.platform_extension.Plugin;
import com.appsflyer.share.platform_extension.PluginInfo;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

public class AppsFlyerPlugin extends CordovaPlugin {

    private CallbackContext mConversionListener = null;
    private CallbackContext mDeepLinkListener = null;
    private CallbackContext mSessionReadyListener = null;

    private AppsFlyerRpcHandler rpcHandler;

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
     */
    @Override
    public boolean execute(final String action, JSONArray args, CallbackContext callbackContext) {
        if ("executeRpc".equals(action)) {
            return executeRpc(args, callbackContext);
        }
        return false;
    }

    public boolean executeRpc(JSONArray args, final CallbackContext callbackContext) {
        try {
            // Extract method and params
            JSONObject options = args.length() > 0 ? args.getJSONObject(0) : new JSONObject();
            String method = options.optString("method", null);
            JSONObject paramsJson = options.optJSONObject("params");
            if (paramsJson == null) {
                paramsJson = new JSONObject();
            }

            applyCallbackRegistrationForMethod(method, callbackContext);

            if ("init".equals(method)) {
                setPluginInfo();
            }

            // Build JSON-RPC request string and execute (all methods, including subscribeForDeepLink)
            JSONObject jsonRequest = new JSONObject();
            jsonRequest.put("method", method);
            jsonRequest.put("params", paramsJson);
            String jsonRequestString = jsonRequest.toString();

            AppsFlyerRpcHandler handler = getOrCreateRpcHandler();
            RpcResponse response = handler.execute(jsonRequestString);

            // Handle response
            boolean isCallbackRegistrationOnly = "registerSessionReadyListener".equals(method)
                    || "subscribeForDeepLink".equals(method)
                    || "registerConversionListener".equals(method);
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
     * Updates or clears stored callback contexts for RPC methods that register or unregister listeners.
     * Called before the request is sent to the bridge so that event delivery uses the correct callback.
     */
    private void applyCallbackRegistrationForMethod(String method, CallbackContext callbackContext) {
        if ("registerSessionReadyListener".equals(method)) {
            mSessionReadyListener = callbackContext;
        }
        if ("unregisterSessionReadyListener".equals(method)) {
            mSessionReadyListener = null;
        }
        if ("subscribeForDeepLink".equals(method)) {
            mDeepLinkListener = callbackContext;
        }
        if ("unsubscribeForDeepLink".equals(method)) {
            mDeepLinkListener = null;
        }
        if ("registerConversionListener".equals(method)) {
            mConversionListener = callbackContext;
        }
        if ("unregisterConversionListener".equals(method)) {
            mConversionListener = null;
        }
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
            Context context = cordova.getActivity();
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
                Log.d("AppsFlyer", "Received event notification " + obj);
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
     * Helper function to send a callback with no results.
     */
    private void sendPluginNoResult(CallbackContext callbackContext) {
        PluginResult pluginResult = new PluginResult(
                PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }

    private void setPluginInfo(){
        PluginInfo pluginInfo = new PluginInfo(Plugin.CORDOVA, PLUGIN_VERSION);
        AppsFlyerLib.getInstance().setPluginInfo(pluginInfo);
    }

}
