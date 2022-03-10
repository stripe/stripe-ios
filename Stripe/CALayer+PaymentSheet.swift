//
//  CALayer+PaymentSheet.swift
//  StripeiOS
//
//  Created by Nick Porter on 2/28/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

extension CALayer {
    
    func applyShadowAppearance(shape: PaymentSheet.Appearance.Shape) {
        shadowColor = shape.componentShadow.color.cgColor
        shadowOpacity = shape.componentShadow.alpha
        shadowOffset = shape.componentShadow.offset
        shadowRadius = CGFloat(shape.componentShadow.radius)
        
        if shape.componentShadow.spread == 0 {
            shadowPath = nil
        } else {
            let dx = CGFloat(-shape.componentShadow.spread)
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(
                roundedRect: rect,
                cornerRadius: shape.cornerRadius
            ).cgPath
        }
    }
    
}
