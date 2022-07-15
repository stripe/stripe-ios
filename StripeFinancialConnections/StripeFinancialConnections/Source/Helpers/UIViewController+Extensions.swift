//
//  UIViewController+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/15/22.
//

import Foundation
import UIKit

extension UIViewController {

    @available(iOSApplicationExtension, unavailable)
    static func topMostViewController() -> UIViewController? {
        guard let window = UIApplication.shared.keyWindow else {
            return nil
        }
        var topMostViewController = window.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        return topMostViewController
    }
}
