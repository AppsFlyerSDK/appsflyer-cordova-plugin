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

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;


import static com.appsflyer.cordova.plugin.AppsFlyerConstants.*;

public class AppsFlyerPlugin extends CordovaPlugin {

	private CallbackContext mConversionListener = null;
    private CallbackContext mAttributionDataListener = null;
    private Map<String, String> mAttributionData = null;
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
		if("setCurrencyCode".equals(action))
		{
			return setCurrencyCode(args);
		}
		else if("setAppUserId".equals(action))
		{
			return setAppUserId(args, callbackContext);
		}
		else if("getAppsFlyerUID".equals(action))
		{
			return getAppsFlyerUID(callbackContext);
		}
		else if ("setDeviceTrackingDisabled".equals(action)) {
			return setDeviceTrackingDisabled(args);
		}
		else if("initSdk".equals(action))
		{
			return initSdk(args,callbackContext);
		}
		else if ("trackEvent".equals(action)) {
			return trackEvent(args, callbackContext);
		}
		else if ("setGCMProjectID".equals(action)) {
			return setGCMProjectNumber(args);
		}
		else if("enableUninstallTracking".equals(action))
		{
			return enableUninstallTracking(args, callbackContext);
		}
		else if("resumeSDK".equals(action))
		{
			return onResume(args, callbackContext);
		}

		return false;
	}

    private void trackAppLaunch() {
        c = this.cordova.getActivity();
        AppsFlyerLib.getInstance().sendDeepLinkData(c);
        AppsFlyerLib.getInstance().trackEvent(c, null, null);
    }

	/**
	 *
	 * @param args
	 * @param callbackContext
     */
	private boolean initSdk(final JSONArray args, final CallbackContext callbackContext) {


		String devKey = null;
		boolean isConversionData;
		boolean isDebug = false;

		AppsFlyerProperties.getInstance().set(AppsFlyerProperties.LAUNCH_PROTECT_ENABLED, false);
		AppsFlyerLib instance = AppsFlyerLib.getInstance();

		try{
			final JSONObject options = args.getJSONObject(0);

			devKey = options.optString(AF_DEV_KEY, "");
			isConversionData = options.optBoolean(AF_CONVERSION_DATA, false);

			if(devKey.trim().equals("")){
				callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_DEVKEY_FOUND));
			}

			isDebug = options.optBoolean(AF_IS_DEBUG, false);

			instance.setDebugLog(isDebug);

			if(isDebug == true){
                Log.d("AppsFlyer", "Starting Tracking");
			}

			trackAppLaunch();
			instance.startTracking(c.getApplication(), devKey);


			if(isConversionData == true){

                if(mAttributionDataListener == null) {
                    mAttributionDataListener = callbackContext;
                }

				if(mConversionListener == null){
					mConversionListener = callbackContext;
				}

                registerConversionListener(instance);
                sendPluginNoResult(callbackContext);

			}
			else{
				callbackContext.success(SUCCESS);
			}

		}
		catch (JSONException e){
			e.printStackTrace();
		}

		return true;
	}

	private void registerConversionListener(AppsFlyerLib instance){
		instance.registerConversionListener(cordova.getActivity().getApplicationContext(), new AppsFlyerConversionListener(){

			@Override
			public void onAppOpenAttribution(Map<String, String> attributionData) {
                mAttributionData = attributionData;
                intentURI =  c.getIntent().getData();

                if(mAttributionDataListener != null && newIntentURI != intentURI) {
                    PluginResult result = new PluginResult(PluginResult.Status.OK, mAttributionData.toString());
                    result.setKeepCallback(false);

                    mAttributionDataListener.sendPluginResult(result);
                    mAttributionDataListener = null;
                }
			}

			@Override
			public void onAttributionFailure(String errorMessage) {
				handleError(AF_ON_ATTRIBUTION_FAILURE, errorMessage);
			}

			@Override
			public void onInstallConversionDataLoaded(Map<String, String> conversionData) {
				handleSuccess(AF_ON_INSTALL_CONVERSION_DATA_LOADED, conversionData);
			}

			@Override
			public void onInstallConversionFailure(String errorMessage) {
				handleError(AF_ON_INSTALL_CONVERSION_FAILURE, errorMessage);
			}


			private void handleError(String eventType, String errorMessage){

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

			private void handleSuccess(String eventType, Map<String, String> data){
				try {
					JSONObject obj = new JSONObject();

					obj.put("status", AF_SUCCESS);
					obj.put("type", eventType);
					obj.put("data", new JSONObject(data));

					sendEvent(obj);
				} catch (JSONException e) {
					e.printStackTrace();
				}
			}

			private void sendEvent(JSONObject params) {

				final String jsonStr = params.toString();


				if (mConversionListener != null) {
					PluginResult result = new PluginResult(PluginResult.Status.OK, jsonStr);
					result.setKeepCallback(false);

					mConversionListener.sendPluginResult(result);
					mConversionListener = null;
				}
			}
		});
	}

	private boolean trackEvent(JSONArray parameters, final CallbackContext callbackContext) {
		String eventName;
		Map<String, Object> eventValues = null;
		try{
			eventName = parameters.getString(0);

			if(parameters.length() >1 && !parameters.get(1).equals(null)){
				JSONObject jsonEventValues = parameters.getJSONObject(1);
				eventValues = jsonToMap(jsonEventValues.toString());
			}
		}
		catch (JSONException e){
			e.printStackTrace();
			return true;
		}

		if(eventName == null || eventName.trim().length()==0){
			callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_EVENT_NAME_FOUND));
			return true;
		}

		Context c = this.cordova.getActivity().getApplicationContext();
		AppsFlyerLib.getInstance().trackEvent(c, eventName, eventValues);

		return true;
	}

	private boolean setCurrencyCode(JSONArray parameters){

		String currencyId=null;
		try
		{
			currencyId = parameters.getString(0);
		}
		catch (JSONException e)
		{
			e.printStackTrace();
			return true; //TODO error
		}
		if(currencyId == null || currencyId.length()==0)
		{
			return true; //TODO error
		}
		AppsFlyerLib.getInstance().setCurrencyCode(currencyId);

		return true;
	}

	private boolean setAppUserId(JSONArray parameters, CallbackContext callbackContext){

		try
		{
			String customeUserId = parameters.getString(0);
			if(customeUserId == null || customeUserId.length()==0){
				return true; //TODO error
			}
        	AppsFlyerLib.getInstance().setAppUserId(customeUserId);
        	PluginResult r = new PluginResult(PluginResult.Status.OK);
        	r.setKeepCallback(false);
        	callbackContext.sendPluginResult(r);
		}
		catch (JSONException e)
		{
			e.printStackTrace();
			return true; //TODO error
		}

		return true;
	}

	private boolean getAppsFlyerUID(CallbackContext callbackContext){

    	String id = AppsFlyerLib.getInstance().getAppsFlyerUID(cordova.getActivity().getApplicationContext());
    	PluginResult r = new PluginResult(PluginResult.Status.OK, id);
    	r.setKeepCallback(false);
    	callbackContext.sendPluginResult(r);

		return true;
	}

	private boolean setDeviceTrackingDisabled(JSONArray parameters){

		try
		{
			boolean isDisabled = parameters.getBoolean(0);
			AppsFlyerLib.getInstance().setDeviceTrackingDisabled(isDisabled);
		}
		catch (JSONException e)
		{
			e.printStackTrace();
			return true; //TODO error
		}
		return true;
	}

	private static Map<String,Object> jsonToMap(String inputString){
		Map<String,Object> newMap = new HashMap<String, Object>();

		try {
			JSONObject jsonObject = new JSONObject(inputString);
			Iterator iterator = jsonObject.keys();
			while (iterator.hasNext()){
				String key = (String) iterator.next();
				newMap.put(key,jsonObject.getString(key));

			}
		} catch(JSONException e) {
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

		if(gcmProjectId == null || gcmProjectId.length()==0){
			return true;//TODO error
		}
		Context c = this.cordova.getActivity().getApplicationContext();
		AppsFlyerLib.getInstance().setGCMProjectNumber(c, gcmProjectId);
		return true;
	}

	private boolean enableUninstallTracking(JSONArray parameters, CallbackContext callbackContext){

		String gcmProjectNumber = parameters.optString(0);

		if(gcmProjectNumber == null || gcmProjectNumber.length()==0){
			callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, NO_GCM_PROJECT_NUMBER_PROVIDED));
			return true;
		}

		AppsFlyerLib.getInstance().enableUninstallTracking(gcmProjectNumber);
		callbackContext.success(SUCCESS);
		return true;
	}

    private boolean onResume(JSONArray parameters, CallbackContext callbackContext){
        Intent intent = cordova.getActivity().getIntent();
        newIntentURI = intent.getData();

        if (newIntentURI != intentURI) {
            if (mAttributionData != null) {
                PluginResult r = new PluginResult(PluginResult.Status.OK, mAttributionData.toString());
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

	private void sendPluginNoResult(CallbackContext callbackContext) {
		PluginResult pluginResult = new PluginResult(
				PluginResult.Status.NO_RESULT);
		pluginResult.setKeepCallback(true);
		callbackContext.sendPluginResult(pluginResult);
	}
}
