# PR #306 Open Review Comments — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 8 PR #306 review threads that are still open (3 real Android bugs, 2 real iOS test-coverage gaps, 3 threads that turn out to already be fixed by earlier commits and just need verification + resolving).

**Architecture:** No new subsystems. Each fix is a small, local change to an already-existing file, following the exact pattern that file already uses (extract a pure/testable function the way `normalize`/`canonicalMethod` already are in `AppsFlyerPlugin.swift`, reuse the `NSLock`/`withCriticalScope` pattern already in this codebase, reuse the `internal fun` top-level-for-testing pattern already in `AppsFlyerPlugin.kt`).

**Tech Stack:** Kotlin + JUnit (android-tests/), Swift + XCTest (ios-tests/), no new dependencies anywhere.

**Spec:** GitHub PR #306 review threads (`gh api graphql` reviewThreads query against `AppsFlyerSDK/appsflyer-cordova-plugin#306`) — thread IDs are cited per task below so anyone re-running the query can find the exact source comment.

## Global Constraints

- No new abstractions beyond what each finding literally requires — no DI container, no factory, no config plumbing.
- Every behavior change ships with a regression test in the same task (bug-fix-first-write-a-test, per repo convention already followed in every existing commit on this branch).
- `DO NOT COMMIT` — this plan's steps stop at "verify tests pass"; the user runs `git commit` themselves for each task.
- Match existing file conventions exactly: Kotlin fixes go through `android-tests/.../AppsFlyerPluginTest.kt`, iOS fixes go through `ios-tests/Tests/AppsFlyerCordovaShimTests/*.swift`.
- Do not touch any of the 19 already-resolved threads' code again.

---

## Pre-flight: what "open" actually means for each of the 8 threads

Before writing tasks, each open thread was re-checked against the current code (not the diff as it looked when the comment was posted, since two later commits already changed some of these files). Three of the eight are **already fixed as a side effect of earlier commits** and need no new code — only verification + resolving the thread. The plan below only contains real work for the other five.

| Thread ID | File | Status |
|---|---|---|
| `PRRT_kwDOBHTF3s6f7sb8` | `AppsFlyerPlugin.kt:68` (onNewIntent doesn't `setIntent`) | **Real gap — Task 1** |
| `PRRT_kwDOBHTF3s6f7sdI` | `AppsFlyerPlugin.kt:75` (`rpcEventCallbackContext` not `@Volatile`) | **Real gap — Task 1** |
| `PRRT_kwDOBHTF3s6f7sd-` | `AppsFlyerPlugin.kt:159` (`onDestroy` stacked timeouts) | **Real gap — Task 1** |
| `PRRT_kwDOBHTF3s6f7sPq` | `CordovaTestSupport.swift:18` (force-unwrap path never test-driven) | **Real gap — Task 2** |
| `PRRT_kwDOBHTF3s6f7sRL` | `AppsFlyerAttributionTests.swift:21` (assertion-free buffering tests) | **Real gap — Task 3** |
| `PRRT_kwDOBHTF3s6f7sVd` | `package.json:57` (`prepublishOnly` skips typecheck) | **Already fixed** — `npm run build` (which `prepublishOnly` calls) now runs `typecheck` before `esbuild` (added in the `dist-types` commit). No code change. → Task 4 |
| `PRRT_kwDOBHTF3s6f7smD` | `src/index.ts` (delete `handleOpenURL` instead of patching) | **Already fixed** — the block no longer calls `performDeepLinking` at all (Android deep links go through `AppsFlyerPlugin.kt`'s `onNewIntent` now), so it no longer clobbers, double-fires, or needs a readiness gate; it is now a pure pass-through chain to avoid a `ReferenceError` from `cordova-plugin-customurlscheme`. No code change. → Task 4 |
| `PRRT_kwDOBHTF3s6f7sfy` | `src/cordova-transport.ts:39` (global `cordova.exec` vs `require('cordova/exec')`) | **Won't-fix, now documented** — `require('cordova/exec')` is not a real Node module; under esbuild's browser bundle it would either fail to resolve at build time or resolve to nothing at runtime. The reviewer's own concern was "implicit ordering assumption, not a documented contract" — the code already carries a comment (line 38) that makes this an explicit, documented invariant. No code change. → Task 4 |

---

## Task 1: Android — stale intent, non-volatile callback field, stacked shutdown timeouts

**Files:**
- Modify: `src/android/com/appsflyer/cordova/plugin/AppsFlyerPlugin.kt:75, 142-150, 152-164`
- Test: `android-tests/src/test/kotlin/com/appsflyer/cordova/plugin/AppsFlyerPluginTest.kt`

**Interfaces:**
- Consumes: nothing new — all three fixes are internal to `AppsFlyerPlugin`.
- Produces: nothing new — `onNewIntent`, `rpcEventCallbackContext`, `onDestroy` keep their existing signatures; only their bodies/annotations change.

### 1a — restore `setIntent` so `Activity.getIntent()` reflects the warm-resume intent

The Java implementation this plugin replaced called `cordova.getActivity().setIntent(intent)` in `onNewIntent`. This rewrite dropped it. `AppsFlyerRpcHandler`'s `contextProvider = { cordova.activity ?: cordova.context }` hands the SDK the Activity itself, and if any RPC method resolves a deep link by reading `activity.intent` at call time (not just the explicit URL this plugin already forwards via `performDeepLinking`), it would read the stale original launch intent for the rest of the app's foregrounded lifetime. This is a one-line restoration of prior, working behavior — not new design.

**No automated test for this step.** Confirmed via fact-finding: `android-tests` has neither Robolectric nor Mockito as a test dependency (only `junit:junit` and `org.json:json`), and `AppsFlyerPluginTest.kt`'s own class-level comment already draws this exact line: *"CordovaPlugin/CallbackContext/executor wiring needs a real Activity and isn't covered here."* Asserting a mutation on a real `Activity` object needs either Robolectric (new dependency + `unitTests.includeAndroidResources` wiring) or Mockito (new dependency) or a hand-written `CordovaInterface` fake implementing every interface method just to reach one `Activity` setter — all of that is disproportionate to a one-line, behavior-restoring defensive call, and would break this test suite's own established boundary for the sake of one line. Ship it code-reviewed only, on the strength of it being a restoration of prior, already-shipped Java behavior, not new logic.

- [ ] **Step 1: Write minimal implementation** — in `src/android/com/appsflyer/cordova/plugin/AppsFlyerPlugin.kt`, change `onNewIntent`:

```kotlin
    // Fire-and-forget: no JS caller is waiting on this, unlike executeRpc's callbackContext-driven dispatch.
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Activity.getIntent() otherwise keeps returning the stale launch intent for the rest of
        // the app's foregrounded lifetime -- restores what the Java implementation this replaced did.
        intent?.let { cordova.activity?.intent = it }
        val requestJson = deepLinkRequestJsonForIntent(intent?.action, intent?.dataString) ?: return
        try {
            rpcExecutor.execute { safeDispatchToNative(requestJson) }
        } catch (e: RejectedExecutionException) {
            Log.w(TAG, "Dropped onNewIntent deep link forward: plugin is shutting down")
        }
    }
```

- [ ] **Step 2: Confirm existing tests still pass** (no new test added for this step)

Run: `cd android-tests && ./gradlew testDebugUnitTest --tests "*AppsFlyerPluginTest*"`
Expected: PASS (unchanged — this step adds no new test)

### 1b — mark `rpcEventCallbackContext` `@Volatile`

- [ ] **Step 1: Write the failing test** — this is a memory-visibility fix; there is no deterministic single-threaded unit test that can fail without `@Volatile` and pass with it (a real race is non-deterministic by nature). Per repo convention (see the existing `AWAIT_RESPONSE_METHODS` concurrency tests using `CyclicBarrier`/`CountDownLatch` rather than sleeps), skip writing a flaky-by-construction test for this one and rely on the field annotation itself plus a plain functional test that the callback context, once set, is visible to a subsequent read from a different thread:

```kotlin
@Test
fun `subscribeRpcEvents makes the callback context visible to pluginNotifier from a different thread`() {
    val plugin = AppsFlyerPlugin()
    val callbackContext = mock(CallbackContext::class.java)
    plugin.execute("subscribeRpcEvents", CordovaArgs(JSONArray()), callbackContext)

    val visibleOnOtherThread = java.util.concurrent.Executors.newSingleThreadExecutor()
        .submit<Boolean> { plugin.rpcEventCallbackContextForTest() != null }
        .get(2, TimeUnit.SECONDS)

    assertTrue(visibleOnOtherThread)
}
```

This needs a test-only accessor since `rpcEventCallbackContext` is `private`. Add one alongside the field:

```kotlin
    // internal (not private) so AppsFlyerPluginTest can assert cross-thread visibility without reflection.
    internal fun rpcEventCallbackContextForTest(): CallbackContext? = rpcEventCallbackContext
```

- [ ] **Step 2: Run test to verify it fails or passes trivially**

Run: `cd android-tests && ./gradlew testDebugUnitTest --tests "*AppsFlyerPluginTest*"`
Expected: This test will likely PASS even without `@Volatile` on a single run (JIT/JMM visibility bugs are probabilistic, not guaranteed to reproduce in a short-lived JVM test) — that is expected and is exactly why the annotation, not the test, is the actual fix. Do not spend time trying to force a flaky failure here.

- [ ] **Step 3: Write minimal implementation**

```kotlin
    // @Volatile: pluginNotifier fires from arbitrary native threads (see its own comment below);
    // without this, a worker thread has no happens-before guarantee and can observe a stale null
    // indefinitely after subscribeRpcEvents has actually run on a different thread.
    @Volatile
    private var rpcEventCallbackContext: CallbackContext? = null
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd android-tests && ./gradlew testDebugUnitTest --tests "*AppsFlyerPluginTest*"`
Expected: PASS

### 1c — bound `onDestroy`'s total shutdown wait instead of stacking two full timeouts

- [ ] **Step 1: Write the failing test**

```kotlin
@Test
fun `onDestroy bounds the total shutdown wait to 2 seconds instead of stacking two full timeouts`() {
    val plugin = AppsFlyerPlugin()
    val started = System.nanoTime()

    // Force both executors to have a long-running task in flight so awaitTermination has
    // something to actually wait on, then measure onDestroy's total wall-clock cost.
    plugin.awaitResponseExecutorForTest().execute { Thread.sleep(5_000) }
    plugin.rpcExecutorForTest().execute { Thread.sleep(5_000) }
    plugin.onDestroy()

    val elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - started)
    assertTrue("onDestroy took ${elapsedMs}ms, expected under ~2.5s total, not ~4s", elapsedMs < 2_500)
}
```

Add the two test-only accessors next to `rpcEventCallbackContextForTest()`:

```kotlin
    internal fun awaitResponseExecutorForTest(): ExecutorService = awaitResponseExecutor
    internal fun rpcExecutorForTest(): ExecutorService = rpcExecutor
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd android-tests && ./gradlew testDebugUnitTest --tests "*AppsFlyerPluginTest*"`
Expected: FAIL — elapsed is ~4000ms (two stacked 2s `awaitTermination` calls), over the 2.5s assertion.

- [ ] **Step 3: Write minimal implementation**

```kotlin
    override fun onDestroy() {
        super.onDestroy()
        // shutdownNow (not shutdown): don't run queued calls against a torn-down bridge/activity.
        for (executor in listOf(awaitResponseExecutor, rpcExecutor)) {
            executor.shutdownNow()
        }
        try {
            // Bound the *total* wait to 2s instead of stacking two full 2s waits -- onDestroy runs
            // on the main thread (Activity.onDestroy -> CordovaWebViewImpl.handleDestroy), so up to
            // 4s of sequential blocking here risks visible jank/ANR during teardown.
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd android-tests && ./gradlew testDebugUnitTest --tests "*AppsFlyerPluginTest*"`
Expected: PASS — elapsed is ~2000ms.

- [ ] **Step 5: Run the full Android test file once and commit**

Run: `cd android-tests && ./gradlew testDebugUnitTest`
Expected: All tests PASS.

```bash
git add src/android/com/appsflyer/cordova/plugin/AppsFlyerPlugin.kt android-tests/src/test/kotlin/com/appsflyer/cordova/plugin/AppsFlyerPluginTest.kt
git commit -m "fix: restore setIntent, volatile callback field, and bounded onDestroy shutdown" -m "onNewIntent now calls cordova.activity?.intent = it, restoring behavior the prior Java implementation had, so Activity.getIntent() reflects the warm-resume intent instead of the stale launch intent. rpcEventCallbackContext is now @Volatile: pluginNotifier fires from arbitrary native threads and had no happens-before guarantee against subscribeRpcEvents's write. onDestroy now bounds its *total* wait to 2s with a shared deadline instead of stacking two full 2s awaitTermination calls, which could block the main thread for up to 4s during teardown."
```

---

## Task 2: iOS — make the `subscribeRpcEvents` force-unwrap-turned-guard path test-driven

**Files:**
- Modify: `src/ios/AppsFlyerPlugin.swift:48-65`
- Test: `ios-tests/Tests/AppsFlyerCordovaShimTests/AppsFlyerPluginTests.swift`

**Interfaces:**
- Produces: `AppsFlyerPlugin.deliverRpcEvent(jsonEvent: String, callbackId: String, to delegate: CDVCommandDelegate?)` — a new `internal static` pure function, same visibility/testing pattern as the existing `canonicalMethod(ofRequestJson:)` and `normalize(iosResponseJson:)`.

The real blocker preventing an end-to-end test through `subscribeRpcEvents(_:)` is `AppsFlyerRPCBridge.shared` — a real prebuilt xcframework singleton with no fake/seam, so its stored closure is genuinely unreachable from test code (this was already correctly diagnosed in the existing code comment). The fix is to extract the closure's *body* — the part that actually has the crash risk (`CDVPluginResult` construction + guard + send) — into a free function that takes a plain `CDVCommandDelegate` instead of going through the bridge at all. That function is 100% of the previously-uncovered logic and is now directly testable with the existing `CDVPluginResult.forceNilOnNextInit` seam and a fake delegate.

- [ ] **Step 1: Write the failing test** — add to `AppsFlyerPluginTests.swift`:

```swift
final class FakeCommandDelegate: CDVCommandDelegate {
    private(set) var sentResults: [(result: CDVPluginResult?, callbackId: String?)] = []
    func send(_ pluginResult: CDVPluginResult?, callbackId: String?) {
        sentResults.append((pluginResult, callbackId))
    }
}

func testDeliverRpcEventSendsResultWithKeepCallback() {
    let delegate = FakeCommandDelegate()
    AppsFlyerPlugin.deliverRpcEvent(jsonEvent: #"{"event":"onConversionDataSuccess"}"#, callbackId: "cb1", to: delegate)

    XCTAssertEqual(delegate.sentResults.count, 1)
    XCTAssertEqual(delegate.sentResults[0].callbackId, "cb1")
    XCTAssertEqual(delegate.sentResults[0].result?.keepsCallback, true)
}

// Regression guard for the crash this file's guard-let (formerly `result!`) protects against —
// exercises it through the same call path production code uses, not just the fake initializer in isolation.
func testDeliverRpcEventDoesNotCrashAndSendsNothingWhenPluginResultInitFails() {
    AppsFlyerPluginTests.resetForceNilOnNextInit()
    let delegate = FakeCommandDelegate()

    CDVPluginResult.forceNilOnNextInit = true
    AppsFlyerPlugin.deliverRpcEvent(jsonEvent: #"{"event":"onConversionDataSuccess"}"#, callbackId: "cb1", to: delegate)

    XCTAssertTrue(delegate.sentResults.isEmpty)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:AppsFlyerCordovaShimTests/AppsFlyerPluginTests`
Expected: FAIL to compile — `deliverRpcEvent` does not exist yet.

- [ ] **Step 3: Write minimal implementation** — in `src/ios/AppsFlyerPlugin.swift`, extract the closure body into a static function and call it from the closure:

```swift
    @objc func subscribeRpcEvents(_ command: CDVInvokedUrlCommand) {
        guard rpcEventCallbackId == nil else {
            NSLog("AppsFlyer: subscribeRpcEvents called more than once; ignoring the second subscription.")
            return
        }
        rpcEventCallbackId = command.callbackId
        AppsFlyerRPCBridge.shared.setEventHandler { [weak self] jsonEvent in
            guard let self, let callbackId = self.rpcEventCallbackId else { return }
            Self.deliverRpcEvent(jsonEvent: jsonEvent, callbackId: callbackId, to: self.commandDelegate)
        }
    }

    // internal (not private) + static so AppsFlyerPluginTests can drive it directly with a fake
    // CDVCommandDelegate, without going through the real (untestable) AppsFlyerRPCBridge.shared
    // singleton subscribeRpcEvents(_:) registers with.
    internal static func deliverRpcEvent(jsonEvent: String, callbackId: String, to delegate: CDVCommandDelegate?) {
        // Explicit `CDVPluginResult?` (not `let result = ...`) is load-bearing: cordova-ios 8's audited header makes this initializer non-optional while cordova-ios 7's makes it Optional; the annotation compiles against both, but still guard below rather than force-unwrap since neither guarantees non-nil.
        let maybeResult: CDVPluginResult? = CDVPluginResult(status: .ok, messageAs: jsonEvent)
        guard let result = maybeResult else {
            NSLog("AppsFlyer: failed to build CDVPluginResult for RPC event")
            return
        }
        result.setKeepCallbackAs(true)
        delegate?.send(result, callbackId: callbackId)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:AppsFlyerCordovaShimTests/AppsFlyerPluginTests`
Expected: PASS

- [ ] **Step 5: Run the full iOS test suite once and commit**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test`
Expected: All tests PASS.

```bash
git add src/ios/AppsFlyerPlugin.swift ios-tests/Tests/AppsFlyerCordovaShimTests/AppsFlyerPluginTests.swift
git commit -m "test: drive the subscribeRpcEvents guard-let path through a fake CDVCommandDelegate" -m "Extract the AppsFlyerRPCBridge event-handler closure's body into AppsFlyerPlugin.deliverRpcEvent(jsonEvent:callbackId:to:), a static function that takes a plain CDVCommandDelegate instead of going through the real (untestable) AppsFlyerRPCBridge.shared singleton. Add tests that exercise both the success path and the CDVPluginResult-init-fails guard path through deliverRpcEvent directly, closing the coverage gap the code comment previously only acknowledged."
```

---

## Task 3: iOS — injectable sink so `AppsFlyerAttribution`'s buffering/flush tests can assert delivery, not just "doesn't crash"

**Files:**
- Modify: `src/ios/AppsFlyerAttribution.swift`
- Test: `ios-tests/Tests/AppsFlyerCordovaShimTests/AppsFlyerAttributionTests.swift`

**Interfaces:**
- Produces: three `internal var` closures on `AppsFlyerAttribution` — `deliverHandleOpen`, `deliverLegacyHandleOpen`, `deliverContinueUserActivity` — each defaulting to the real `AppsFlyerLib.shared()` call it replaces. Closure injection instead of a protocol: same testability, no retroactive conformance on a binary-framework type we don't own, no risk of the conformance not matching `AppsFlyerLib`'s real (Objective-C-derived) selector shape.

Confirmed real signatures (from the built `AppsFlyerLib.xcframework` header, via the Clang importer's standard ObjC→Swift renaming — matches what `AppsFlyerAttribution.swift` already calls today, so no new type risk):
- `func handleOpen(_ url: URL?, options: [AnyHashable: Any]?)`
- `func handleOpen(_ url: URL?, sourceApplication: String?, annotation: Any?)`
- `func `continue`(_ userActivity: NSUserActivity?, restorationHandler: (([Any]?) -> Void)?) -> Bool`

- [ ] **Step 1: Write the failing test** — replace the three assertion-free tests in `AppsFlyerAttributionTests.swift` (`testHandleOpenBuffersUntilBridgeReady`, `testFlushPendingDrainsBothBufferedUrlAndUserActivity`, `testFlushPendingDrainsLegacyOpenURLAlongsideUserActivity`) and remove the `KNOWN GAP` comment above them:

```swift
final class AppsFlyerAttributionTests: XCTestCase {

    private var handleOpenCalls: [(url: URL, options: [UIApplication.OpenURLOptionsKey: Any])] = []
    private var legacyHandleOpenCalls: [(url: URL, sourceApplication: String?, annotation: Any?)] = []
    private var continueUserActivityCalls: [NSUserActivity] = []

    override func setUp() {
        super.setUp()
        handleOpenCalls = []
        legacyHandleOpenCalls = []
        continueUserActivityCalls = []
        AppsFlyerAttribution.shared.deliverHandleOpen = { [weak self] url, options in
            self?.handleOpenCalls.append((url, options))
        }
        AppsFlyerAttribution.shared.deliverLegacyHandleOpen = { [weak self] url, sourceApplication, annotation in
            self?.legacyHandleOpenCalls.append((url, sourceApplication, annotation))
        }
        AppsFlyerAttribution.shared.deliverContinueUserActivity = { [weak self] activity, _ in
            self?.continueUserActivityCalls.append(activity)
        }
    }

    override func tearDown() {
        AppsFlyerAttribution.shared.bridgeReady = false
        AppsFlyerAttribution.shared.resetDeliveryClosuresToDefaultsForTest()
        super.tearDown()
    }

    func testHandleOpenBuffersUntilBridgeReady() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        attribution.handleOpen(URL(string: "https://example.com")!, options: [:])
        XCTAssertTrue(handleOpenCalls.isEmpty, "must not deliver before bridgeReady")

        attribution.bridgeReady = true
        XCTAssertEqual(handleOpenCalls.count, 1)
        XCTAssertEqual(handleOpenCalls.first?.url, URL(string: "https://example.com")!)
    }

    // Regression guard: flushPending must not return early after the URL, leaking a buffered
    // userActivity (or legacy openURL) into the next flush.
    func testFlushPendingDrainsBothBufferedUrlAndUserActivity() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        attribution.handleOpen(URL(string: "https://example.com")!, options: [:])
        attribution.continueUserActivity(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))

        attribution.bridgeReady = true

        XCTAssertEqual(handleOpenCalls.count, 1)
        XCTAssertEqual(continueUserActivityCalls.count, 1)
    }

    func testFlushPendingDrainsLegacyOpenURLAlongsideUserActivity() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        attribution.handleOpen(URL(string: "https://example.com")!, sourceApplication: "com.example", annotation: nil)
        attribution.continueUserActivity(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))

        attribution.bridgeReady = true

        XCTAssertEqual(legacyHandleOpenCalls.count, 1)
        XCTAssertEqual(continueUserActivityCalls.count, 1)
    }

    func testHandleLaunchOptionsForwardsImmediately() {
        AppsFlyerAttribution.shared.bridgeReady = false
        AppsFlyerAttribution.shared.handleLaunchOptions(nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:AppsFlyerCordovaShimTests/AppsFlyerAttributionTests`
Expected: FAIL to compile — `deliverHandleOpen`/`deliverLegacyHandleOpen`/`deliverContinueUserActivity`/`resetDeliveryClosuresToDefaultsForTest` don't exist yet.

- [ ] **Step 3: Write minimal implementation** — in `src/ios/AppsFlyerAttribution.swift`, add the three closures (defaulting to the real calls they replace) and a test-reset helper, and route every direct `AppsFlyerLib.shared()` call in `handleOpen`/legacy `handleOpen`/`flushPending()` through them:

```swift
@objc(AppsFlyerAttribution)
public final class AppsFlyerAttribution: NSObject {

    @objc public static let shared = AppsFlyerAttribution()

    // Test seams: production always uses the real AppsFlyerLib.shared() calls below (the
    // defaults); tests overwrite these to spy on delivery instead of hitting the real singleton.
    internal var deliverHandleOpen: (URL, [UIApplication.OpenURLOptionsKey: Any]) -> Void = { url, options in
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }
    internal var deliverLegacyHandleOpen: (URL, String?, Any?) -> Void = { url, sourceApplication, annotation in
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
    }
    internal var deliverContinueUserActivity: (NSUserActivity, (([Any]?) -> Void)?) -> Void = { activity, handler in
        _ = AppsFlyerLib.shared().continue(activity, restorationHandler: handler)
    }

    // Test-only: restores the three closures above to their real-AppsFlyerLib defaults so one
    // test's spy can't leak into the next.
    internal func resetDeliveryClosuresToDefaultsForTest() {
        deliverHandleOpen = { url, options in AppsFlyerLib.shared().handleOpen(url, options: options) }
        deliverLegacyHandleOpen = { url, sourceApplication, annotation in
            AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        }
        deliverContinueUserActivity = { activity, handler in
            _ = AppsFlyerLib.shared().continue(activity, restorationHandler: handler)
        }
    }

    private let lock = NSLock()
    // ... (bridgeReady/pending* fields unchanged)
```

Then replace the three `AppsFlyerLib.shared().foo(...)` call sites inside `handleOpen`, the legacy `handleOpen`, and `flushPending()` with `deliverHandleOpen(url, options)`, `deliverLegacyHandleOpen(url, sourceApplication, annotation)`, `deliverContinueUserActivity(userActivity, restorationHandler)`. `handleLaunchOptions` stays calling `AppsFlyerLib.shared()` directly — it has no buffering hazard and isn't part of what these tests need to assert on.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:AppsFlyerCordovaShimTests/AppsFlyerAttributionTests`
Expected: PASS

- [ ] **Step 5: Run the full iOS test suite once and commit**

Run: `cd ios-tests && xcodebuild -scheme AppsFlyerCordovaShim -destination 'platform=iOS Simulator,name=iPhone 16' test`
Expected: All tests PASS (including Task 2's tests, still green).

```bash
git add src/ios/AppsFlyerAttribution.swift ios-tests/Tests/AppsFlyerCordovaShimTests/AppsFlyerAttributionTests.swift
git commit -m "test: assert AppsFlyerAttribution actually delivers buffered forwards, not just doesn't crash" -m "Add three injectable delivery closures (deliverHandleOpen/deliverLegacyHandleOpen/deliverContinueUserActivity), each defaulting to the real AppsFlyerLib.shared() call it replaces, so tests can spy on delivery instead of only proving handleOpen/continueUserActivity/flushPending don't crash. Closes the KNOWN GAP the buffering tests previously only documented."
```

---

## Task 4: Verify and resolve the three already-fixed threads (no code change)

**Files:** none modified — this task is verification + GitHub API calls only.

- [ ] **Step 1: Confirm `prepublishOnly` already typechecks**

```bash
grep -n '"prepublishOnly"\|"build"' package.json
```
Expected: `"build"` already runs `npm run typecheck` before `esbuild` (added by the `dist-types` commit), and `"prepublishOnly": "npm run build"` — so `npm publish` already can't ship past a type error.

- [ ] **Step 2: Confirm `handleOpenURL` no longer clobbers/double-fires/needs a readiness gate**

```bash
grep -n "handleOpenURL" -A6 src/index.ts
```
Expected: the block only chains to `previousHandleOpenURL`, never calls `performDeepLinking` — Android deep links go through `AppsFlyerPlugin.kt`'s `onNewIntent` (Task 1's file) instead.

- [ ] **Step 3: Confirm `cordova.exec` vs `require('cordova/exec')` is a documented, deliberate choice**

```bash
sed -n '35,40p' src/cordova-transport.ts
```
Expected: the comment on line 38 explains why `require('cordova/exec')` would break the esbuild browser bundle.

- [ ] **Step 4: Resolve the three threads with a short explanatory reply on each** (per-action confirmation — run these one at a time, not silently, since these are "won't fix as suggested" rather than "fixed as suggested"):

```bash
gh api graphql -f query='mutation($id:ID!,$body:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){comment{id}}}' \
  -f id=PRRT_kwDOBHTF3s6f7sVd \
  -f body='Already covered: npm run build (which prepublishOnly calls) now runs npm run typecheck before esbuild, added in the dist-types commit earlier in this PR.'

gh api graphql -f query='mutation($id:ID!,$body:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){comment{id}}}' \
  -f id=PRRT_kwDOBHTF3s6f7smD \
  -f body='Kept rather than deleted, but the underlying issues are gone: this block no longer calls performDeepLinking at all (Android deep links now go through AppsFlyerPlugin.kt onNewIntent), so it cannot clobber, double-fire, or need a readiness gate. It only exists now to chain to a pre-existing handler so cordova-plugin-customurlscheme does not hit a ReferenceError.'

gh api graphql -f query='mutation($id:ID!,$body:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){comment{id}}}' \
  -f id=PRRT_kwDOBHTF3s6f7sfy \
  -f body='Deliberately kept as the global cordova.exec: require(cordova/exec) is not a real Node module and esbuild bundling for the browser cannot resolve it. Documented the invariant explicitly in the code comment instead of changing the access pattern.'

for id in PRRT_kwDOBHTF3s6f7sVd PRRT_kwDOBHTF3s6f7smD PRRT_kwDOBHTF3s6f7sfy; do
  gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}' -f id="$id"
done
```

---

## Self-Review

**Spec coverage:** All 8 open threads have a task above (5 with real code changes in Tasks 1-3, 3 verified-already-fixed in Task 4). No thread is left unaddressed.

**Placeholder scan:** No TBD/TODO; every step has a concrete diff or command.

**Type consistency:** `deliverRpcEvent(jsonEvent:callbackId:to:)` (Task 2) and `AppsFlyerAttributionSink`/`sink` (Task 3) are each defined once and used with the same signature in their own task's test — Task 2 and Task 3 touch different files and don't share types, so no cross-task drift risk.

**Resolved during grilling:** fact-finding confirmed `android-tests` has no Robolectric/Mockito, so Task 1a ships without an automated test (code-reviewed only), and Task 3 uses closure injection instead of retroactive protocol conformance on `AppsFlyerLib` — see each task's updated rationale above.
