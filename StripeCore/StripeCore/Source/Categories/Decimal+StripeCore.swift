//
//  Decimal+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 4/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public extension Decimal {
    var floatValue: Float {
        return (self as NSDecimalNumber).floatValue
    }
}
