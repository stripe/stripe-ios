//
//  PaymentSheetError.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

/// Errors specific to PaymentSheet itself
///
/// Most errors do not originate from PaymentSheet itself; instead, they come from the Stripe API
/// or other SDK components like STPPaymentHandler, PassKit (Apple Pay), etc.
public enum PaymentSheetError: Error, LocalizedError {

    /// An unknown error.
    case unknown(debugDescription: String)

    // MARK: Generic errors
    case missingClientSecret
    case invalidClientSecret
    case unexpectedResponseFromStripeAPI
    case applePayNotSupportedOrMisconfigured
    case alreadyPresented
    case flowControllerConfirmFailed(message: String)
    case errorHandlingNextAction
    case unrecognizedHandlerStatus
    case accountLinkFailure
    case setupIntentClientSecretProviderNil
    /// No payment method types available error.
    case noPaymentMethodTypesAvailable(intentPaymentMethods: [STPPaymentMethodType])

    // MARK: Loading errors
    case paymentIntentInTerminalState(status: STPPaymentIntentStatus)
    case setupIntentInTerminalState(status: STPSetupIntentStatus)
    case fetchPaymentMethodsFailure

    // MARK: Deferred intent errors
    case deferredIntentValidationFailed(message: String)

    // MARK: - Link errors
    case linkSignUpNotRequired
    case linkCallVerifyNotRequired
    case linkingWithoutValidSession
    case savingWithoutValidLinkSession
    case payingWithoutValidLinkSession
    case deletingWithoutValidLinkSession
    case updatingWithoutValidLinkSession
    case linkLookupNotFound(serverErrorMessage: String)
    case failedToCreateLinkSession
    case linkNotAuthorized

    // MARK: - Confirmation errors
    case unexpectedNewPaymentMethod

    public var errorDescription: String? {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension PaymentSheetError: CustomDebugStringConvertible {
    /// A string that can safely be logged to our analytics service that does not contain any PII
    public var safeLoggingString: String {
        switch self {
        case .unknown:
            return "unknown"
        case .missingClientSecret:
            return "missingClientSecret"
        case .invalidClientSecret:
            return "invalidClientSecret"
        case .unexpectedResponseFromStripeAPI:
            return "unexpectedResponseFromStripeAPI"
        case .applePayNotSupportedOrMisconfigured:
            return "applePayNotSupportedOrMisconfigured"
        case .alreadyPresented:
            return "alreadyPresented"
        case .flowControllerConfirmFailed:
            return "flowControllerConfirmFailed"
        case .errorHandlingNextAction:
            return "errorHandlingNextAction"
        case .unrecognizedHandlerStatus:
            return "unrecognizedHandlerStatus"
        case .accountLinkFailure:
            return "accountLinkFailure"
        case .setupIntentClientSecretProviderNil:
            return "setupIntentClientSecretProviderNil"
        case .noPaymentMethodTypesAvailable:
            return "noPaymentMethodTypesAvailable"
        case .paymentIntentInTerminalState:
            return "paymentIntentInTerminalState"
        case .setupIntentInTerminalState:
            return "setupIntentInTerminalState"
        case .fetchPaymentMethodsFailure:
            return "fetchPaymentMethodsFailure"
        case .deferredIntentValidationFailed:
            return "deferredIntentValidationFailed"
        case .linkSignUpNotRequired:
            return "linkSignUpNotRequired"
        case .linkCallVerifyNotRequired:
            return "linkCallVerifyNotRequired"
        case .linkingWithoutValidSession:
            return "linkingWithoutValidSession"
        case .savingWithoutValidLinkSession:
            return "savingWithoutValidLinkSession"
        case .payingWithoutValidLinkSession:
            return "payingWithoutValidLinkSession"
        case .deletingWithoutValidLinkSession:
            return "deletingWithoutValidLinkSession"
        case .updatingWithoutValidLinkSession:
            return "updatingWithoutValidLinkSession"
        case .linkLookupNotFound:
            return "linkLookupNotFound"
        case .failedToCreateLinkSession:
            return "failedToCreateLinkSession"
        case .linkNotAuthorized:
            return "linkNotAuthorized"
        case .unexpectedNewPaymentMethod:
            return "unexpectedNewPaymentMethod"
        }
    }

    /// A description logged to a developer for debugging
    public var debugDescription: String {
        let errorMessageSuffix = {
            switch self {
            case .unknown(debugDescription: let message):
                return message
            case .linkLookupNotFound(serverErrorMessage: let message):
                return "An error occurred in PaymentSheet. " + message
            case .missingClientSecret:
                return "The client secret is missing"
            case .unexpectedResponseFromStripeAPI:
                return "Unexpected response from Stripe API."
            case .applePayNotSupportedOrMisconfigured:
                return "Attempted Apple Pay but it's not supported by the device, not configured, or missing a presenter"
            case .deferredIntentValidationFailed(message: let message):
                return message
            case .alreadyPresented:
                return "presentingViewController is already presenting a view controller"
            case .flowControllerConfirmFailed(message: let message):
                return message
            case .errorHandlingNextAction:
                return "Unknown error occured while handling intent next action"
            case .unrecognizedHandlerStatus:
                return "Unrecognized STPPaymentHandlerActionStatus status"
            case .invalidClientSecret:
                return "Invalid client secret"
            case .accountLinkFailure:
                return STPLocalizedString(
                    "Something went wrong when linking your account.\nPlease try again later.",
                    "Error message when an error case happens when linking your account"
                )
            case .paymentIntentInTerminalState(status: let status):
                return "PaymentSheet received a PaymentIntent in a terminal state: \(status)"
            case .setupIntentInTerminalState(status: let status):
                return "PaymentSheet received a SetupIntent in a terminal state: \(status)"
            case .fetchPaymentMethodsFailure:
                return "Failed to retrieve PaymentMethods for the customer"
            case .linkSignUpNotRequired:
                return "Don't call sign up if not needed"
            case .noPaymentMethodTypesAvailable(intentPaymentMethods: let intentPaymentMethods):
                return "None of the payment methods on the PaymentIntent/SetupIntent can be used in PaymentSheet: \(intentPaymentMethods). You may need to set `allowsDelayedPaymentMethods` or `allowsPaymentMethodsRequiringShippingAddress` or set `returnURL` in your PaymentSheet.Configuration object."
            case .linkCallVerifyNotRequired:
                return "Don't call verify if not needed"
            case .linkingWithoutValidSession:
                return "Linking account session without valid consumer session"
            case .savingWithoutValidLinkSession:
                return "Saving to Link without valid session"
            case .payingWithoutValidLinkSession:
                return "Paying with Link without valid session"
            case .deletingWithoutValidLinkSession:
                return "Deleting Link payment details without valid session"
            case .updatingWithoutValidLinkSession:
                return "Updating Link payment details without valid session"
            case .failedToCreateLinkSession:
                return "Failed to create Link account session"
            case .linkNotAuthorized:
                return "confirm called without authorizing Link"
            case .setupIntentClientSecretProviderNil:
                return "setupIntentClientSecretForCustomerAttach, but setupIntentClientSecretProvider is nil"
            case .unexpectedNewPaymentMethod:
                return "New payment method should not have been created yet"
            }
        }()

        switch self {
        case .unknown:
            return "An unknown error occurred in PaymentSheet. " + errorMessageSuffix
        default:
            return "An error occurred in PaymentSheet. " + errorMessageSuffix
        }
    }
}
