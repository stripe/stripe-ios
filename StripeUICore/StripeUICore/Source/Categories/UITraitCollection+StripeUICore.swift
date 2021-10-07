//
//  UITraitCollection+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 10/3/21.
//

import UIKit

@_spi(STP) public extension UITraitCollection {

    var isDarkMode: Bool {
        if #available(iOS 12.0, *) {
            return userInterfaceStyle == .dark
        } else {
            return false
        }
    }

}
