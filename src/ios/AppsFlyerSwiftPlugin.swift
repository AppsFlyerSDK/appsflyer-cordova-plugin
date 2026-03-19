//
//  AppsFlyerSwiftPlugin.swift
//  AppsFlyer Cordova Plugin
//
//  Swift plugin - accessible from Cordova alongside AppsFlyerPlugin.
//  Will eventually contain all methods migrated from AppsFlyerPlugin.m
//
//  TODO (when migration complete): Rename to AppsFlyerPlugin, clean up configs (remove duplicate feature).
//
//  NOTE: Use current (non-deprecated) CDVPluginResult creation and commandDelegate.send* APIs.
//  See logEvent implementation for the correct pattern.
//

import Foundation
import AppsFlyerLib

/// Swift plugin implementation. Exposed to Cordova as AppsFlyerSwiftPlugin.
@objc(AppsFlyerSwiftPlugin)
public class AppsFlyerSwiftPlugin: CDVPlugin {

    // MARK: - TCF Data Collection

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

    // MARK: - Log Event

    @objc public func logEvent(_ command: CDVInvokedUrlCommand) {
        guard command.arguments.count >= 2 else {
            return
        }
        let eventName = command.arguments[0] as? String
        let eventValues = command.arguments[1] as? [String: Any]

        var errorMessage: String?
        if eventName == nil || (eventName?.isEmpty ?? true) {
            errorMessage = "Event name is illegal"
        } else if eventValues == nil {
            errorMessage = "Event Values are illegal"
        }

        if let error = errorMessage {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: error)
            commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            return
        }

        let name = eventName!
        let values = eventValues as NSDictionary?

        AppsFlyerLib.shared().logEvent(name: name, values: values, completionHandler: { [weak self] _, error in
            guard let self = self else { return }
            if let err = error {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: err.localizedDescription)
                self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            } else {
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: name)
                self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId)
            }
        })
    }
}
