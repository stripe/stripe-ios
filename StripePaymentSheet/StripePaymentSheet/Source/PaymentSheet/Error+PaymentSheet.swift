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
    /// Returns a user-safe error message applying live/test mode rules:
    /// - `card_error`: always shows the raw card message (safe per Stripe API docs).
    /// - Non-card errors in **live mode**: shows a generic message. If a request ID is
    ///   available it is appended ("Something went wrong. Request ID: req_xxx") so users
    ///   can reference it with support; otherwise falls back to the generic unexpected-error string.
    /// - Non-card errors in **test mode**: preserves the raw server message so developers
    ///   can diagnose issues during integration.
    /// - When `stripeErrorTypeKey` is absent (e.g. SDK-internal connection errors), the
    ///   message is assumed to be intentionally user-facing and is returned as-is.
    var userSafeErrorMessage: String {
        let errorType = userInfo[STPError.stripeErrorTypeKey] as? String
        guard let errorType else {
            return userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
        }
        guard errorType != "card_error" else {
            return userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
        }
        // Non-card server error: apply live/test-mode logic.
        let isLiveMode = userInfo[STPError.stripeLivemodeKey] as? Bool ?? false
        if isLiveMode {
            if let requestId = userInfo[STPError.stripeRequestIDKey] as? String {
                let format = STPLocalizedString(
                    "Something went wrong. Request ID: %@",
                    "Error message shown to the user in live mode for non-card API errors, including the request ID for support reference."
                )
                return String(format: format, requestId)
            }
            return NSError.stp_unexpectedErrorMessage()
        }
        // Test mode: preserve the raw server message to aid developer debugging.
        return userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
    }
}
