//
//  AppsFlyerAttribution.swift
//  cordova-plugin-appsflyer-sdk
//
//  AppDelegate-facing facade for all four AppsFlyer lifecycle forwards. `handleOpen`/
//  `continueUserActivity` buffer until `AppsFlyerPlugin` flips `bridgeReady`; `handleLaunchOptions`
//  has no such hazard (no async RPC dependency sits between cold start and this call).
//  `bridgeReady`/pending-buffer access is guarded by `lock`: the RPC bridge's completion (sets
//  `bridgeReady`) and the AppDelegate's swizzled open-URL/continue-activity forwards fire on
//  independent threads.
//
//  Kept as a plain NSObject subclass, not a struct/enum, so it stays a single #import-free target
//  for AppsFlyerX+AppController.m to call into via a locally forward-declared @interface (no
//  generated "<AppModule>-Swift.h" name is knowable at plugin-authoring time in a single-target
//  Cordova app) — see the header comment in AppsFlyerX+AppController.m.

import Foundation
import UIKit
import AppsFlyerLib

@objc(AppsFlyerAttribution)
public final class AppsFlyerAttribution: NSObject {

    @objc public static let shared = AppsFlyerAttribution()

    private let lock = NSLock()
    private var _bridgeReady = false
    @objc public var bridgeReady: Bool {
        get { lock.withCriticalScope { _bridgeReady } }
        set {
            lock.withCriticalScope { _bridgeReady = newValue }
            if newValue { flushPending() }
        }
    }

    private var pendingUserActivity: NSUserActivity?
    private var pendingRestorationHandler: (([Any]?) -> Void)?
    private var pendingUrl: URL?
    private var pendingOptions: [UIApplication.OpenURLOptionsKey: Any] = [:]
    private var pendingLegacyUrl: URL?
    private var pendingSourceApplication: String?
    private var pendingAnnotation: Any?

    private override init() {}

    @objc public func continueUserActivity(
        _ userActivity: NSUserActivity,
        restorationHandler: (([Any]?) -> Void)? = nil
    ) {
        let shouldBuffer: Bool = lock.withCriticalScope {
            guard !_bridgeReady else { return false }
            pendingUserActivity = userActivity
            pendingRestorationHandler = restorationHandler
            return true
        }
        guard !shouldBuffer else { return }
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: restorationHandler)
    }

    @objc public func handleOpen(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        let shouldBuffer: Bool = lock.withCriticalScope {
            guard !_bridgeReady else { return false }
            pendingUrl = url
            pendingOptions = options
            return true
        }
        guard !shouldBuffer else { return }
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }

    @objc public func handleOpen(_ url: URL, sourceApplication: String?, annotation: Any?) {
        let shouldBuffer: Bool = lock.withCriticalScope {
            guard !_bridgeReady else { return false }
            pendingLegacyUrl = url
            pendingSourceApplication = sourceApplication
            pendingAnnotation = annotation
            return true
        }
        guard !shouldBuffer else { return }
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
    }

    @objc public func handleLaunchOptions(_ launchOptions: [AnyHashable: Any]?) {
        AppsFlyerLib.shared().handleLaunchOptions(launchOptions)
    }

    // Drains every buffered form so a URL, a legacy openURL, and a userActivity that all arrived
    // before bridgeReady are each delivered exactly once — don't early-return after the first.
    private func flushPending() {
        let snapshot: (
            url: URL?, options: [UIApplication.OpenURLOptionsKey: Any],
            legacyUrl: URL?, sourceApplication: String?, annotation: Any?,
            userActivity: NSUserActivity?, restorationHandler: (([Any]?) -> Void)?
        ) = lock.withCriticalScope {
            defer {
                pendingUrl = nil
                pendingOptions = [:]
                pendingLegacyUrl = nil
                pendingSourceApplication = nil
                pendingAnnotation = nil
                pendingUserActivity = nil
                pendingRestorationHandler = nil
            }
            return (
                pendingUrl, pendingOptions,
                pendingLegacyUrl, pendingSourceApplication, pendingAnnotation,
                pendingUserActivity, pendingRestorationHandler
            )
        }
        if let url = snapshot.url {
            AppsFlyerLib.shared().handleOpen(url, options: snapshot.options)
        }
        if let legacyUrl = snapshot.legacyUrl {
            AppsFlyerLib.shared().handleOpen(
                legacyUrl,
                sourceApplication: snapshot.sourceApplication,
                withAnnotation: snapshot.annotation
            )
        }
        if let userActivity = snapshot.userActivity {
            AppsFlyerLib.shared().continue(userActivity, restorationHandler: snapshot.restorationHandler)
        }
    }
}

private extension NSLock {
    // iOS 15 target — NSLocking.withLock is iOS 16+, so this is a manual equivalent.
    func withCriticalScope<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
