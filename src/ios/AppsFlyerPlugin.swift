//
//  AppsFlyerPlugin.swift
//  cordova-plugin-appsflyer-sdk
//
//  Thin Cordova shim over AppsFlyerRPC: one call (`executeRpc`) and one persistent event channel (`subscribeRpcEvents`). All RPC dispatch, response normalization, and threading is owned by AppsFlyerRPCBridge — this file only shapes JSON envelopes and Cordova plumbing.

import Foundation
#if AF_CORDOVA_SPM_TEST
import Cordova
#endif
import AppsFlyerRPC

@objc(AppsFlyerPlugin)
public class AppsFlyerPlugin: CDVPlugin {
    private let lock = NSLock()
    private var _rpcEventCallbackId: String?
    private var rpcEventCallbackId: String? {
        get { lock.withCriticalScope { _rpcEventCallbackId } }
        set { lock.withCriticalScope { _rpcEventCallbackId = newValue } }
    }

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
        let callbackId = command.callbackId
        let delegate = self.commandDelegate
        Task {
            AppsFlyerRPCBridge.shared.executeJson(requestJson) { responseJson in
                let (normalized, succeeded) = Self.normalize(iosResponseJson: responseJson)
                DispatchQueue.main.async {
                    if requestedMethod == "initialize" && succeeded {
                        AppsFlyerAttribution.shared.bridgeReady = true
                    }
                    guard let result = CDVPluginResult(status: .ok, messageAs: normalized) else {
                        NSLog("AppsFlyer: failed to build CDVPluginResult for executeRpc")
                        return
                    }
                    delegate?.send(result, callbackId: callbackId)
                }
            }
        }
    }

    @objc func subscribeRpcEvents(_ command: CDVInvokedUrlCommand) {
        guard rpcEventCallbackId == nil else {
            NSLog("AppsFlyer: subscribeRpcEvents called more than once; ignoring the second subscription.")
            let result = CDVPluginResult(status: .error, messageAs: "subscribeRpcEvents called more than once; ignoring duplicate subscription.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        rpcEventCallbackId = command.callbackId
        AppsFlyerRPCBridge.shared.setEventHandler { [weak self] jsonEvent in
            guard let self, let callbackId = self.rpcEventCallbackId else { return }
            Self.deliverRpcEvent(jsonEvent: jsonEvent, callbackId: callbackId, to: self.commandDelegate)
        }
    }

    internal static func deliverRpcEvent(jsonEvent: String, callbackId: String, to delegate: CDVCommandDelegate?) {
        let maybeResult: CDVPluginResult? = CDVPluginResult(status: .ok, messageAs: jsonEvent)
        guard let result = maybeResult else {
            NSLog("AppsFlyer: failed to build CDVPluginResult for RPC event")
            return
        }
        result.setKeepCallbackAs(true)
        delegate?.send(result, callbackId: callbackId)
    }

    // WebView reload invalidates all previously issued callbackIds — Cordova calls this so plugins can drop stale ones instead of sending to a dead callback forever.
    public override func onReset() {
        super.onReset()
        rpcEventCallbackId = nil
        AppsFlyerRPCBridge.shared.removeEventHandler()
    }

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
            let code = result["code"] as? Int ?? 500
            let message = (result["error"] as? String) ?? (result["message"] as? String) ?? "SDK-level failure"
            return (encodeNormalizedError(code: code, message: message), false)
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
