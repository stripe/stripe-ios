//
//  UIFont+Stripe.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 11/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public extension UIFont {
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight, maximumPointSize: CGFloat? = nil) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        
        if let maximumPointSize = maximumPointSize {
            return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
        }
        return metrics.scaledFont(for: font)
    }
}
