//
//  UIViewController+BottomSheet.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Convenience method that presents the view controller in a custom 'bottom sheet' style
    func presentAsBottomSheet(
        _ viewControllerToPresent: BottomSheetPresentable,
        appearance: PaymentSheet.Appearance,
        completion: (() -> Void)? = nil
    ) {
        var presentAsFormSheet: Bool {
            #if canImport(CompositorServices)
            return true
            #else
            // Present as form sheet in larger devices (iPad/Mac).
            if #available(iOS 14.0, macCatalyst 14.0, *) {
                return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
            } else {
                return UIDevice.current.userInterfaceIdiom == .pad
            }
            #endif
        }

        if presentAsFormSheet {
            viewControllerToPresent.modalPresentationStyle = .formSheet
            // Don't allow the pull down to dismiss gesture, it's too easy to trigger accidentally while scrolling
            viewControllerToPresent.isModalInPresentation = true
            if let vc = viewControllerToPresent as? BottomSheetViewController {
                viewControllerToPresent.presentationController?.delegate = vc
            }
        } else {
            viewControllerToPresent.modalPresentationStyle = .custom
            viewControllerToPresent.modalPresentationCapturesStatusBarAppearance = true
            BottomSheetTransitioningDelegate.appearance = appearance
            viewControllerToPresent.transitioningDelegate = BottomSheetTransitioningDelegate.default
        }

        present(viewControllerToPresent, animated: true, completion: completion)
    }

    var bottomSheetController: BottomSheetViewController? {
        var current: UIViewController? = self
        while current != nil {
            if let bottomSheetController = current as? BottomSheetViewController {
                return bottomSheetController
            }

            current = current?.parent
        }

        return nil
    }
}
