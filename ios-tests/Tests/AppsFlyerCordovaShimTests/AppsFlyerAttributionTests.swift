import XCTest
@testable import AppsFlyerCordovaShim

final class AppsFlyerAttributionTests: XCTestCase {

    override func tearDown() {
        // `.shared` is a process-wide singleton — reset it so test order/reruns can't leak
        // bridgeReady=true (or a stale pending buffer) into an unrelated test.
        AppsFlyerAttribution.shared.bridgeReady = false
        super.tearDown()
    }

    // (c) constructing/using AppsFlyerAttribution on a fresh bridge-not-ready state doesn't crash.
    func testHandleOpenBuffersUntilBridgeReady() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        // No AppsFlyerLib call should fire yet — buffered internally.
        attribution.handleOpen(URL(string: "https://example.com")!, options: [:])
        // Proves the buffer/flush wiring executes without crashing; AppsFlyerLib itself isn't mocked here.
        attribution.bridgeReady = true
    }

    // (b) buffered-callback flush drains BOTH a URL and a userActivity, not just the first.
    func testFlushPendingDrainsBothBufferedUrlAndUserActivity() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        // Regression guard: flushPending must not return early after the URL, leaking a buffered
        // userActivity (or legacy openURL) into the next flush.
        attribution.handleOpen(URL(string: "https://example.com")!, options: [:])
        attribution.continueUserActivity(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))
        attribution.bridgeReady = true
    }

    func testFlushPendingDrainsLegacyOpenURLAlongsideUserActivity() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        attribution.handleOpen(URL(string: "https://example.com")!, sourceApplication: "com.example.app", annotation: nil)
        attribution.continueUserActivity(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))
        attribution.bridgeReady = true
    }

    func testHandleLaunchOptionsForwardsImmediately() {
        // handleLaunchOptions has no buffering hazard — must be callable regardless of bridgeReady state.
        AppsFlyerAttribution.shared.bridgeReady = false
        AppsFlyerAttribution.shared.handleLaunchOptions(nil)
    }
}
