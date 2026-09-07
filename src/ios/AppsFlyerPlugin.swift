//
//  AppsFlyerPlugin.swift
//  cordova-plugin-appsflyer-sdk
//
//  Thin Cordova shim over AppsFlyerRPC: one call (`executeRpc`) and one persistent event
//  channel (`subscribeRpcEvents`). All RPC dispatch, response normalization, and threading is
//  owned by AppsFlyerRPCBridge — this file only shapes JSON envelopes and Cordova plumbing.

import Foundation
// A real generated Cordova iOS project has no Swift module named "Cordova" -- CordovaLib is a
// plain Obj-C static library, and its types (CDVPlugin, CDVInvokedUrlCommand, ...) reach Swift
// only via the project's auto-generated Objective-C bridging header, which is implicitly visible
// to every Swift file in the target without an import statement. The ios-tests/ SPM harness has
// no bridging header (SPM doesn't support one per-file the way Xcode does target-wide), so it
// fakes "Cordova" as a real importable Swift module instead -- this flag is defined only there.
#if AF_CORDOVA_SPM_TEST
import Cordova
#endif
import AppsFlyerRPC

@objc(AppsFlyerPlugin)
public class AppsFlyerPlugin: CDVPlugin {

    // Cordova has no notifyListeners equivalent — a persistent event stream is one stored
    // callbackId re-sent with keepCallback, the same pattern Cordova's own watchPosition-style
    // plugins use. Guarded so a second subscribeRpcEvents call can't register a second native
    // event handler (which would double-fire every event to whichever callback last won the race).
    private var rpcEventCallbackId: String?

    @objc func executeRpc(_ command: CDVInvokedUrlCommand) {
        guard
            let args = command.arguments.first as? [String: Any],
            let requestJson = args["requestJson"] as? String
        else {
            let result = CDVPluginResult(status: .error, messageAs: "requestJson is required")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        let requestedMethod = Self.canonicalMethod(ofRequestJson: requestJson)
        Task {
            AppsFlyerRPCBridge.shared.executeJson(requestJson) { [weak self] responseJson in
                let (normalized, succeeded) = Self.normalize(iosResponseJson: responseJson)
                if requestedMethod == "initialize" && succeeded {
                    // Setting bridgeReady triggers AppsFlyerAttribution's own didSet flush.
                    AppsFlyerAttribution.shared.bridgeReady = true
                }
                let result = CDVPluginResult(status: .ok, messageAs: normalized)
                self?.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc func subscribeRpcEvents(_ command: CDVInvokedUrlCommand) {
        guard rpcEventCallbackId == nil else {
            NSLog("AppsFlyer: subscribeRpcEvents called more than once; ignoring the second subscription.")
            return
        }
        rpcEventCallbackId = command.callbackId
        AppsFlyerRPCBridge.shared.setEventHandler { [weak self] jsonEvent in
            guard let self, let callbackId = self.rpcEventCallbackId else { return }
            // Explicit `?` here (not `let result = ...`) is load-bearing: cordova-ios 8's
            // NS_ASSUME_NONNULL-audited CDVPluginResult.h makes this initializer return a
            // non-optional, while cordova-ios 7's unaudited header makes it a genuine Optional.
            // The annotation coerces cleanly from either, so this line compiles against both.
            let result: CDVPluginResult? = CDVPluginResult(status: .ok, messageAs: jsonEvent)
            result?.setKeepCallbackAs(true)
            self.commandDelegate.send(result!, callbackId: callbackId)
        }
    }

    // internal (not private) + static so AppsFlyerPluginTests can call these directly.
    static func canonicalMethod(ofRequestJson requestJson: String) -> String? {
        guard
            let data = requestJson.data(using: .utf8),
            let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return request["method"] as? String
    }

    /// Normalizes iOS's AFRPCResponse into the shared { success, data|error } shape.
    static func normalize(iosResponseJson responseJson: String) -> (json: String, succeeded: Bool) {
        guard
            let data = responseJson.data(using: .utf8),
            let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return (encodeNormalizedError(code: 500, message: "Malformed AFRPCResponse from native RPC layer"), false)
        }

        if let error = response["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? 500
            let message = error["message"] as? String ?? "Unknown protocol error"
            return (encodeNormalizedError(code: code, message: message), false)
        }

        guard let result = response["result"] as? [String: Any] else {
            return (encodeNormalizedError(code: 500, message: "Missing result in AFRPCResponse"), false)
        }

        guard let succeeded = result["success"] as? Bool else {
            return (encodeNormalizedError(code: 500, message: "AFRPCResponse.result missing success flag"), false)
        }
        if !succeeded {
            let message = (result["error"] as? String) ?? (result["message"] as? String) ?? "SDK-level failure"
            return (encodeNormalizedError(code: 500, message: message), false)
        }

        return (encodeJSONOrFallback(["success": true, "data": result["data"] ?? NSNull()]), true)
    }

    private static func encodeNormalizedError(code: Int, message: String) -> String {
        encodeJSONOrFallback(["success": false, "error": ["code": code, "message": message]])
    }

    private static func encodeJSONOrFallback(_ object: [String: Any]) -> String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: object),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{\"success\":false,\"error\":{\"code\":500,\"message\":\"Failed to encode RPC response\"}}"
        }
        return json
    }
}
