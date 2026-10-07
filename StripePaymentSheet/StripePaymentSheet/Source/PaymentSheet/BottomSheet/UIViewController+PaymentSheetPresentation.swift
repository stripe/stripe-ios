//
//  UIViewController+PaymentSheetPresentation.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/7/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIViewController {

    /// Presents the selected PaymentSheet container using its own presentation lifecycle.
    func presentAsSheet(
        _ viewControllerToPresent: any PaymentSheetContainer,
        completion: (() -> Void)? = nil
    ) {
        viewControllerToPresent.present(from: self, completion: completion)
    }

    var bottomSheetController: (any PaymentSheetContainer)? {
        var current: UIViewController? = self
        while let viewController = current {
            if let container = viewController as? any PaymentSheetContainer {
                return container
            }

            current = viewController.parent
        }

        return nil
    }
}
