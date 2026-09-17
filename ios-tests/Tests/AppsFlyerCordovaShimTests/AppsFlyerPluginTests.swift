import XCTest
import Cordova
@testable import AppsFlyerCordovaShim

// normalize()/canonicalMethod() are the pure functions executeRpc() uses to shape every RPC response, success or error.

final class AppsFlyerPluginTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        CDVPluginResult.forceNilOnNextInit = false
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

    func testNormalizeForwardsSdkLevelFailureCodeInsteadOfHardcoding500() {
        let iosResponse = #"{"result":{"success":false,"code":599,"error":"native validation failed"}}"#
        let (json, succeeded) = AppsFlyerPlugin.normalize(iosResponseJson: iosResponse)
        XCTAssertFalse(succeeded)
        XCTAssertTrue(json.contains("\"code\":599"))
    }

    final class FakeCommandDelegate: CDVCommandDelegate {
        private(set) var sentResults: [(result: CDVPluginResult?, callbackId: String?)] = []
        var onSend: (() -> Void)?

        func send(_ pluginResult: CDVPluginResult?, callbackId: String?) {
            sentResults.append((pluginResult, callbackId))
            onSend?()
        }
    }

    func testDeliverRpcEventSendsResultWithKeepCallback() {
        let delegate = FakeCommandDelegate()
        let sent = expectation(description: "RPC event sent")
        delegate.onSend = {
            XCTAssertTrue(Thread.isMainThread)
            sent.fulfill()
        }
        AppsFlyerPlugin.deliverRpcEvent(jsonEvent: #"{"event":"onConversionDataSuccess"}"#, callbackId: "cb1", to: delegate)
        wait(for: [sent], timeout: 1)

        XCTAssertEqual(delegate.sentResults.count, 1)
        XCTAssertEqual(delegate.sentResults[0].callbackId, "cb1")
        XCTAssertEqual(delegate.sentResults[0].result?.keepsCallback, true)
    }

    func testDeliverRpcEventDoesNotCrashAndSendsNothingWhenPluginResultInitFails() {
        let delegate = FakeCommandDelegate()

        CDVPluginResult.forceNilOnNextInit = true
        AppsFlyerPlugin.deliverRpcEvent(jsonEvent: #"{"event":"onConversionDataSuccess"}"#, callbackId: "cb1", to: delegate)

        XCTAssertTrue(delegate.sentResults.isEmpty)
    }

    func testFakePluginResultInitializerIsNilForOneForcedCallOnly() {
        XCTAssertNotNil(CDVPluginResult(status: .ok, messageAs: "default"))

        CDVPluginResult.forceNilOnNextInit = true
        XCTAssertNil(CDVPluginResult(status: .ok, messageAs: "forced"))
        XCTAssertNotNil(CDVPluginResult(status: .ok, messageAs: "reset"))
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
