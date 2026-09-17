import XCTest
@testable import AppsFlyerCordovaShim

final class AppsFlyerAttributionTests: XCTestCase {

    private var handleOpenCalls: [(url: URL, options: [UIApplication.OpenURLOptionsKey: Any])] = []
    private var legacyHandleOpenCalls: [(url: URL, sourceApplication: String?, annotation: Any?)] = []
    private var continueUserActivityCalls: [NSUserActivity] = []
    private var handleLaunchOptionsCalls: [[AnyHashable: Any]?] = []

    override func setUp() {
        super.setUp()
        handleOpenCalls = []
        legacyHandleOpenCalls = []
        continueUserActivityCalls = []
        handleLaunchOptionsCalls = []
        // Spy on delivery instead of hitting the real AppsFlyerLib.shared() singleton.
        AppsFlyerAttribution.shared.deliverHandleOpen = { [weak self] url, options in
            self?.handleOpenCalls.append((url, options))
        }
        AppsFlyerAttribution.shared.deliverLegacyHandleOpen = { [weak self] url, sourceApplication, annotation in
            self?.legacyHandleOpenCalls.append((url, sourceApplication, annotation))
        }
        AppsFlyerAttribution.shared.deliverContinueUserActivity = { [weak self] activity, _ in
            self?.continueUserActivityCalls.append(activity)
        }
        AppsFlyerAttribution.shared.deliverHandleLaunchOptions = { [weak self] options in
            self?.handleLaunchOptionsCalls.append(options)
        }
    }

    override func tearDown() {
        // `.shared` is a process-wide singleton — reset so test order/reruns can't leak bridgeReady=true, a stale pending buffer, or a spy closure into another test.
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

    // Regression guard: flushPending must not return early after the URL, leaking a buffered userActivity (or legacy openURL) into the next flush.
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
        attribution.handleOpen(URL(string: "https://example.com")!, sourceApplication: "com.example.app", annotation: nil)
        attribution.continueUserActivity(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))

        attribution.bridgeReady = true

        XCTAssertEqual(legacyHandleOpenCalls.count, 1)
        XCTAssertEqual(continueUserActivityCalls.count, 1)
    }

    // handleLaunchOptions has no buffering hazard — must be callable regardless of bridgeReady state.
    func testHandleLaunchOptionsForwardsImmediately() {
        let options: [AnyHashable: Any] = ["UIApplicationLaunchOptionsURLKey": "https://example.com/launch"]
        AppsFlyerAttribution.shared.bridgeReady = false
        AppsFlyerAttribution.shared.handleLaunchOptions(options)

        XCTAssertEqual(handleLaunchOptionsCalls.count, 1)
        let forwarded = handleLaunchOptionsCalls.first.flatMap { $0 }
        XCTAssertEqual(forwarded?["UIApplicationLaunchOptionsURLKey"] as? String, "https://example.com/launch")
    }
}
