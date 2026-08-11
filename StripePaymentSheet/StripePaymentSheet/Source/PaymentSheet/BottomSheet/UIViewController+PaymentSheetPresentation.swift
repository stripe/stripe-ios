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

        if let sheetPresentationController = viewControllerToPresent.sheetPresentationController {
            if #available(iOS 17.0, *) {
                viewControllerToPresent.prepareForPresentation(in: view.bounds.width)
                sheetPresentationController.detents = [viewControllerToPresent.contentSizedDetent]
                sheetPresentationController.selectedDetentIdentifier = PaymentSheetContainerViewController.contentDetentIdentifier
            } else {
                sheetPresentationController.detents = [.large()]
                sheetPresentationController.selectedDetentIdentifier = .large
            }
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
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
