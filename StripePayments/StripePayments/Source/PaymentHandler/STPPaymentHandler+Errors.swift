//
//  STPPaymentHandler+Errors.swift
//  StripePayments
//
//  Extracted from STPPaymentHandler.swift for modularity.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - Error Creation

extension STPPaymentHandler {

    /// Creates an error for the given error code.
    /// - Parameter loggingSafeErrorMessage: Error details that are safe to log i.e. don't contain PII/PDE or secrets.
    @_spi(STP) public func _error(
        for errorCode: STPPaymentHandlerErrorCode,
        apiErrorCode: String? = nil,
        loggingSafeErrorMessage: String? = nil,
        localizedDescription: String? = nil
    ) -> NSError {
        var userInfo = [String: String]()
        userInfo[STPError.errorMessageKey] = loggingSafeErrorMessage
        userInfo[NSLocalizedDescriptionKey] = localizedDescription
        switch errorCode {
        // 3DS(2) flow expected user errors
        case .notAuthenticatedErrorCode:
            userInfo[NSLocalizedDescriptionKey] = STPLocalizedString(
                "We are unable to authenticate your payment method. Please choose a different payment method and try again.",
                "Error when 3DS2 authentication failed (e.g. customer entered the wrong code)"
            )

        case .timedOutErrorCode:
            userInfo[NSLocalizedDescriptionKey] = STPLocalizedString(
                "Timed out authenticating your payment method -- try again",
                "Error when 3DS2 authentication timed out."
            )

        // PaymentIntent has an unexpected status
        case .intentStatusErrorCode:
            // The PI's status is processing or unknown
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey] ?? "The PaymentIntent status cannot be handled."
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        case .unsupportedAuthenticationErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        case .requiredAppNotAvailable:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey]
                ?? "This PaymentIntent action requires an app, but the app is not installed or the request to open the app was denied."
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        // Programming errors
        case .requiresPaymentMethodErrorCode:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey]
                ?? "The PaymentIntent requires a PaymentMethod or Source to be attached before using STPPaymentHandler."
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        case .noConcurrentActionsErrorCode:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey]
                ?? "The current action is not yet completed. STPPaymentHandler does not support concurrent calls to its API."
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        case .requiresAuthenticationContextErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        case .missingReturnURL:
            userInfo[STPError.errorMessageKey] = missingReturnURLErrorMessage
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        // Exceptions thrown from the Stripe3DS2 SDK. Other errors are reported via STPChallengeStatusReceiver.
        case .stripe3DS2ErrorCode:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey] ?? "There was an error in the Stripe3DS2 SDK."
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        // Confirmation errors (eg card was declined)
        case .paymentErrorCode:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey]
                ?? "There was an error confirming the Intent. Inspect the `paymentIntent.lastPaymentError` or `setupIntent.lastSetupError` property."

            userInfo[NSLocalizedDescriptionKey] =
                apiErrorCode.flatMap({ NSError.Utils.localizedMessage(fromAPIErrorCode: $0) })
                ?? userInfo[NSLocalizedDescriptionKey]
                ?? NSError.stp_unexpectedErrorMessage()

        // Client secret format error
        case .invalidClientSecret:
            userInfo[STPError.errorMessageKey] =
                userInfo[STPError.errorMessageKey]
                ?? "The provided Intent client secret does not match the expected client secret format. Make sure your server is returning the correct value and that is passed to `STPPaymentHandler`."
            userInfo[NSLocalizedDescriptionKey] =
                userInfo[NSLocalizedDescriptionKey] ?? NSError.stp_unexpectedErrorMessage()

        case .unexpectedErrorCode:
            break
        }
        return STPPaymentHandlerError(code: errorCode, loggingSafeUserInfo: userInfo) as NSError
    }
}

// MARK: - STPPaymentHandlerError

/// STPPaymentHandler errors (i.e. errors that are created by the STPPaymentHandler class and have a corresponding STPPaymentHandlerErrorCode) used to be NSErrors.
/// This struct exists so that these errors can be Swift errors to conform to AnalyticLoggableError, while still looking like the old NSErrors to users (i.e. same domain and code).
struct STPPaymentHandlerError: Error, CustomNSError, AnalyticLoggableError {
    // AnalyticLoggableError properties
    let analyticsErrorType: String = errorDomain
    let analyticsErrorCode: String
    let additionalNonPIIErrorDetails: [String: Any]

    // CustomNSError properties, to not break old behavior when this was an NSError
    static let errorDomain: String = STPPaymentHandler.errorDomain
    let errorUserInfo: [String: Any]
    let errorCode: Int

    init(code: STPPaymentHandlerErrorCode, loggingSafeUserInfo: [String: String]) {
        errorCode = code.rawValue
        // Set analytics error code to the description (e.g. "invalidClientSecret")
        analyticsErrorCode = code.description
        errorUserInfo = loggingSafeUserInfo
        additionalNonPIIErrorDetails = loggingSafeUserInfo
    }
}
