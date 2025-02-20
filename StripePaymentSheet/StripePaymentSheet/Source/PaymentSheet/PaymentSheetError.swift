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
    case integrationError(nonPIIDebugDescription: String)
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
    case embeddedPaymentElementUpdateWithFormPresented

    // MARK: Loading errors
    case paymentIntentInTerminalState(status: STPPaymentIntentStatus)
    case setupIntentInTerminalState(status: STPSetupIntentStatus)
    case fetchPaymentMethodsFailure

    // MARK: Deferred intent errors
    case intentConfigurationValidationFailed(message: String)
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
    case confirmingWithInvalidPaymentOption
    case embeddedPaymentElementAlreadyConfirmedIntent

    public var errorDescription: String? {
        switch self {
        case .confirmingWithInvalidPaymentOption:
            return String.Localized.please_choose_a_valid_payment_method
        default:
            return NSError.stp_unexpectedErrorMessage()
        }
    }
}

extension PaymentSheetError: CustomDebugStringConvertible {
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
            case .intentConfigurationValidationFailed(message: let message):
                return message
            case .embeddedPaymentElementAlreadyConfirmedIntent:
                return "This instance of EmbeddedPaymentElement has already confirmed an intent successfully. Create a new instance of EmbeddedPaymentElement to confirm a new intent."
            case .integrationError(nonPIIDebugDescription: let nonPIIDebugDescription):
                return "There's a problem with your integration. \(nonPIIDebugDescription)"
            case .confirmingWithInvalidPaymentOption:
                return "`confirm` should only be called when `paymentOption` is not nil"
            case .embeddedPaymentElementUpdateWithFormPresented:
                return "`update` called while a form is already presented, this is not supported. `update` should only be called while a form is not presented."
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
