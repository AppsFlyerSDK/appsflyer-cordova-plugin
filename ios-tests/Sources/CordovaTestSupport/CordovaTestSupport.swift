//
//  CordovaTestSupport.swift
//
//  Minimal stand-in for the handful of CordovaLib (`Cordova` module) symbols
//  AppsFlyerPlugin.swift touches — CDVPlugin, CDVInvokedUrlCommand, CDVPluginResult,
//  CDVCommandDelegate, CDVCommandStatus. CordovaLib itself isn't distributed as an SPM/CocoaPods
//  package consumable outside a `cordova platform add ios`-generated project, so this test target
//  provides a source-accurate shim of just that surface instead of vendoring the real framework.
//  Real integration coverage against actual CordovaLib still requires building inside a generated
//  Cordova iOS project (see the test report for what this harness does and doesn't cover).

import Foundation

public enum CDVCommandStatus: Int {
    case ok = 0
    case error = 1
}

public final class CDVPluginResult: NSObject {
    public let status: CDVCommandStatus
    public let message: Any?
    private var keepCallback = false

    public init?(status: CDVCommandStatus, messageAs message: String) {
        self.status = status
        self.message = message
    }

    // Real CDVPluginResult's Obj-C selector is still setKeepCallbackAsBool:, but Swift's Clang
    // importer auto-renames the Bool-suffixed setter to setKeepCallbackAs(_:) on import -- match
    // that renamed spelling here too, or this double silently drifts from what production code
    // actually calls (as it did until the real e2e build caught it).
    public func setKeepCallbackAs(_ bKeepCallback: Bool) {
        keepCallback = bKeepCallback
    }

    public var keepsCallback: Bool { keepCallback }
}

public final class CDVInvokedUrlCommand: NSObject {
    public let arguments: [Any]
    public let callbackId: String

    public init(arguments: [Any], callbackId: String) {
        self.arguments = arguments
        self.callbackId = callbackId
    }
}

public protocol CDVCommandDelegate: AnyObject {
    func send(_ pluginResult: CDVPluginResult?, callbackId: String?)
}

open class CDVPlugin: NSObject {
    public var commandDelegate: CDVCommandDelegate!

    public override init() {
        super.init()
    }
}
