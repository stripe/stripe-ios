//
//  FixedHeightTransitionDelegate.swift
//  StripePaymentSheet
//

import UIKit

class FixedHeightTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let heightRatio: CGFloat
    init(heightRatio: CGFloat) {
        self.heightRatio = heightRatio
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FixedHeightPresentationController(heightRatio: heightRatio,
                                                 presentedViewController: presented,
                                                 presenting: presenting)
    }
}
