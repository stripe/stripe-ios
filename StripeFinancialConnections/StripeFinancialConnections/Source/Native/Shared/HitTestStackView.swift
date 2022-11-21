//
//  HitTestStackView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// A `UIStackView` that considers the touch area
// of subviews first because the subviews might have
// increased tap area.
class HitTestStackView: UIStackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) {
                return true
            }
        }
        return super.point(inside: point, with: event)
    }
}
