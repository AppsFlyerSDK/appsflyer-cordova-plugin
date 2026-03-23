//
//  AppsFlyerSwiftPlugin.swift
//  AppsFlyer Cordova Plugin
//
//  Swift plugin — RPC entry point mirrors Android `AppsFlyerPlugin.executeRpc`:
//  JS passes `{ method, params }`, native builds JSON-RPC and runs `AFRPCClient.execute`.
//

import Foundation
import AppsFlyerLib
import AppsFlyerRPC

/// Swift plugin implementation. Exposed to Cordova as AppsFlyerSwiftPlugin.
@objc(AppsFlyerSwiftPlugin)
public class AppsFlyerSwiftPlugin: CDVPlugin {

    // MARK: - RPC client

    private lazy var rpcClient: AFRPCClient = {
        AFRPCClient { [weak self] json in
            self?.handleRpcBridgeEvent(json)
        }
    }()

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

    // MARK: - Bridge events → JS

    private func handleRpcBridgeEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
        var payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return
        }

        let eventName = payload["event"] as? String ?? ""
        payload["type"] = Self.mapBridgeEventNameToJsType(eventName)
        payload["status"] = Self.afSuccess

        guard let outData = try? JSONSerialization.data(withJSONObject: payload, options: []),
        let jsonStr = String(data: outData, encoding: .utf8)
        else {
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
        let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: jsonStr)
        result.keepCallback = true

        switch jsType {
        case Self.afOnInstallConversionDataLoaded,
        Self.afOnInstallConversionFailure,
        "onAppOpenAttribution",
        "onAppOpenAttributionFailure":
            if let cb = conversionListenerCallbackId {
                commandDelegate.send(result, callbackId: cb)
            }
        case Self.afOnDeepLinking:
            if let cb = deepLinkListenerCallbackId {
                commandDelegate.send(result, callbackId: cb)
            }
        case Self.afOnSessionReady:
            if let cb = sessionReadyListenerCallbackId {
                commandDelegate.send(result, callbackId: cb)
            }
        default:
            break
        }
    }

    // MARK: - Listener registration

    private func applyCallbackRegistrationForMethod(_ method: String, command: CDVInvokedUrlCommand) {
        switch method {
        case "registerSessionReadyListener":
            sessionReadyListenerCallbackId = command.callbackId
        case "unregisterSessionReadyListener":
            sessionReadyListenerCallbackId = nil
        case "subscribeForDeepLink", "registerDeeplinkListener":
            deepLinkListenerCallbackId = command.callbackId
        case "unsubscribeForDeepLink":
            deepLinkListenerCallbackId = nil
        case "registerConversionListener":
            conversionListenerCallbackId = command.callbackId
        case "unregisterConversionListener":
            conversionListenerCallbackId = nil
        default:
            break
        }
    }

    // MARK: - Cordova method names → iOS AFRPC

    /// Normalizes JS RPC names and params to what `AppsFlyerRPC` expects.
    private func normalizeRpcInvocation(method: String, params: [String: Any]) -> NormalizedRpcInvocation {
        switch method {
        case "subscribeForDeepLink":
            return .invoke(method: "registerDeeplinkListener", params: params)
        case "unsubscribeForDeepLink":
            return .localAckOnly
        case "stop":
            let stopped = params["shouldStop"] as? Bool ?? false
            return .invoke(method: "setStopped", params: ["stopped": stopped])
        case "anonymizeUser":
            let flag = params["shouldAnonymize"] as? Bool ?? false
            return .invoke(method: "setAnonymizeUser", params: ["anonymize": flag])
        case "setUserEmailsWithCryptType":
            var p = params
            if let ct = p["cryptType"] as? String {
                let lower = ct.lowercased()
                if lower == "sha256" {
                    p["cryptType"] = "sha256"
                } else if lower == "none" || lower.isEmpty {
                    p["cryptType"] = "none"
                }
            }
            return .invoke(method: "setUserEmails", params: p)
        case "appendParametersToDeepLinkingURL":
            var p: [String: Any] = [:]
            if let c = params["contains"] as? String {
                p["containsString"] = c
            }
            if let raw = params["parameters"] as? [String: Any] {
                var stringMap: [String: String] = [:]
                for (k, v) in raw {
                    stringMap[k] = "\(v)"
                }
                p["params"] = stringMap
            }
            return .invoke(method: "appendParametersToDeeplinkURL", params: p)
        case "performDeepLinking":
            if let url = params["url"] as? String {
                return .invoke(method: "performOnAppAttributionWithURL", params: ["url": url])
            }
            return .invoke(method: "performOnAppAttributionWithURL", params: params)
        default:
            return .invoke(method: method, params: params)
        }
    }

    private enum NormalizedRpcInvocation {
        case invoke(method: String, params: [String: Any])
        /// iOS RPC has no deeplink unsubscribe — only clear the Cordova callback (already cleared in applyCallbackRegistration).
        case localAckOnly
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
            sendCordovaError(command, message: "PARSE_ERRORMissing options object")
            return
        }

        let rawMethod = options["method"] as? String
        if rawMethod == nil || rawMethod?.isEmpty == true {
            sendCordovaError(command, message: "INVALID_PARAMETERSMissing method")
            return
        }

        let method = rawMethod!
        applyCallbackRegistrationForMethod(method, command: command)

        let paramsObject = normalizeRpcParams(options["params"])
        let normalized = normalizeRpcInvocation(method: method, params: paramsObject)

        switch normalized {
        case .localAckOnly:
            sendRegistrationAck(command: command) { [weak self] result in
                guard let self = self, let result = result else { return }
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
            return
        case let .invoke(rpcMethod, rpcParams):
            let requestJson: String
            do {
                requestJson = try Self.buildJsonRpcEnvelope(method: rpcMethod, params: rpcParams)
            } catch {
                sendCordovaError(command, message: "PARSE_ERROR\(error.localizedDescription)")
                return
            }

            let responseJson = await rpcClient.execute(jsonRequest: requestJson)
            Self.sendRpcEnvelopeToCordova(
                responseJson,
                originalMethod: method,
                command: command
            ) { [weak self] result in
                guard let self = self, let result = result else { return }
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

    private static func buildJsonRpcEnvelope(method: String, params: [String: Any]) throws -> String {
        let envelope: [String: Any] = [
            "method": method,
            "params": params
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])
        guard let str = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AppsFlyerSwiftPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "UTF-8 encode failed"])
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
            send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "INTERNAL_ERRORInvalid RPC response"))
            return
        }

        if let transportError = obj["error"] as? [String: Any], !(transportError.isEmpty) {
            let code = transportError["code"] as? Int ?? 0
            let message = transportError["message"] as? String ?? "RPC error"
            send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "\(code)\(message)"))
            return
        }

        let resultValue = obj["result"]

        if let dict = resultValue as? [String: Any] {
            if let success = dict["success"] as? Bool, success == false {
                let code = dict["errorCode"] as? Int ?? 0
                let message = dict["message"] as? String ?? "RPC error"
                send(CDVPluginResult(status: CDVCommandStatus.error, messageAs: "\(code)\(message)"))
                return
            }
        }

        let registrationOnly = isCallbackRegistrationOnlyMethod(originalMethod)

        if registrationOnly {
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

        send(CDVPluginResult(status: CDVCommandStatus.ok, messageAs: payloadString))
    }

    private func sendCordovaError(_ command: CDVInvokedUrlCommand, message: String) {
        let result = CDVPluginResult(status: CDVCommandStatus.error, messageAs: message)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    // MARK: - TCF Data Collection (called directly from Cordova)

    @objc public func enableTCFDataCollection(_ command: CDVInvokedUrlCommand) {
        guard command.arguments.count > 0 else {
            return
        }
        var enable = false
        if let enableValue = command.arguments.first as? NSNumber {
            enable = enableValue.boolValue
        }
        AppsFlyerLib.shared().enableTCFDataCollection(enable)
    }
}
