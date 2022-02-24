//
//  UINavigationController+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/10/22.
//

import UIKit
@_spi(STP) import StripeUICore

extension UINavigationController {
    func configureBorderlessNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .clear
        }
    }

    func setNavigationBarBackgroundColor(with backgroundColor: UIColor?) {
        let bgColor = backgroundColor ?? CompatibleColor.systemBackground

        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance.backgroundColor = bgColor
            navigationBar.scrollEdgeAppearance?.backgroundColor = bgColor
        } else {
            navigationBar.backgroundColor = bgColor
        }
    }
}
