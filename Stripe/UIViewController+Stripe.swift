//
//  UIViewController+Stripe.swift
//  StripeiOS
//
//  Created by Ramon Torres on 5/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIViewController {

    /// Walks the presented view controller hierarchy and return the top most presented controller.
    /// - Returns: Returns the top most presented view controller, or `nil` if this view controller is not presenting another controller.
    func findTopMostPresentedViewController() -> UIViewController? {
        var topMostController = self.presentedViewController

        while let presented = topMostController?.presentedViewController {
            topMostController = presented
        }

        return topMostController
    }

}
