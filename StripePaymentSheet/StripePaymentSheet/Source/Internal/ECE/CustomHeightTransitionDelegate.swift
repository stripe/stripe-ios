//
//  CustomHeightTransitionDelegate.swift
//  StripePaymentSheet
//

import UIKit

class CustomHeightTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let presentationHeight: CustomHeightPresentationController.PresentationHeight
    init(presentationHeight: CustomHeightPresentationController.PresentationHeight) {
        self.presentationHeight = presentationHeight
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomHeightPresentationController(presentationHeight: presentationHeight,
                                                  presentedViewController: presented,
                                                  presenting: presenting)
    }
}
