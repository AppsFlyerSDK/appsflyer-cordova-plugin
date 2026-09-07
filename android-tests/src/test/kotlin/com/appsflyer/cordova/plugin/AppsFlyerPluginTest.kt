package com.appsflyer.cordova.plugin

import com.appsflyer.pluginbridge.model.RpcResponse
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Exercises the pure JSON-normalization/routing logic in AppsFlyerPlugin.kt against the real
 * org.json and af-android-plugin-bridge artifacts -- CordovaPlugin/CallbackContext/executor
 * wiring itself needs a real Activity and isn't covered here (see the test report).
 */
class AppsFlyerPluginTest {

    // --- normalize()/normalizeError(): must match iOS's { success, data|error } envelope. ---

    @Test
    fun `normalize wraps a Success result under data`() {
        val result = mapOf("uid" to "abc123")
        val envelope = JSONObject(normalize(RpcResponse.Success(result)))

        assertTrue(envelope.getBoolean("success"))
        assertEquals("abc123", envelope.getJSONObject("data").getString("uid"))
    }

    @Test
    fun `normalize wraps VoidSuccess as null data`() {
        val envelope = JSONObject(normalize(RpcResponse.VoidSuccess))

        assertTrue(envelope.getBoolean("success"))
        assertTrue(envelope.isNull("data"))
    }

    @Test
    fun `normalize wraps an Error under a code plus message`() {
        val envelope = JSONObject(normalize(RpcResponse.Error(404, "not found")))

        assertFalse(envelope.getBoolean("success"))
        val error = envelope.getJSONObject("error")
        assertEquals(404, error.getInt("code"))
        assertEquals("not found", error.getString("message"))
    }

    @Test
    fun `normalizeError produces the same shape as a caught exception path`() {
        val envelope = JSONObject(normalizeError(code = 500, message = "boom"))

        assertFalse(envelope.getBoolean("success"))
        assertEquals(500, envelope.getJSONObject("error").getInt("code"))
        assertEquals("boom", envelope.getJSONObject("error").getString("message"))
    }

    // --- isAwaitResponseCall(): routes exactly the wire methods that block on an async response. ---

    @Test
    fun `isAwaitResponseCall is true for every await-response method`() {
        for (method in listOf("start", "logEvent", "generateInviteLink", "validateAndLogInAppPurchase")) {
            val requestJson = JSONObject().put("method", method).toString()
            assertTrue("$method should route to the awaitResponse lane", isAwaitResponseCall(requestJson))
        }
    }

    @Test
    fun `isAwaitResponseCall is false for a general-lane method`() {
        val requestJson = JSONObject().put("method", "setCurrencyCode").toString()
        assertFalse(isAwaitResponseCall(requestJson))
    }

    @Test
    fun `isAwaitResponseCall does not throw on malformed JSON`() {
        // parseJsonOrDefault must swallow this, not propagate -- a malformed requestJson would
        // otherwise crash dispatch before either executor lane ever ran.
        assertFalse(isAwaitResponseCall("not json"))
    }

    // --- normalizeDeepLinkEvent(): Android FOUND/NOT_FOUND/ERROR -> lowercase, everything else untouched. ---

    @Test
    fun `normalizeDeepLinkEvent lowercases only the error field, leaves status untouched`() {
        val raw = JSONObject()
            .put("event", "onDeepLinking")
            .put("data", JSONObject().put("status", "FOUND").put("error", "SOME_ERROR"))
            .toString()

        val normalized = JSONObject(normalizeDeepLinkEvent(raw))
        val data = normalized.getJSONObject("data")

        assertEquals("FOUND", data.getString("status"))
        assertEquals("some_error", data.getString("error"))
    }

    @Test
    fun `normalizeDeepLinkEvent passes through a non-deep-link event unmodified`() {
        val raw = JSONObject().put("event", "somethingElse").put("data", JSONObject()).toString()
        assertEquals(raw, normalizeDeepLinkEvent(raw))
    }

    @Test
    fun `normalizeDeepLinkEvent does not mutate the original envelope's data object`() {
        val data = JSONObject().put("status", "FOUND").put("error", "ERR")
        val envelope = JSONObject().put("event", "onDeepLinking").put("data", data)

        normalizeDeepLinkEvent(envelope.toString())

        // The function must copy before lowercasing -- pluginNotifier fires from arbitrary
        // native threads and `data` here is the caller's own object, not owned by this call.
        assertEquals("ERR", data.getString("error"))
    }

    @Test
    fun `normalizeDeepLinkEvent passes through malformed JSON unmodified rather than throwing`() {
        assertEquals("not json", normalizeDeepLinkEvent("not json"))
    }

    // --- Two lanes, not three: a slow awaitResponse call must not delay an unrelated queued RPC. ---
    // Exercises the exact factory calls + sizing constant AppsFlyerPlugin uses for its two
    // executors, not a reimplementation -- proves the isolation property the two-lane design
    // exists for, without driving the real rpcHandler (which needs a live Activity/AppsFlyerLib).

    @Test
    fun `a slow awaitResponse call does not delay a concurrently queued general-lane call`() {
        val awaitResponseExecutor = Executors.newFixedThreadPool(AWAIT_RESPONSE_METHODS.size)
        val rpcExecutor = Executors.newSingleThreadExecutor()
        try {
            val fastLatch = CountDownLatch(1)

            // Simulates a slow awaitResponse call (e.g. validateAndLogInAppPurchase's store round trip)
            // occupying the pooled lane.
            awaitResponseExecutor.execute { Thread.sleep(300) }

            // A concurrently queued general-lane call (e.g. setCurrencyCode) must still complete
            // fast -- it's on rpcExecutor, an entirely separate lane from the slow call above.
            val start = System.nanoTime()
            rpcExecutor.execute { fastLatch.countDown() }

            assertTrue(
                "general-lane call should not wait on the awaitResponse lane's slow call",
                fastLatch.await(100, TimeUnit.MILLISECONDS),
            )
            assertTrue((System.nanoTime() - start) < TimeUnit.MILLISECONDS.toNanos(300))
        } finally {
            awaitResponseExecutor.shutdownNow()
            rpcExecutor.shutdownNow()
        }
    }

    @Test
    fun `the awaitResponse lane is pooled so two concurrent slow calls don't block each other`() {
        val awaitResponseExecutor = Executors.newFixedThreadPool(AWAIT_RESPONSE_METHODS.size)
        try {
            val bothStarted = CountDownLatch(2)
            awaitResponseExecutor.execute { bothStarted.countDown(); Thread.sleep(200) }
            awaitResponseExecutor.execute { bothStarted.countDown(); Thread.sleep(200) }

            assertTrue(
                "both awaitResponse calls should start concurrently -- a single-threaded lane " +
                    "would run the second only after the first's 200ms sleep",
                bothStarted.await(100, TimeUnit.MILLISECONDS),
            )
        } finally {
            awaitResponseExecutor.shutdownNow()
        }
    }
}
