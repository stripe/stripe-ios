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
public enum PaymentSheetError: Error {

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

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension PaymentSheetError: CustomDebugStringConvertible {
    /// Returns true if the error is un-fixable; e.g. no amount of retrying or customer action will result in something different
    static func isUnrecoverable(error: Error) -> Bool {
        // TODO: Expired ephemeral key
        return false
    }

    /// A string that can safley be logged to our analytics service that does not contain any PII
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
        }
    }   case .unknown:
            return "unknown"
        }
    }

    /// A description logged to a developer for debugging
    public var debugDescription: String {
        switch self {
        case .unknown(debugDescription: let message):
            return "An unknown error occurred in PaymentSheet. " + message
        case .linkLookupNotFound(serverErrorMessage: let message):
            return "An error occurred in PaymentSheet. " + message
        default:
            return "An error occurred in PaymentSheet. " + safeLoggingString
        }
    }
}
