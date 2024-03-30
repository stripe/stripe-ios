//
//  UIViewController+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/15/22.
//

import Foundation
import UIKit

extension UIViewController {

    static func topMostViewController() -> UIViewController? {
        guard let window = UIApplication.shared.customKeyWindow else {
            return nil
        }
        var topMostViewController = window.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        return topMostViewController
    }
}

extension UIApplication {

    fileprivate var customKeyWindow: UIWindow? {
        let foregroundActiveWindow =
            connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ ($0 as? UIWindowScene) })?.windows
            .first(where: \.isKeyWindow)

        if let foregroundActiveWindow = foregroundActiveWindow {
            return foregroundActiveWindow
        }

        // There are scenarios (ex. presenting from a notification) when
        // no scenes are `foregroundActive` so here we ignore the parameter
        return
            connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap({ ($0 as? UIWindowScene) })?.windows
            .first(where: \.isKeyWindow)
    }
}
