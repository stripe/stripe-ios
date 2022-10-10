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
        completion: (() -> ())? = nil
    ) {
        if UIDevice.current.userInterfaceIdiom == .pad {
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
