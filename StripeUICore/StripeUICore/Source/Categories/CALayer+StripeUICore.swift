//
//  CALayer+StripeUICore.swift
//  StripeUICore
//
//  Created by Nick Porter on 3/16/22.
//
import Foundation
import QuartzCore
import UIKit

@_spi(STP) public extension CALayer {

    func applyShadow(shape: ElementsUITheme.Shape) {
        shadowColor = shape.shadow.color.cgColor
        shadowOpacity = shape.shadow.alpha
        shadowOffset = shape.shadow.offset
        shadowRadius = CGFloat(shape.cornerRadius)
    }

}
