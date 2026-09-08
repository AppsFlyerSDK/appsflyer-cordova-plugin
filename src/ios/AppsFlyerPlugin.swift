//
//  AppsFlyerPlugin.swift
//  cordova-plugin-appsflyer-sdk
//
//  Thin Cordova shim over AppsFlyerRPC: one call (`executeRpc`) and one persistent event channel (`subscribeRpcEvents`). All RPC dispatch, response normalization, and threading is owned by AppsFlyerRPCBridge — this file only shapes JSON envelopes and Cordova plumbing.

import Foundation
// A real Cordova iOS project has no Swift module named "Cordova" (CordovaLib is a plain Obj-C static library reached via the project's auto-generated bridging header); the ios-tests/ SPM harness has no such header, so it fakes "Cordova" as an importable module instead — this flag is defined only there.
#if AF_CORDOVA_SPM_TEST
import Cordova
#endif
import AppsFlyerRPC

@objc(AppsFlyerPlugin)
public class AppsFlyerPlugin: CDVPlugin {

    // Cordova has no notifyListeners equivalent — a persistent event stream is one stored callbackId re-sent with keepCallback (Cordova's watchPosition-style pattern), guarded so a second subscribeRpcEvents call can't register a second native handler and double-fire events. Written on Cordova's dispatch thread, read from the RPC bridge's delivery thread — same cross-thread hazard/lock pattern as AppsFlyerAttribution.swift's `bridgeReady`.
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
            // Explicit `CDVPluginResult?` (not `let result = ...`) is load-bearing: cordova-ios 8's audited header makes this initializer non-optional while cordova-ios 7's makes it Optional; the annotation compiles against both, but still guard below rather than force-unwrap since neither guarantees non-nil.
            let maybeResult: CDVPluginResult? = CDVPluginResult(status: .ok, messageAs: jsonEvent)
            guard let result = maybeResult else {
                NSLog("AppsFlyer: failed to build CDVPluginResult for RPC event")
                return
            }
            result.setKeepCallbackAs(true)
            self.commandDelegate.send(result, callbackId: callbackId)
        }
    }

    // WebView reload invalidates all previously issued callbackIds — Cordova calls this so plugins can drop stale ones instead of sending to a dead callback forever.
    public override func onReset() {
        super.onReset()
        rpcEventCallbackId = nil
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

private extension NSLock {
    // Same iOS-15-compatible equivalent as AppsFlyerAttribution.swift's `withCriticalScope` (NSLocking.withLock is iOS 16+); duplicated here since that one is file-private there.
    func withCriticalScope<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
