import XCTest
@testable import AppsFlyerCordovaShim

// Covers the "success passthrough" leg of Step 1's verification: normalize()/canonicalMethod()
// are the pure functions executeRpc() uses to shape every RPC response, success or error.

final class AppsFlyerPluginTests: XCTestCase {

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

    func testCanonicalMethodExtractsMethodName() {
        let requestJson = #"{"method":"initialize","params":{}}"#
        XCTAssertEqual(AppsFlyerPlugin.canonicalMethod(ofRequestJson: requestJson), "initialize")
    }

    // Same cases as the Android envelope-parity tests — keep in sync; proves both platforms emit
    // an identical { success, data|error } shape despite differently-shaped raw input.

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
