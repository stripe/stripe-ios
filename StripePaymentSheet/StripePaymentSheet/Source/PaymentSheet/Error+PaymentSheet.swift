//
//  Error+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

extension Error {

    /// Formats Stripe errors for SDK UI without changing the original error or test-mode diagnostics.
    /// Card errors and merchant-provided errors retain their actionable messages.
    func userFacingDescription(isTestmode: Bool) -> String {
        guard !isTestmode else { return nonGenericDescription }

        // Checkout and PaymentHandler can wrap an API error before it reaches the UI.
        // Bound traversal in case an underlying-error chain contains a cycle.
        var error: Error = self
        for _ in 0..<5 {
            if let checkoutError = error as? CheckoutError,
               case .apiError(_, let underlying?) = checkoutError {
                error = underlying
                continue
            }
            let nsError = error as NSError
            guard nsError.domain == STPError.STPPaymentHandlerErrorDomain,
                  let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error else {
                break
            }
            error = underlying
        }

        let nsError = error as NSError
        let requestID: String?
        let errorCode: String?
        let errorType: String?
        if let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError {
            if apiError.type == .cardError { return error.nonGenericDescription }
            requestID = apiError.requestID
            errorCode = apiError.code
            errorType = apiError.type.rawValue
        } else if nsError.domain == STPError.stripeDomain || nsError.domain == STPError.STPPaymentHandlerErrorDomain {
            if nsError.userInfo[STPError.stripeErrorTypeKey] as? String == "card_error" {
                return error.nonGenericDescription
            }
            // PaymentHandler maps confirmation errors to localized card messages.
            if nsError.domain == STPError.STPPaymentHandlerErrorDomain,
               nsError.code == STPPaymentHandlerErrorCode.paymentErrorCode.rawValue,
               nsError.userInfo[STPError.stripeErrorTypeKey] == nil,
               let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String,
               !message.isEmpty, message != NSError.stp_unexpectedErrorMessage() {
                return message
            }
            requestID = nsError.userInfo[STPError.stripeRequestIDKey] as? String
            errorCode = nsError.userInfo[STPError.stripeErrorCodeKey] as? String
            errorType = nsError.userInfo[STPError.stripeErrorTypeKey] as? String
        } else if error is PaymentSheetError || error is CheckoutError || error is StripeError {
            requestID = nil
            // Do not stringify SDK errors: CustomDebugStringConvertible can expose debug details
            // even for enum cases with no associated values.
            errorCode = (error as? StripeError)?.analyticsErrorCode
                ?? Mirror(reflecting: error).children.first?.label
                ?? String(nsError.code)
            errorType = nil
            // Preserve the SDK's explicit localized validation message.
            if let sheetError = error as? PaymentSheetError,
               sheetError.localizedDescription != NSError.stp_unexpectedErrorMessage() {
                return sheetError.localizedDescription
            }
        } else {
            // Merchants can supply their own user-facing errors from confirmation callbacks.
            return error.nonGenericDescription
        }

        let identifier = [requestID, errorCode, errorType].compactMap { $0 }.first { !$0.isEmpty }
            ?? String(nsError.code)
        return NSError.stp_unexpectedErrorMessage() + " (\(identifier))"
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
