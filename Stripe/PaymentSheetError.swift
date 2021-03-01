//
//  PaymentSheetError.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Errors specific to PaymentSheet itself
///
/// Most errors do not originate from PaymentSheet itself; instead, they come from the Stripe API
/// or other SDK components like STPPaymentHandler, PassKit (Apple Pay), etc.
public enum PaymentSheetError: Error {
    /// An unknown error.
    case unknown(debugDescription: String)

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension PaymentSheetError {
    /// Returns true if the error is un-fixable; e.g. no amount of retrying or customer action will result in something different
    static func isUnrecoverable(error: Error) -> Bool {
        // TODO: Expired ephemeral key
        return false
    }
}
