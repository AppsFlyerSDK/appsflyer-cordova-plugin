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

// Methods that block on async responses; use separate executor to avoid head-of-line-blocking.
internal val AWAIT_RESPONSE_METHODS: Set<String> = setOf(
    "start", "logEvent", "generateInviteLink", "validateAndLogInAppPurchase",
)

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

internal fun deepLinkRequestJsonForIntent(action: String?, url: String?): String? {
    if (action != Intent.ACTION_VIEW || url.isNullOrEmpty()) return null
    return JSONObject().apply {
        put("method", "performDeepLinking")
        put("params", JSONObject().apply { put("url", url) })
    }.toString()
}

// Pass-through: preserve native deep-link strings unchanged (parity with iOS).
internal fun normalizeDeepLinkEvent(eventJson: String): String = eventJson

/** Cordova bridge — every SDK capability is dispatched via executeRpc -> AppsFlyerRpcHandler. */
class AppsFlyerPlugin : CordovaPlugin() {

    private val awaitResponseExecutor = Executors.newFixedThreadPool(AWAIT_RESPONSE_METHODS.size)
    private val rpcExecutor = Executors.newSingleThreadExecutor()

    @Volatile
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

    private fun subscribeRpcEvents(callbackContext: CallbackContext) {
        if (rpcEventCallbackContext != null) {
            Log.w(TAG, "subscribeRpcEvents called more than once; ignoring duplicate subscription")
            callbackContext.error("subscribeRpcEvents called more than once; ignoring duplicate subscription")
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

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { cordova.activity?.intent = it }
        val requestJson = deepLinkRequestJsonForIntent(intent?.action, intent?.dataString) ?: return
        try {
            rpcExecutor.execute { safeDispatchToNative(requestJson) }
        } catch (e: RejectedExecutionException) {
            Log.w(TAG, "Dropped onNewIntent deep link forward: plugin is shutting down")
        }
    }

    override fun onReset() {
        super.onReset()
        rpcEventCallbackContext = null
    }

    override fun onDestroy() {
        super.onDestroy()
        rpcEventCallbackContext = null
        for (executor in listOf(awaitResponseExecutor, rpcExecutor)) {
            executor.shutdownNow()
        }
        try {
            val deadlineNanos = System.nanoTime() + TimeUnit.SECONDS.toNanos(2)
            for (executor in listOf(awaitResponseExecutor, rpcExecutor)) {
                val remainingNanos = deadlineNanos - System.nanoTime()
                if (remainingNanos > 0) {
                    executor.awaitTermination(remainingNanos, TimeUnit.NANOSECONDS)
                }
            }
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    internal fun awaitResponseExecutorForTest(): ExecutorService = awaitResponseExecutor
    internal fun rpcExecutorForTest(): ExecutorService = rpcExecutor

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

internal fun normalize(response: RpcResponse): String = when (response) {
    is RpcResponse.Success<*> -> JSONObject()
        .put("success", true)
        .put("data", JSONObject.wrap(response.result) ?: JSONObject.NULL)
        .toString()
    is RpcResponse.VoidSuccess -> JSONObject()
        .put("success", true)
        .put("data", JSONObject.NULL)
        .toString()
    is RpcResponse.Error -> normalizeError(code = response.code, message = response.message)
}

internal fun normalizeError(code: Int, message: String): String = JSONObject()
    .put("success", false)
    .put("error", JSONObject().put("code", code).put("message", message))
    .toString()
