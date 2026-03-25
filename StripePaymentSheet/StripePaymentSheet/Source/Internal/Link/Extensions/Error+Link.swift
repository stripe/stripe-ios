//
//  Error+Link.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 8/25/25.
//

import Foundation
@_spi(STP) import StripeCore

private let authErrorCodes: Set<String?> = [
    "consumer_session_credentials_invalid",
    "consumer_session_expired",
]

extension Error {
    var isLinkAuthError: Bool {
        if let stripeError = self as? StripeError,
           case let .apiError(stripeAPIError) = stripeError,
           authErrorCodes.contains(stripeAPIError.code) {
            return true
        }
        return false
    }
}
