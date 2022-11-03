//
//  UITraitCollection+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 10/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) extension UITraitCollection {

    public var isDarkMode: Bool {
        return userInterfaceStyle == .dark
    }

}
