//
//  ShadowConfiguration.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/8/22.
//

import Foundation
import UIKit

struct ShadowConfiguration {
    let shadowColor: UIColor
    let shadowOffset: CGSize
    // The view layers shadow opacity is of `Float` type, not `CGFloat`
    let shadowOpacity: Float
    let shadowRadius: CGFloat

    func applyTo(layer: CALayer) {
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = shadowOffset
    }
}
