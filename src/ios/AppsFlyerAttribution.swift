import Foundation
import UIKit
import AppsFlyerLib

@objc(AppsFlyerAttribution)
public final class AppsFlyerAttribution: NSObject {

    @objc public static let shared = AppsFlyerAttribution()

    internal var deliverHandleOpen: (URL, [UIApplication.OpenURLOptionsKey: Any]) -> Void = { url, options in
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }
    internal var deliverLegacyHandleOpen: (URL, String?, Any?) -> Void = { url, sourceApplication, annotation in
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
    }
    internal var deliverContinueUserActivity: (NSUserActivity, (([Any]?) -> Void)?) -> Void = { activity, handler in
        _ = AppsFlyerLib.shared().continue(activity, restorationHandler: handler)
    }
    internal var deliverHandleLaunchOptions: (([AnyHashable: Any]?) -> Void) = { AppsFlyerLib.shared().handleLaunchOptions($0) }

    internal func resetDeliveryClosuresToDefaultsForTest() {
        deliverHandleOpen = { url, options in AppsFlyerLib.shared().handleOpen(url, options: options) }
        deliverLegacyHandleOpen = { url, sourceApplication, annotation in
            AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        }
        deliverContinueUserActivity = { activity, handler in
            _ = AppsFlyerLib.shared().continue(activity, restorationHandler: handler)
        }
        deliverHandleLaunchOptions = { AppsFlyerLib.shared().handleLaunchOptions($0) }
        lock.withCriticalScope { pendingActions.removeAll() }
    }

    private let lock = NSLock()
    private var _bridgeReady = false
    @objc public var bridgeReady: Bool {
        get { lock.withCriticalScope { _bridgeReady } }
        set {
            let actions: [() -> Void] = lock.withCriticalScope {
                _bridgeReady = newValue
                guard newValue else { return [] }
                let drained = pendingActions
                pendingActions.removeAll()
                return drained
            }
            for action in actions {
                action()
            }
        }
    }

    private var pendingActions: [() -> Void] = []

    private override init() {}

    @objc public func continueUserActivity(
        _ userActivity: NSUserActivity,
        restorationHandler: (([Any]?) -> Void)? = nil
    ) {
        // When buffering, drop UIKit's restorationHandler so pendingActions does not retain it across async delays.
        let shouldBuffer: Bool = lock.withCriticalScope {
            guard !_bridgeReady else { return false }
            pendingActions.append { [weak self] in
                self?.deliverContinueUserActivity(userActivity, nil)
            }
            return true
        }
        guard !shouldBuffer else { return }
        deliverContinueUserActivity(userActivity, restorationHandler)
    }

    @objc public func handleOpen(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        dispatchOrBuffer { [weak self] in
            self?.deliverHandleOpen(url, options)
        }
    }

    @objc public func handleOpen(_ url: URL, sourceApplication: String?, annotation: Any?) {
        dispatchOrBuffer { [weak self] in
            self?.deliverLegacyHandleOpen(url, sourceApplication, annotation)
        }
    }

    @objc public func handleLaunchOptions(_ launchOptions: [AnyHashable: Any]?) {
        deliverHandleLaunchOptions(launchOptions)
    }

    private func dispatchOrBuffer(_ action: @escaping () -> Void) {
        let shouldBuffer: Bool = lock.withCriticalScope {
            guard !_bridgeReady else { return false }
            pendingActions.append(action)
            return true
        }
        guard !shouldBuffer else { return }
        action()
    }

}

extension NSLock {
    func withCriticalScope<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
