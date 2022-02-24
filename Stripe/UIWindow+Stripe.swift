//
//  UIWindow+Stripe.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIWindow {

    func findTopMostPresentedViewController() -> UIViewController? {
        var topMostController = self.rootViewController

        // Find the top-most presented UIViewController
        while let presented = topMostController?.presentedViewController {
            topMostController = presented
        }

        return topMostController
    }

}
