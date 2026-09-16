import XCTest
import Cordova
@testable import AppsFlyerCordovaShim

// normalize()/canonicalMethod() are the pure functions executeRpc() uses to shape every RPC response, success or error.

final class AppsFlyerPluginTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        CDVPluginResult.forceNilOnNextInit = false
    }

    func testNormalizeReturnsSuccessEnvelope() {
        let iosResponse = #"{"result":{"success":true,"data":{"uid":"abc"}}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertTrue(succeeded)
        XCTAssertTrue(json.contains("\"success\":true"))
        XCTAssertTrue(json.contains("\"uid\":\"abc\""))
    }

    func testNormalizeReturnsErrorEnvelopeOnProtocolError() {
        let iosResponse = #"{"error":{"code":404,"message":"not found"}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("\"code\":404"))
    }

    func testNormalizeFailsClosedWhenResultMissingSuccessFlag() {
        let iosResponse = #"{"result":{"data":{"uid":"abc"}}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("missing success flag"))
    }

    func testNormalizeReturnsErrorEnvelopeOnMalformedJson() {
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: "not json")
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("Malformed AFRPCResponse"))
    }

    func testNormalizeReturnsErrorEnvelopeOnSdkLevelFailure() {
        let iosResponse = #"{"result":{"success":false,"error":"native validation failed"}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("native validation failed"))
    }

    // Regression guard for the parallel fix that stopped hardcoding 500 on SDK-level failure.
    func testNormalizeForwardsSdkLevelFailureCodeInsteadOfHardcoding500() {
        let iosResponse = #"{"result":{"success":false,"code":599,"error":"native validation failed"}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("\"code\":599"))
    }

    // Proves the fake CDVPluginResult init? mirrors the real Obj-C initializer's contract both ways (non-nil normally, nil when forced) — the failure mode AppsFlyerPlugin.subscribeRpcEvents' guard-let branch (formerly `result!`) now fails safe against. Not exercised through subscribeRpcEvents(_:) itself: it registers with the prebuilt AppsFlyerRPCBridge.shared xcframework, so the stored closure isn't reachable from test code; real coverage needs an injectable event-handler seam (production code) or a generated Cordova project.
    func testFakeCDVPluginResultInitCanReturnNilOrNonNil() {
        AppsFlyerPluginTests.resetForceNilOnNextInit()

        XCTAssertNotNil(CDVPluginResult(status: .ok, messageAs: "{}"))

        CDVPluginResult.forceNilOnNextInit = true
        XCTAssertNil(CDVPluginResult(status: .ok, messageAs: "{}"))

        // The toggle is single-shot — must not leak into the next construction.
        XCTAssertNotNil(CDVPluginResult(status: .ok, messageAs: "{}"))
    }

    private static func resetForceNilOnNextInit() {
        CDVPluginResult.forceNilOnNextInit = false
    }

    // The real blocker to testing subscribeRpcEvents(_:) end-to-end is AppsFlyerRPCBridge.shared,
    // a real prebuilt xcframework singleton with no fake -- deliverRpcEvent is the closure body it
    // registers, extracted so the guard-let-or-bail path (formerly `result!`) is directly testable
    // without going through the bridge at all.
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

    // Regression guard for the crash this file's guard-let (formerly `result!`) protects against.
    func testDeliverRpcEventDoesNotCrashAndSendsNothingWhenPluginResultInitFails() {
        AppsFlyerPluginTests.resetForceNilOnNextInit()
        let delegate = FakeCommandDelegate()

        CDVPluginResult.forceNilOnNextInit = true
        AppsFlyerPlugin.deliverRpcEvent(jsonEvent: #"{"event":"onConversionDataSuccess"}"#, callbackId: "cb1", to: delegate)

        XCTAssertTrue(delegate.sentResults.isEmpty)
    }

    func testCanonicalMethodExtractsMethodName() {
        let requestJson = #"{"method":"initialize","params":{}}"#
        XCTAssertEqual(AppsFlyerPlugin.canonicalMethod(ofRequestJson: requestJson), "initialize")
    }

    // Same cases as the Android envelope-parity tests (keep in sync) — proves both platforms emit an identical { success, data|error } shape despite differently-shaped raw input.

    func testEnvelopeParity_successfulResultWithData_matchesAndroid() {
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: #"{"result":{"success":true,"data":{"uid":"abc"}}}"#)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(json.jsonNormalized, #"{"success":true,"data":{"uid":"abc"}}"#.jsonNormalized)
    }

    func testEnvelopeParity_voidSuccess_matchesAndroid() {
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: #"{"result":{"success":true}}"#)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(json.jsonNormalized, #"{"success":true,"data":null}"#.jsonNormalized)
    }

    func testEnvelopeParity_protocolError_matchesAndroid() {
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: #"{"error":{"code":404,"message":"not found"}}"#)
        XCTAssertFalse(succeeded)
        XCTAssertEqual(json.jsonNormalized, #"{"success":false,"error":{"code":404,"message":"not found"}}"#.jsonNormalized)
    }
}

private extension String {
    // JSONSerialization doesn't guarantee key order — compare by decoded structure, not the raw string.
    var jsonNormalized: String {
        guard
            let data = data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let normalized = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
            let string = String(data: normalized, encoding: .utf8)
        else {
            return self
        }
        return string
    }
}
