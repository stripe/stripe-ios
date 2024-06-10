//
//  PaymentSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

extension PaymentSheet {

    /// An unordered list of paymentMethod types that can be used with PaymentSheet
    /// - Note: This is a var so that we can enable experimental payment methods in PaymentSheetTestPlayground.
    /// Modifying this property in a production app can lead to unexpected behavior.
    ///
    /// :nodoc:
    @_spi(STP) public static var supportedPaymentMethods: [STPPaymentMethodType] = [
        .card, .payPal,
        .klarna, .afterpayClearpay, .affirm,
        .iDEAL, .bancontact, .sofort, .SEPADebit, .EPS, .giropay, .przelewy24,
        .USBankAccount,
        .instantDebits,
        .AUBECSDebit,
        .UPI,
        .cashApp,
        .blik,
        .grabPay,
        .FPX,
        .bacsDebit,
        .alipay,
        .OXXO, .zip, .revolutPay, .amazonPay, .alma, .mobilePay, .konbini, .paynow, .promptPay,
        .boleto,
        .swish,
        .twint,
        .multibanco,
    ]
}

// MARK: - PaymentMethodRequirementProvider

/// Defines an instance type who provides a set of `PaymentMethodTypeRequirement` it satisfies
protocol PaymentMethodRequirementProvider {

    /// The set of payment requirements provided by this instance
    var fulfilledRequirements: [PaymentMethodTypeRequirement] { get }
}

extension PaymentSheet.Configuration: PaymentMethodRequirementProvider {
    var fulfilledRequirements: [PaymentMethodTypeRequirement] {
        var reqs = [PaymentMethodTypeRequirement]()
        if returnURL != nil { reqs.append(.returnURL) }
        if allowsDelayedPaymentMethods { reqs.append(.userSupportsDelayedPaymentMethods) }
        if allowsPaymentMethodsRequiringShippingAddress { reqs.append(.shippingAddress) }
        if FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
            reqs.append(.financialConnectionsSDK)
        }
        return reqs
    }
}

extension Intent: PaymentMethodRequirementProvider {
    var fulfilledRequirements: [PaymentMethodTypeRequirement] {
        switch self {
        case let .paymentIntent(_, paymentIntent):
            var reqs = [PaymentMethodTypeRequirement]()
            // Shipping address
            if let shippingInfo = paymentIntent.shipping {
                if shippingInfo.name != nil,
                    shippingInfo.address?.line1 != nil,
                    shippingInfo.address?.country != nil,
                    shippingInfo.address?.postalCode != nil
                {
                    reqs.append(.shippingAddress)
                }
            }

            // valid us bank verification method
            if let usBankOptions = paymentIntent.paymentMethodOptions?.usBankAccount,
                usBankOptions.verificationMethod.isValidForPaymentSheet
            {
                reqs.append(.validUSBankVerificationMethod)
            }

            return reqs
        case let .setupIntent(_, setupIntent):
            var reqs = [PaymentMethodTypeRequirement]()

            // valid us bank verification method
            if let usBankOptions = setupIntent.paymentMethodOptions?.usBankAccount,
                usBankOptions.verificationMethod.isValidForPaymentSheet
            {
                reqs.append(.validUSBankVerificationMethod)
            }
            return reqs
        case .deferredIntent:
            // Verification method is always 'automatic'
            return [.validUSBankVerificationMethod]
        }
    }
}

extension STPPaymentMethodOptions.USBankAccount.VerificationMethod {
    var isValidForPaymentSheet: Bool {
        switch self {
        case .skip, .microdeposits, .unknown:
            return false
        case .automatic, .instant, .instantOrSkip:
            return true
        }
    }
}

typealias PaymentMethodTypeRequirement = PaymentSheet.PaymentMethodTypeRequirement

extension PaymentSheet {
    enum PaymentMethodTypeRequirement: Comparable {

        /// A special case that indicates the payment method is always unsupported by PaymentSheet
        case unsupported

        /// A special case that indicates the payment method is unsupported by PaymentSheet when using SetupIntents or SFU
        case unsupportedForSetup

        /// A special case that indicates the payment method is unsupported by PaymentSheet for later reuse
        case unsupportedForReuse

        /// Indicates that a payment method requires a return URL
        case returnURL

        /// Indicates that a payment method requires shipping information
        case shippingAddress

        /// Requires that the user declare support for asynchronous payment methods
        case userSupportsDelayedPaymentMethods

        /// Requires that the FinancialConnections SDK has been linked
        case financialConnectionsSDK

        /// Requires a valid us bank verification method
        case validUSBankVerificationMethod

        /// A helpful description for developers to better understand requirements so they can debug why payment methods are not present
        var debugDescription: String {
            switch self {
            case .unsupported:
                return "This payment method is not currently supported by PaymentSheet."
            case .unsupportedForSetup:
                return "This payment method is not currently supported by PaymentSheet when using a PaymentIntent with the `setupFutureUsage` parameter, or when using a SetupIntent."
            case .unsupportedForReuse:
                return "PaymentSheet does not currently support reusing this saved payment method."
            case .returnURL:
                return "A return URL must be set, see https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet#ios-set-up-return-url"
            case .shippingAddress:
                return "A shipping address must be present on the Intent or collected through the Address Element and populated on PaymentSheet.Configuration.shippingDetails. See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping and https://stripe.com/docs/elements/address-element/collect-addresses?platform=ios#ios-pre-fill-billing"
            case .userSupportsDelayedPaymentMethods:
                return "PaymentSheet.Configuration.allowsDelayedPaymentMethods must be set to true."
            case .financialConnectionsSDK:
                return "financialConnectionsSDK: The FinancialConnections SDK must be linked. See https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet#ios-ach"
            case .validUSBankVerificationMethod:
                return "Requires a valid US bank verification method."
            }
        }

    }

    enum PaymentMethodAvailabilityStatus: Equatable {
        /// This payment method is supported by PaymentSheet and the current configuration and intent
        case supported
        /// This payment method is not supported by PaymentSheet and/or the current configuration or intent
        case notSupported
        /// This payment method is not activated in live mode in the Stripe Dashboard
        case unactivated
        /// This payment method has requirements not met by the configuration or intent
        case missingRequirements(Set<PaymentMethodTypeRequirement>)

        var debugDescription: String {
            switch self {
            case .supported:
                return "Supported by PaymentSheet."
            case .notSupported:
                return "This payment method is not currently supported by PaymentSheet."
            case .unactivated:
                return "This payment method is enabled for test mode, but is not activated for live mode. Visit the Stripe Dashboard to activate the payment method. https://support.stripe.com/questions/activate-a-new-payment-method"
            case .missingRequirements(let missingRequirements):
                return missingRequirements.map { $0.debugDescription }.joined(separator: "\n\t* ")
            }
        }

        static func ==(lhs: PaymentMethodAvailabilityStatus, rhs: PaymentMethodAvailabilityStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notSupported, .notSupported),
                 (.supported, .supported),
                 (.unactivated, .unactivated):
                  return true
            case (.missingRequirements(let requirements), .missingRequirements(let otherRequirements)):
                // don't care about the ordering
                return requirements.sorted(by: { $0 >= $1 }) == otherRequirements.sorted(by: { $0 >= $1 })
            default:
                return false
            }
        }
    }
}
