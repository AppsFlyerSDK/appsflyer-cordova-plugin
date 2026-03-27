//
//  AppsFlyerPlugin.swift
//  AppsFlyer Cordova Plugin
//
//  Swift plugin — RPC entry point mirrors Android `AppsFlyerPlugin.executeRpc`:
//  JS passes `{ method, params }`, native builds JSON-RPC and runs `AFRPCClient.execute`.
//

import Foundation
import UIKit
import AppsFlyerRPC

/// iOS Cordova plugin: JSON-RPC via `AppsFlyerRPC` (`executeRpc`). Registered as `AppsFlyerPlugin` in plugin.xml.
@objc(AppsFlyerPlugin)
public class AppsFlyerPlugin: CDVPlugin {

    private static let rpcLogPrefix = "[AppsFlyer RPC]"

    /// Cordova plugin version for RPC `setPluginInfo` (align with `package.json` / Android `AppsFlyerConstants.PLUGIN_VERSION`).
    private static let cordovaPluginVersion = "6.17.8"

    /// Logs to Xcode / device console (`NSLog`). Filter: `AppsFlyer RPC`
    private func logRpc(_ message: String) {
        NSLog("%@ %@", Self.rpcLogPrefix, message)
    }

    private static func logRpc(_ message: String) {
        NSLog("%@ %@", rpcLogPrefix, message)
    }

    private static func truncateForLog(_ string: String, max: Int = 800) -> String {
        guard string.count > max else { return string }
        return String(string.prefix(max)) + "…(\(string.count) chars total)"
    }

    // MARK: - RPC client

    private lazy var rpcClient: AFRPCClient = {
        AFRPCClient { [weak self] json in
            self?.handleRpcBridgeEvent(json)
        }
    }()

    /// Internal: fire-and-forget RPC `start` (same `AFRPCClient` as `executeRpc`). Posted on foreground after JS has started once.
    private static let rpcStartFireAndForgetNotification = Notification.Name("AppsFlyerRpcStartFireAndForget")

    /// Matches `AF_BRIDGE_SET` in `AppsFlyerAttribution.h` (`bridge is set`).
    private static let appsFlyerBridgeSetNotification = Notification.Name("bridge is set")

    /// After JS invokes RPC `start` once, `UIApplication.didBecomeActive` re-posts fire-and-forget `start` (replaces Obj-C `shouldStartSdk` / `sendLaunch:`).
    private var shouldStartSdk = false

    /// Ensures we only register `NotificationCenter` observers once per plugin instance.
    private var didRegisterNotificationObservers = false

    /// Cordova callback IDs for streaming RPC events.
    private var conversionListenerCallbackId: String?
    private var deepLinkListenerCallbackId: String?
    private var sessionReadyListenerCallbackId: String?

    // MARK: - Event type constants

    private static let afOnInstallConversionDataLoaded = "onInstallConversionDataLoaded"
    private static let afOnInstallConversionFailure = "onInstallConversionFailure"
    private static let afOnDeepLinking = "onDeepLinking"
    private static let afOnSessionReady = "onSessionReady"
    private static let afSuccess = "success"

    // MARK: - Cordova plugin lifecycle

    public override func pluginInitialize() {
        super.pluginInitialize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - executeRpc

    /// Args: `[ { "method": "<name>", "params": { ... } } ]`
    @objc public func executeRpc(_ command: CDVInvokedUrlCommand) {
        Task { @MainActor in
            await self.executeRpcAsync(command)
        }
    }

    private func executeRpcAsync(_ command: CDVInvokedUrlCommand) async {
        guard let options = command.arguments.first as? [String: Any] else {
            logRpc("executeRpc: error — missing options object")
            sendCordovaError(command, message: "PARSE_ERRORMissing options object")
            return
        }

        let rawMethod = options["method"] as? String
        if rawMethod == nil || rawMethod?.isEmpty == true {
            logRpc("executeRpc: error — missing method")
            sendCordovaError(command, message: "INVALID_PARAMETERSMissing method")
            return
        }

        let method = rawMethod!
        logRpc("executeRpc: begin method=\(method) callbackId=\(command.callbackId ?? "nil")")

        applyCallbackRegistrationForMethod(method, command: command)

        let paramsObject = normalizeRpcParams(options["params"])
        let normalized = normalizeRpcInvocation(method: method, params: paramsObject)

        switch normalized {
        case .localAckOnly:
            logRpc("executeRpc: localAckOnly (no RPC call) for method=\(method)")
            sendRegistrationAck(command: command) { [weak self] result in
                guard let self = self, let result = result else { return }
                self.logRpc("executeRpc: sending localAckOnly result for callbackId=\(command.callbackId ?? "nil")")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
            return
        case let .invoke(rpcMethod, rpcParams):
            if rpcMethod != method {
                logRpc("executeRpc: normalized \(method) → RPC method=\(rpcMethod)")
            }

            if rpcMethod == "init" {
                setupAttributionBridgeAndForegroundObserversIfNeeded()
                await sendPluginInfoBeforeInit()
            }

            if rpcMethod == "start" {
                shouldStartSdk = true
            }

            let requestJson: String
            do {
                requestJson = try Self.buildJsonRpcEnvelope(method: rpcMethod, params: rpcParams)
            } catch {
                logRpc("executeRpc: build envelope failed: \(error.localizedDescription)")
                sendCordovaError(command, message: "PARSE_ERROR\(error.localizedDescription)")
                return
            }

            logRpc("executeRpc: request \(Self.truncateForLog(requestJson))")

            let responseJson = await rpcClient.execute(jsonRequest: requestJson)
            logRpc("executeRpc: response \(Self.truncateForLog(responseJson))")

            Self.sendRpcEnvelopeToCordova(
                responseJson,
                originalMethod: method,
                command: command
            ) { [weak self] result in
                guard let self = self, let result = result else {
                    Self.logRpc("executeRpc: sendRpcEnvelope callback with nil result")
                    return
                }
                // CDVPluginResult.status is NSNumber in Cordova (not Swift enum).
                self.logRpc("executeRpc: sending Cordova result status=\(result.status.intValue) for callbackId=\(command.callbackId ?? "nil")")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    /// `params` may be `nil`, `NSNull`, or a dictionary (Cordova / JS).
    private func normalizeRpcParams(_ value: Any?) -> [String: Any] {
        if value == nil || value is NSNull {
            return [:]
        }
        if let dict = value as? [String: Any] {
            return dict
        }
        return [:]
    }

    // MARK: - Cordova method names → iOS AFRPC

    /// Renames Cordova-only RPC method aliases and applies transforms that are not expressible as fixed key names in JS (`www/appsflyer.js` sends native RPC names/params for iOS where possible).
    private func normalizeRpcInvocation(method: String, params: [String: Any]) -> NormalizedRpcInvocation {
        switch method {
        case "subscribeForDeepLink":
            return .invoke(method: "registerDeeplinkListener", params: params)
        case "unsubscribeForDeepLink":
            return .localAckOnly
        case "unregisterConversionListener":
            return .localAckOnly
        case "unregisterSessionReadyListener":
            return .localAckOnly
        case "validateAndLogInAppPurchaseV2":
            var p = params
            if var transaction = p["transaction"] as? [String: Any] {
                transaction["purchaseType"] = Self.normalizePurchaseTypeForValidateAndLogV2(transaction["purchaseType"])
                p["transaction"] = transaction
            }
            return .invoke(method: "validateAndLogInAppPurchaseV2", params: p)
        default:
            return .invoke(method: method, params: params)
        }
    }

    /// Maps Cordova `AFPurchaseDetails.purchaseType` strings to RPC `validateAndLogInAppPurchaseV2` values (`subscription` | `oneTimePurchase`).
    private static func normalizePurchaseTypeForValidateAndLogV2(_ raw: Any?) -> String {
        if raw == nil || raw is NSNull {
            return "oneTimePurchase"
        }
        let string: String
        if let s = raw as? String {
            string = s
        } else {
            string = String(describing: raw as Any)
        }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "oneTimePurchase"
        }
        let normalized = trimmed.lowercased().replacingOccurrences(of: "_", with: "")
        if normalized == "subscription" {
            return "subscription"
        }
        return "oneTimePurchase"
    }

    private enum NormalizedRpcInvocation {
        case invoke(method: String, params: [String: Any])
        /// No RPC call: iOS AppsFlyerRPC has no unsubscribe APIs — Cordova callback is cleared in `applyCallbackRegistrationForMethod`
        case localAckOnly
    }

    // MARK: - Plugin info (before init)

    /// Cordova host marker: RPC `setPluginInfo` before `init`.
    /// Failures are logged only; `init` always proceeds afterward.
    private func sendPluginInfoBeforeInit() async {
        do {
            let pluginInfoJson = try Self.buildJsonRpcEnvelope(
                method: "setPluginInfo",
                params: ["plugin": "cordova", "pluginVersion": Self.cordovaPluginVersion]
            )
            logRpc("sendPluginInfoBeforeInit: request \(Self.truncateForLog(pluginInfoJson))")
            let pluginInfoResponse = await rpcClient.execute(jsonRequest: pluginInfoJson)
            logRpc("sendPluginInfoBeforeInit: raw response \(pluginInfoResponse)")
        } catch {
            logRpc("sendPluginInfoBeforeInit: ignoring envelope error, proceeding with init — \(error.localizedDescription)")
        }
    }

    private static func buildJsonRpcEnvelope(method: String, params: [String: Any]) throws -> String {
        let envelope: [String: Any] = [
            "method": method,
            "params": params
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])
        guard let str = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AppsFlyerPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "UTF-8 encode failed"])
        }
        return str
    }

    /// `true` for RPC calls that only register a Cordova callback
    private static func isCallbackRegistrationOnlyMethod(_ originalMethod: String) -> Bool {
        switch originalMethod {
        case "registerSessionReadyListener", "subscribeForDeepLink", "registerDeeplinkListener", "registerConversionListener":
            return true
        default:
            return false
        }
    }

    // MARK: - Attribution bridge (SDK `init` RPC)

    /// Sets `isBridgeReady`, posts `AF_BRIDGE_SET`, registers `UIApplication.didBecomeActive` + internal fire-and-forget `start` observer.
    private func setupAttributionBridgeAndForegroundObserversIfNeeded() {
        guard !didRegisterNotificationObservers else { return }
        didRegisterNotificationObservers = true

        setAppsFlyerAttributionBridgeReady()
        NotificationCenter.default.post(name: Self.appsFlyerBridgeSetNotification, object: self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRpcStartFireAndForgetNotification),
            name: Self.rpcStartFireAndForgetNotification,
            object: nil
        )
        Self.logRpc("setupAttributionBridge: bridge ready + foreground observers (init RPC)")
    }

    /// Sets `[AppsFlyerAttribution shared].isBridgeReady` without importing Obj‑C headers into the app’s Swift bridging header (Cordova often omits that import).
    private func setAppsFlyerAttributionBridgeReady() {
        guard let cls = NSClassFromString("AppsFlyerAttribution") else {
            Self.logRpc("setAppsFlyerAttributionBridgeReady: AppsFlyerAttribution class not found — ensure AppsFlyerAttribution.m is in the iOS target")
            return
        }
        guard let shared = (cls as AnyObject).perform(NSSelectorFromString("shared"))?.takeUnretainedValue() as? NSObject else {
            Self.logRpc("setAppsFlyerAttributionBridgeReady: -[AppsFlyerAttribution shared] failed")
            return
        }
        shared.setValue(true, forKey: "isBridgeReady")
    }

    /// Flush attribution bridge state; optionally re-run session `start` via RPC.
    @objc private func handleApplicationDidBecomeActive() {
        NotificationCenter.default.post(name: Self.appsFlyerBridgeSetNotification, object: self)
        if shouldStartSdk {
            NotificationCenter.default.post(name: Self.rpcStartFireAndForgetNotification, object: nil)
        }
    }

    @objc private func handleRpcStartFireAndForgetNotification() {
        Task { @MainActor in
            do {
                let json = try Self.buildJsonRpcEnvelope(method: "start", params: ["awaitResponse": false])
                Self.logRpc("rpcStartFireAndForget: \(Self.truncateForLog(json))")
                _ = await rpcClient.execute(jsonRequest: json)
            } catch {
                Self.logRpc("rpcStartFireAndForget: build envelope failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Bridge events → JS

    private func handleRpcBridgeEvent(_ json: String) {
        Self.logRpc("bridge event raw: \(Self.truncateForLog(json))")

        guard let data = json.data(using: .utf8),
        var payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            Self.logRpc("bridge event: failed to parse JSON as dictionary")
            return
        }

        let eventName = payload["event"] as? String ?? ""
        let mappedType = Self.mapBridgeEventNameToJsType(eventName)
        payload["type"] = mappedType
        payload["status"] = Self.afSuccess

        Self.logRpc("bridge event: event=\(eventName) → type=\(mappedType)")

        guard let outData = try? JSONSerialization.data(withJSONObject: payload, options: []),
        let jsonStr = String(data: outData, encoding: .utf8)
        else {
            Self.logRpc("bridge event: failed to re-encode payload for JS")
            return
        }

        let jsType = payload["type"] as? String ?? ""
        DispatchQueue.main.async { [weak self] in
            self?.deliverRpcEvent(jsonStr, jsType: jsType)
        }
    }

    /// Maps AFRPC `event` field to Cordova `type` (same rules as Android `RpcEventNotifier`).
    private static func mapBridgeEventNameToJsType(_ event: String) -> String {
        switch event {
        case "onConversionDataSuccess":
            return afOnInstallConversionDataLoaded
        case "onConversionDataFail":
            return afOnInstallConversionFailure
        case "onDeepLinkReceived":
            return afOnDeepLinking
        default:
            return event
        }
    }

    /// Delivers JSON to the correct listener callback
    private func deliverRpcEvent(_ jsonStr: String, jsType: String) {
        Self.logRpc("deliver: jsType=\(jsType) payload=\(Self.truncateForLog(jsonStr))")

        let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: jsonStr)
        result.keepCallback = true

        switch jsType {
        case Self.afOnInstallConversionDataLoaded,
        Self.afOnInstallConversionFailure,
        "onAppOpenAttribution",
        "onAppOpenAttributionFailure":
            if let cb = conversionListenerCallbackId {
                Self.logRpc("deliver: sending to conversion listener callbackId=\(cb)")
                commandDelegate.send(result, callbackId: cb)
            } else {
                Self.logRpc("deliver: no conversionListenerCallbackId set — event dropped (register registerConversionListener first)")
            }
        case Self.afOnDeepLinking:
            if let cb = deepLinkListenerCallbackId {
                Self.logRpc("deliver: sending to deep link listener callbackId=\(cb)")
                commandDelegate.send(result, callbackId: cb)
            } else {
                Self.logRpc("deliver: no deepLinkListenerCallbackId — event dropped")
            }
        case Self.afOnSessionReady:
            if let cb = sessionReadyListenerCallbackId {
                Self.logRpc("deliver: sending to session ready listener callbackId=\(cb)")
                commandDelegate.send(result, callbackId: cb)
            } else {
                Self.logRpc("deliver: no sessionReadyListenerCallbackId — event dropped")
            }
        default:
            Self.logRpc("deliver: unhandled jsType=\(jsType) — event dropped")
        }
    }

    // MARK: - Listener registration

    private func applyCallbackRegistrationForMethod(_ method: String, command: CDVInvokedUrlCommand) {
        let cb = command.callbackId
        switch method {
        case "registerSessionReadyListener":
            sessionReadyListenerCallbackId = cb
            logRpc("registration: sessionReady listener → callbackId=\(cb ?? "nil")")
        case "unregisterSessionReadyListener":
            sessionReadyListenerCallbackId = nil
            logRpc("registration: sessionReady listener cleared")
        case "subscribeForDeepLink", "registerDeeplinkListener":
            deepLinkListenerCallbackId = cb
            logRpc("registration: deep link listener → callbackId=\(cb ?? "nil")")
        case "unsubscribeForDeepLink":
            deepLinkListenerCallbackId = nil
            logRpc("registration: deep link listener cleared")
        case "registerConversionListener":
            conversionListenerCallbackId = cb
            logRpc("registration: conversion listener → callbackId=\(cb ?? "nil")")
        case "unregisterConversionListener":
            conversionListenerCallbackId = nil
            logRpc("registration: conversion listener cleared")
        default:
            break
        }
    }

    private func sendRegistrationAck(command: CDVInvokedUrlCommand, send: @escaping (CDVPluginResult?) -> Void) {
        let result = CDVPluginResult(status: CDVCommandStatus.noResult)
        result.keepCallback = true
        send(result)
    }

    /// Maps AFRPC JSON to Cordova (aligned with iOS `result.success` convention).
    private static func sendRpcEnvelopeToCordova(
    _ responseJson: String,
    originalMethod: String,
    command: CDVInvokedUrlCommand,
    send: @escaping (CDVPluginResult?) -> Void
    ) {
        guard let data = responseJson.data(using: .utf8),
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            logRpc("sendRpcEnvelope: invalid JSON response")
            send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "INTERNAL_ERRORInvalid RPC response"))
            return
        }

        if let transportError = obj["error"] as? [String: Any], !(transportError.isEmpty) {
            let code = transportError["code"] as? Int ?? 0
            let message = transportError["message"] as? String ?? "RPC error"
            logRpc("sendRpcEnvelope: transport error code=\(code) message=\(message) method=\(originalMethod)")
            send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "\(code)\(message)"))
            return
        }

        let resultValue = obj["result"]

        if let dict = resultValue as? [String: Any] {
            if let success = dict["success"] as? Bool, success == false {
                let code = dict["errorCode"] as? Int ?? 0
                let message = dict["message"] as? String ?? "RPC error"
                logRpc("sendRpcEnvelope: handler failure success=false code=\(code) message=\(message) method=\(originalMethod)")
                send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "\(code)\(message)"))
                return
            }
        }

        let registrationOnly = isCallbackRegistrationOnlyMethod(originalMethod)

        if registrationOnly {
            logRpc("sendRpcEnvelope: registration-only method=\(originalMethod) → NO_RESULT + keepCallback (listener stored for bridge events)")
            let ack = CDVPluginResult(status: CDVCommandStatus.noResult)
            ack.keepCallback = true
            send(ack)
            return
        }

        let payloadString: String
        if resultValue == nil || resultValue is NSNull {
            payloadString = ""
        } else if let r = resultValue,
        let jsonData = try? JSONSerialization.data(withJSONObject: r, options: [.sortedKeys]),
        let s = String(data: jsonData, encoding: .utf8) {
            payloadString = s
        } else if let r = resultValue {
            payloadString = String(describing: r)
        } else {
            payloadString = ""
        }

        logRpc("sendRpcEnvelope: OK method=\(originalMethod) payload=\(truncateForLog(payloadString))")
        send(CDVPluginResult(status: CDVCommandStatus.ok, messageAs: payloadString))
    }

    private func sendCordovaError(_ command: CDVInvokedUrlCommand, message: String) {
        let result = CDVPluginResult(status: CDVCommandStatus.error, messageAs: message)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
}
