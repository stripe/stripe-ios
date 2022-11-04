//
//  NSError+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 7/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension NSError {
    public class func stp_unexpectedErrorMessage() -> String {
        return STPLocalizedString(
            "There was an unexpected error -- try again in a few seconds",
            "Unexpected error, such as a 500 from Stripe or a JSON parse error"
        )
    }
}
