//
//  UIViewController+BottomSheet.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.

import UIKit

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension UIViewController {
    /// Convenience method that presents the view controller in a custom 'bottom sheet' style
    func presentAsBottomSheet(
        _ viewControllerToPresent: BottomSheetPresentable,
        appearance: PaymentSheet.Appearance,
        completion: (() -> Void)? = nil
    ) {
        // Whether to present the bottomsheet as a form sheet on larger devices, or as bottom sheet
        // on smaller devices.
        let presentAsForm: Bool
        if #available(iOS 14.0, macCatalyst 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad
                || UIDevice.current.userInterfaceIdiom == .mac
            {
                presentAsForm = true
            } else {
                presentAsForm = false
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                presentAsForm = true
            } else {
                presentAsForm = false
            }
        }

        if presentAsForm {
            viewControllerToPresent.modalPresentationStyle = .formSheet
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
}
