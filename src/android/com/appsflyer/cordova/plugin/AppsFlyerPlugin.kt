package com.appsflyer.cordova.plugin

import android.content.Intent
import android.util.Log
import com.appsflyer.pluginbridge.handler.AppsFlyerRpcHandler
import com.appsflyer.pluginbridge.model.RpcResponse
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaArgs
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.PluginResult
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.TimeUnit

private const val TAG = "AppsFlyerPlugin"
private const val RPC_EVENT_NAME = "rpcEvent"
private const val DEEP_LINK_EVENT_NAME = "onDeepLinking"

// Wire method names whose native handler blocks the calling thread on an async response -- optionally via an "awaitResponse" param, or always for validateAndLogInAppPurchase (no such param; its promise needs the store-validation round trip). Own lane avoids head-of-line-blocking rpcExecutor.
// internal (not private) so AppsFlyerPluginTest can size a real awaitResponseExecutor off it without duplicating the literal set.
internal val AWAIT_RESPONSE_METHODS: Set<String> = setOf(
    "start", "logEvent", "generateInviteLink", "validateAndLogInAppPurchase",
)

// internal (not private) + top-level so AppsFlyerPluginTest can call this directly.
internal fun isAwaitResponseCall(requestJson: String): Boolean =
    parseJsonOrDefault(requestJson, default = false) { it.optString("method") in AWAIT_RESPONSE_METHODS }

// Shared by every JSON helper below — best-effort parse, `default` instead of throwing.
private inline fun <T> parseJsonOrDefault(json: String, default: T, block: (JSONObject) -> T): T {
    return try {
        block(JSONObject(json))
    } catch (e: Exception) {
        // Don't log `json` itself — it can be a deep-link event carrying a URL with PII query params.
        Log.w(TAG, "Failed to parse RPC event JSON, passing through unmodified", e)
        default
    }
}

// Cordova's PluginManager calls onNewIntent on every registered plugin for a warm-resume Intent (CordovaActivity.onNewIntent -> appView.onNewIntent), so this covers cordova-plugin-customurlscheme's redelivered Intent natively, without a JS-level handleOpenURL shim. Primitives, not Intent, so it's testable without an Android framework mock -- see the class-level comment on why onNewIntent itself isn't covered here.
internal fun deepLinkRequestJsonForIntent(action: String?, url: String?): String? {
    if (action != Intent.ACTION_VIEW || url.isNullOrEmpty()) return null
    return JSONObject().apply {
        put("method", "performDeepLinking")
        put("params", JSONObject().apply { put("url", url) })
    }.toString()
}

// `status` is left as-is — js-core-plugin's normalizeDeepLinkStatus() already re-normalizes it for every consumer; duplicating that here would just drift out of sync.
internal fun normalizeDeepLinkEvent(eventJson: String): String = parseJsonOrDefault(eventJson, eventJson) { envelope ->
    if (envelope.optString("event") != DEEP_LINK_EVENT_NAME) return@parseJsonOrDefault eventJson
    val data = envelope.optJSONObject("data") ?: return@parseJsonOrDefault eventJson

    // Copy instead of mutating `data` in place — pluginNotifier fires from arbitrary native threads and `data` is owned by `envelope`, not this function.
    val error = data.optString("error").takeIf { it.isNotEmpty() }?.lowercase()
    if (error != null) {
        val copy = JSONObject(data.toString())
        copy.put("error", error)
        envelope.put("data", copy)
    }

    envelope.toString()
}

/** Cordova bridge — every SDK capability is dispatched via executeRpc -> AppsFlyerRpcHandler. */
class AppsFlyerPlugin : CordovaPlugin() {

    // rpcExecutor single-threaded: AppsFlyerRpcHandler's listener fields are unsynchronized `var`s, so pooling it could race registration against dispatch. awaitResponseExecutor is pooled, sized to AWAIT_RESPONSE_METHODS, so its methods don't block each other while still isolated from general RPC dispatch.
    private val awaitResponseExecutor = Executors.newFixedThreadPool(AWAIT_RESPONSE_METHODS.size)
    private val rpcExecutor = Executors.newSingleThreadExecutor()

    // Set once by subscribeRpcEvents; js-core-plugin's transport subscribes at most once per instance, but nothing stops a stray second call, so double-subscription is guarded explicitly below.
    private var rpcEventCallbackContext: CallbackContext? = null

    private val rpcHandler by lazy {
        AppsFlyerRpcHandler(
            contextProvider = { cordova.activity ?: cordova.context },
            pluginNotifier = { rawEventJson ->
                val callbackContext = rpcEventCallbackContext
                if (callbackContext == null) {
                    Log.w(TAG, "Dropping $RPC_EVENT_NAME: no subscriber registered")
                } else {
                    val pluginResult = PluginResult(PluginResult.Status.OK, normalizeDeepLinkEvent(rawEventJson))
                    pluginResult.keepCallback = true
                    callbackContext.sendPluginResult(pluginResult)
                }
            },
        )
    }

    override fun execute(action: String, args: CordovaArgs, callbackContext: CallbackContext): Boolean {
        return when (action) {
            "executeRpc" -> {
                executeRpc(args, callbackContext)
                true
            }
            "subscribeRpcEvents" -> {
                subscribeRpcEvents(callbackContext)
                true
            }
            else -> false
        }
    }

    private fun executeRpc(args: CordovaArgs, callbackContext: CallbackContext) {
        val requestJson = args.optJSONObject(0)?.optString("requestJson")
        if (requestJson.isNullOrEmpty()) {
            callbackContext.error("requestJson is required")
            return
        }
        val executor = if (isAwaitResponseCall(requestJson)) awaitResponseExecutor else rpcExecutor
        dispatch(callbackContext, executor, requestJson)
    }

    // Stores the CallbackContext once; a stray second subscription would otherwise register a second listener and double-fire every rpcEvent.
    private fun subscribeRpcEvents(callbackContext: CallbackContext) {
        if (rpcEventCallbackContext != null) {
            Log.w(TAG, "subscribeRpcEvents called more than once; ignoring duplicate subscription")
            return
        }
        rpcEventCallbackContext = callbackContext
    }

    private fun dispatch(callbackContext: CallbackContext, executor: ExecutorService, requestJson: String) {
        try {
            executor.execute {
                // Never let an exception escape the task: uncaught, it hits this worker thread's default UncaughtExceptionHandler and kills the whole process on Android.
                try {
                    callbackContext.success(safeDispatchToNative(requestJson))
                } catch (e: Exception) {
                    callbackContext.error("Unexpected RPC dispatch failure: ${e.message}")
                }
            }
        } catch (e: RejectedExecutionException) {
            callbackContext.error("Plugin is shutting down")
        }
    }

    // Fire-and-forget: no JS caller is waiting on this, unlike executeRpc's callbackContext-driven dispatch.
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        val requestJson = deepLinkRequestJsonForIntent(intent?.action, intent?.dataString) ?: return
        try {
            rpcExecutor.execute { safeDispatchToNative(requestJson) }
        } catch (e: RejectedExecutionException) {
            Log.w(TAG, "Dropped onNewIntent deep link forward: plugin is shutting down")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // shutdownNow (not shutdown): don't run queued calls against a torn-down bridge/activity; awaitTermination bounds the wait so onDestroy can't hang on a stuck task.
        for (executor in listOf(awaitResponseExecutor, rpcExecutor)) {
            executor.shutdownNow()
        }
        try {
            awaitResponseExecutor.awaitTermination(2, TimeUnit.SECONDS)
            rpcExecutor.awaitTermination(2, TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    // Catches AppsFlyerRpcHandler exceptions here so they fail the call instead of crashing the process; never forwards the exception message to JS since it can contain internal class names/paths (CWE-209).
    private fun safeDispatchToNative(requestJson: String): String {
        return try {
            normalize(rpcHandler.execute(requestJson))
        } catch (e: Exception) {
            // Don't log `requestJson` — same PII risk as parseJsonOrDefault above (e.g. a performDeepLinking call carries a URL with PII query params).
            Log.w(TAG, "Native RPC dispatch failed", e)
            normalizeError(code = 500, message = "Unexpected native RPC failure")
        }
    }
}

// internal (not private) + top-level so AppsFlyerPluginTest can call these directly without instantiating a CordovaPlugin(); must match the { success, data|error } envelope iOS's bridge also emits — keep in sync with AppsFlyerPluginTests.swift.
internal fun normalize(response: RpcResponse): String {
    val normalized = JSONObject()
    when (response) {
        is RpcResponse.Success<*> -> {
            normalized.put("success", true)
            // wrap() also covers a future result type that isn't a Map/Collection, falling back to JSONObject.NULL instead of a stringified blob.
            normalized.put("data", JSONObject.wrap(response.result) ?: JSONObject.NULL)
        }
        is RpcResponse.VoidSuccess -> {
            normalized.put("success", true)
            normalized.put("data", JSONObject.NULL)
        }
        is RpcResponse.Error -> return normalizeError(code = response.code, message = response.message)
    }
    return normalized.toString()
}

internal fun normalizeError(code: Int, message: String): String {
    val error = JSONObject()
    error.put("code", code)
    error.put("message", message)
    val normalized = JSONObject()
    normalized.put("success", false)
    normalized.put("error", error)
    return normalized.toString()
}
