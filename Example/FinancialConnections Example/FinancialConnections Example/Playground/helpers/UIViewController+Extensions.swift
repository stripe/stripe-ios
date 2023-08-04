//
//  UIViewController+Extensions.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

<<<<<<< Updated upstream
    static func topMostViewController() -> UIViewController? {
=======
        static func topMostViewController() -> UIViewController? {
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
    fileprivate var customKeyWindow: UIWindow? {
=======
        fileprivate var customKeyWindow: UIWindow? {
>>>>>>> Stashed changes
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
