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

    func applyShadow(theme: ElementsUITheme) {
        guard let shadow = theme.shadow else { return }
        
        shadowColor = shadow.color.cgColor
        shadowOpacity = Float(shadow.opacity)
        shadowOffset = shadow.offset
        shadowRadius = CGFloat(shadow.radius)
    }

}
