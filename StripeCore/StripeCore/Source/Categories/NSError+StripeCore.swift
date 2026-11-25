//
//  NSError+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 7/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSError {

    /// A generic localized message for errors that have no more specific customer-facing message.
    /// Exposed to React Native so failures raised by its bridge show the same message as native errors.
    @_spi(InternalOnlyAPI) @_spi(ReactNativeSDK) public class func stp_unexpectedErrorMessage() -> String {
        return STPLocalizedString(
            "There was an unexpected error -- try again in a few seconds",
            "Unexpected error, such as a 500 from Stripe or a JSON parse error"
        )
    }
}
