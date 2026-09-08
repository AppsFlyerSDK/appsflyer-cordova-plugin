import XCTest
@testable import AppsFlyerCordovaShim

// KNOWN GAP: the three buffering/flush tests below only assert "doesn't crash", not that flushPending() actually delivered each buffered URL/legacy-URL/userActivity to AppsFlyerLib — pendingUrl/pendingLegacyUrl/pendingUserActivity are `private` (unreachable via @testable) and flushPending() calls the real AppsFlyerLib.shared() singleton with no spy seam. Fixing this needs a production change in AppsFlyerAttribution.swift (an injectable sink protocol, or relaxing the pending* fields to `internal`) outside this file's ownership — flagged as a follow-up, not worked around here.
final class AppsFlyerAttributionTests: XCTestCase {

    override func tearDown() {
        // `.shared` is a process-wide singleton — reset so test order/reruns can't leak bridgeReady=true or a stale pending buffer into another test.
        AppsFlyerAttribution.shared.bridgeReady = false
        super.tearDown()
    }

    func testHandleOpenBuffersUntilBridgeReady() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
        attribution.handleOpen(URL(string: "https://example.com")!, options: [:])
        attribution.bridgeReady = true
    }

    // Regression guard: flushPending must not return early after the URL, leaking a buffered userActivity (or legacy openURL) into the next flush.
    func testFlushPendingDrainsBothBufferedUrlAndUserActivity() {
        let attribution = AppsFlyerAttribution.shared
        attribution.bridgeReady = false
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

    // handleLaunchOptions has no buffering hazard — must be callable regardless of bridgeReady state.
    func testHandleLaunchOptionsForwardsImmediately() {
        AppsFlyerAttribution.shared.bridgeReady = false
        AppsFlyerAttribution.shared.handleLaunchOptions(nil)
    }
}
