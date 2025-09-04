//
//  Error+Link.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 8/25/25.
//

import Foundation
@_spi(STP) import StripeCore

extension Error {
    var isLinkAuthError: Bool {
        if let stripeError = self as? StripeError,
           case let .apiError(stripeAPIError) = stripeError,
           stripeAPIError.code == "consumer_session_credentials_invalid" {
            return true
        }
        return false
    }
}
