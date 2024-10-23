//
//  CALayer+StripeUICore.swift
//  StripeUICore
//
//  Created by Nick Porter on 3/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
import Foundation
import QuartzCore
import UIKit

@_spi(STP) public extension CALayer {

    func applyShadow(shadow: ElementsAppearance.Shadow?) {
        guard let shadow = shadow else {
            shadowOpacity = 0
            return
        }

        shadowColor = shadow.color.cgColor
        shadowOpacity = Float(shadow.opacity)
        shadowOffset = shadow.offset
        shadowRadius = CGFloat(shadow.radius)
    }

}
