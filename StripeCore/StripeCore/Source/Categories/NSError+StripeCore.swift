//
//  NSError+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 7/7/21.
//

import Foundation

@_spi(STP) public extension NSError {
    class func stp_unexpectedErrorMessage() -> String {
        return STPLocalizedString(
            "There was an unexpected error -- try again in a few seconds",
            "Unexpected error, such as a 500 from Stripe or a JSON parse error")
    }
}
