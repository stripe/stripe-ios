//
//  Decimal+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 4/14/22.
//

import Foundation

@_spi(STP) public extension Decimal {
    var floatValue: Float {
        return (self as NSDecimalNumber).floatValue
    }
}
