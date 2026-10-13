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

    /// Adds a diagnostic identifier to the existing localized description in live mode.
    func userFacingDescription(using apiClient: STPAPIClient) -> String {
        guard !apiClient.isTestmode else { return nonGenericDescription }

        // Unwrap only to find metadata; keep the original error's localized description.
        // Limit traversal in case the underlying-error chain contains a cycle.
        var error: Error = self
        for _ in 0..<5 {
            if let checkoutError = error as? CheckoutError,
               case .apiError(_, let underlying?) = checkoutError {
                error = underlying
            } else if let underlying = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
                error = underlying
            } else {
                break
            }
        }

        let requestID: String?
        if case StripeError.apiError(let apiError) = error {
            requestID = apiError.requestID
        } else {
            requestID = (error as NSError).userInfo[STPError.stripeRequestIDKey] as? String
        }
        let identifier = requestID?.nonEmpty ?? error._stp_error_code?.nonEmpty ?? String((error as NSError).code)
        return localizedDescription + " (\(identifier))"
    }

    /// If the `localizedDescription` contains a generic error message this returns the raw error message within `userInfo`
    /// Otherwise returns the `localizedDescription`
    var nonGenericDescription: String {
        if let paymentSheetError = self as? PaymentSheetError {
            return paymentSheetError.debugDescription
        }
        // Path 1: STPPaymentHandler wraps API errors as NSUnderlyingError (e.g. after 3DS2 or
        // payment confirmation). The outer error has a generic localizedDescription so we dig
        // into the underlying error for the API message.
        if localizedDescription == "The operation couldn’t be completed. (STPPaymentHandlerErrorDomain error 2.)",
           let underlyingError = (self as NSError).userInfo["NSUnderlyingError"] as? NSError {
            return underlyingError.userSafeErrorMessage
        }
        // If the `localizedDescription` is not generic, return the `localizedDescription`
        if localizedDescription != NSError.stp_unexpectedErrorMessage() { return localizedDescription }

        // Path 2: Direct STPError with a generic localizedDescription (e.g. from STPAPIClient
        // network responses that set stripeErrorTypeKey directly in userInfo).
        return (self as NSError).userSafeErrorMessage
    }
}

private extension NSError {
    /// Returns `errorMessageKey` only when the error is a `card_error`, which per Stripe API docs
    /// is safe to display to end users. All other error types (e.g. `invalid_request_error`)
    /// contain developer-facing details and fall back to the generic message.
    /// When `stripeErrorTypeKey` is absent (e.g. SDK-internal connection errors), the message
    /// is assumed to be intentionally user-facing.
    var userSafeErrorMessage: String {
        let errorType = userInfo[STPError.stripeErrorTypeKey] as? String
        if let errorType, errorType != "card_error" {
            return NSError.stp_unexpectedErrorMessage()
        }
        return userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
    }
}
