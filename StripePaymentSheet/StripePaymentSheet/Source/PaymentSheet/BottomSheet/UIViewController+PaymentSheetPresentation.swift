//
//  UIViewController+PaymentSheetPresentation.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/7/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Presents a PaymentSheet container using UIKit's native sheet presentation.
    func presentAsSheet(
        _ viewControllerToPresent: PaymentSheetContainerViewController,
        completion: (() -> Void)? = nil
    ) {
        viewControllerToPresent.modalPresentationStyle = .pageSheet
        viewControllerToPresent.modalPresentationCapturesStatusBarAppearance = true
        viewControllerToPresent.prepareForPresentation(in: view.bounds.width)

        if let sheetPresentationController = viewControllerToPresent.sheetPresentationController {
            sheetPresentationController.detents = [viewControllerToPresent.contentSizedDetent, .large()]
            sheetPresentationController.selectedDetentIdentifier = PaymentSheetContainerViewController.contentDetentIdentifier
            sheetPresentationController.prefersGrabberVisible = true
        }
        viewControllerToPresent.presentationController?.delegate = viewControllerToPresent

        // Prevent the presenting view from regaining focus when editing ends in the bottom sheet.
        viewIfLoaded?.endEditing(true)
        present(viewControllerToPresent, animated: true, completion: completion)
    }

    var bottomSheetController: PaymentSheetContainerViewController? {
        var current: UIViewController? = self
        while current != nil {
            if let bottomSheetController = current as? PaymentSheetContainerViewController {
                return bottomSheetController
            }

            current = current?.parent
        }

        return nil
    }
}
