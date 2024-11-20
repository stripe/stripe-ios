//
//  UIViewController+StripeConnect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/11/24.
//

@_spi(STP) import StripeUICore
import UIKit

extension UIViewController {
    /// Helper that adds a child view controller and pins its view to this view controller's view
    func addChildAndPinView(_ child: UIViewController) {
        child.willMove(toParent: self)
        addChild(child)
        view.addAndPinSubview(child.view)
        child.didMove(toParent: self)
    }
}
