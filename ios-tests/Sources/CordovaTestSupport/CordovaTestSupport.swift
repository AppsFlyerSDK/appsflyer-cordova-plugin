// Minimal shim of the CordovaLib symbols AppsFlyerPlugin.swift touches (CDVPlugin, CDVInvokedUrlCommand, CDVPluginResult, CDVCommandDelegate, CDVCommandStatus) — CordovaLib isn't distributable as an SPM/CocoaPods package outside a generated Cordova iOS project, so real integration coverage still requires one (see the test report).

import Foundation

public enum CDVCommandStatus: Int {
    case ok = 0
    case error = 1
}

public final class CDVPluginResult: NSObject {
    // Test seam for the real (Obj-C, Optional-returning) initializer's nil path, driving AppsFlyerPlugin's guard-let-or-bail branch; single-shot, reset on next init so it can't leak into another test.
    public static var forceNilOnNextInit = false

    public let status: CDVCommandStatus
    public let message: Any?
    private var keepCallback = false

    public init?(status: CDVCommandStatus, messageAs message: String) {
        if Self.forceNilOnNextInit {
            Self.forceNilOnNextInit = false
            return nil
        }
        self.status = status
        self.message = message
    }

    // Swift's Clang importer renames the real setKeepCallbackAsBool: to setKeepCallbackAs(_:); match that here or this double silently drifts from what production code calls (as it did until e2e caught it).
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

    // Cordova calls onReset() on WebView reload; AppsFlyerPlugin overrides it, so this fake base needs the method to exist.
    open func onReset() {}
}
