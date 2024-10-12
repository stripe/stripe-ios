//
//  UIViewController+StripeConnect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/11/24.
//

import UIKit

extension UIViewController {
    func addChildAndPinView(_ child: UIViewController) {
        child.willMove(toParent: self)
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.bounds
        child.didMove(toParent: self)
    }
}
