//
//  Error+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension Error {

    /// If the `localizedDescription` contains a generic error message this returns the raw error message within `userInfo`
    /// Otherwise returns the `localizedDescription`
    var nonGenericDescription: String {
        if let paymentSheetError = self as? PaymentSheetError {
            return paymentSheetError.debugDescription
        }
        if localizedDescription == "The operation couldn’t be completed. (STPPaymentHandlerErrorDomain error 2.)",
           let underlyingError = (self as NSError).userInfo["NSUnderlyingError"] as? NSError {
            // Only show raw API messages for card_error types, which are safe to display to users.
            // Other API error types (e.g. invalid_request_error) contain developer-facing details.
            if let errorType = underlyingError.userInfo[STPError.stripeErrorTypeKey] as? String,
               errorType != "card_error" {
                return NSError.stp_unexpectedErrorMessage()
            }
            return underlyingError.userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
        }
        // If the `localizedDescription` is not generic, return the `localizedDescription`
        if localizedDescription != NSError.stp_unexpectedErrorMessage() { return localizedDescription }

        // If error message is generic, only return raw API message for card_error types.
        // Non-card API errors (e.g. invalid_request_error) contain developer-facing details
        // that should not be shown to end users.
        if let errorType = (self as NSError).userInfo[STPError.stripeErrorTypeKey] as? String,
           errorType != "card_error" {
            return NSError.stp_unexpectedErrorMessage()
        }
        let errorMessage = (self as NSError).userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
        return errorMessage
    }
}
