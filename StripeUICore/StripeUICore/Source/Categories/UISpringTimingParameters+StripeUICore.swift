//
//  UISpringTimingParameters+StripeUICore.swift
//  StripeUICore
//
//  Created by David Estes on 1/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public extension UISpringTimingParameters {
    convenience init(mass: CGFloat, dampingRatio: CGFloat, frequencyResponse: CGFloat) {
        // h/t https://medium.com/ios-os-x-development/demystifying-uikit-spring-animations-2bb868446773
        let stiffness: CGFloat = pow(2 * .pi / frequencyResponse, 2) * mass
        let damping: CGFloat = 4 * .pi * dampingRatio * mass / frequencyResponse
        self.init(
            mass: mass,
            stiffness: stiffness,
            damping: damping,
            initialVelocity: .zero)
    }
}
