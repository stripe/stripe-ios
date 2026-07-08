//
//  NSAttributedString+Stripe.swift
//  StripePaymentsUI
//
//  Created by Ramon Torres on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

extension NSAttributedString {

    /// A range covering from the start to the end of the attributed string.
    @_spi(STP) public var extent: NSRange {
        return NSRange(location: 0, length: self.length)
    }

}
