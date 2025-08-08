//
//  AppDelegate+BrokenConstraints.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 8/13/25.
//
@_spi(STP) import StripeUICore
import UIKit

extension AppDelegate {
    /// - Note: Only call this **once**!
    func catchBrokenConstraints() {
        let sel = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        let method = class_getInstanceMethod(UIView.self, sel)!
        let impl = method_getImplementation(method)

        let replSel = #selector(UIView.willBreakConstraint(_:_:_:))
        let replMethod = class_getInstanceMethod(UIView.self, replSel)!
        let replImpl = method_getImplementation(replMethod)

        class_replaceMethod(UIView.self, sel, replImpl, method_getTypeEncoding(replImpl))
        class_replaceMethod(UIView.self, replSel, impl, method_getTypeEncoding(impl))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveBrokenConstraintNotification),
            name: Notification.Name(rawValue: "NSISEngineWillBreakConstraint"),
            object: nil
        )
    }

    @objc func didReceiveBrokenConstraintNotification(notification: NSNotification) {
        guard let constraint = notification.object as? NSLayoutConstraint else {
            return
        }
        let ignoredBrokenConstraints = [
            "STP_Internal_LinkMoreInfoView", // https://jira.corp.stripe.com/browse/RUN_MOBILESDK-4562
            "_UIRemoteKeyboardPlaceholderView", // Broken constraints in Apple's keyboard; unclear how it's our fault
            "SystemInputAssistantView", // Same as ^
        ]
        guard !ignoredBrokenConstraints.contains(where: { constraint.debugDescription.contains($0) }) else {
            return
        }
        let alert = UIAlertController(title: "Broken constraint!", message: "\(constraint)\nPlease fix it or file a bug!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.findTopMostPresentedViewController().present(alert, animated: true)
    }
}

extension UIView {
    @objc func willBreakConstraint(_ engine: Any, _ constraint: NSLayoutConstraint, _ conflict: Any) {
        willBreakConstraint(engine, constraint, conflict) // swizzled, will call original impl instead
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "NSISEngineWillBreakConstraint"),
            object: constraint
        )
    }
}
