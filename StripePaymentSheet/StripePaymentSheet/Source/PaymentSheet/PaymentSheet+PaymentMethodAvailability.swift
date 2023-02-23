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
        .AUBECSDebit,
        .UPI,
        .cashApp,
    ]

    /// An unordered list of paymentMethodtypes that can be used with Link in PaymentSheet
    /// - Note: This is a var because it depends on the authenticated Link user
    ///
    /// :nodoc:
    internal static var supportedLinkPaymentMethods: [STPPaymentMethodType] = []
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
        case let .paymentIntent(paymentIntent):
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
        case let .setupIntent(setupIntent):
            var reqs = [PaymentMethodTypeRequirement]()

            // valid us bank verification method
            if let usBankOptions = setupIntent.paymentMethodOptions?.usBankAccount,
                usBankOptions.verificationMethod.isValidForPaymentSheet
            {
                reqs.append(.validUSBankVerificationMethod)
            }
            return reqs
        case .deferredIntent:
            // TODO(DeferredIntent): Allow ACHv2
            return []
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

        /// A special case that indicates the payment method is unavailable
        case unavailable

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
            case .unavailable:
                return "unavailable: This payment method is not available."
            case .returnURL:
                return "returnURL: A return URL must be set, see https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet#ios-set-up-return-url"
            case .shippingAddress:
                return "shippingAddress: A shipping address must be present on the Intent or collected through the Address Element and populated on PaymentSheet.Configuration.shippingDetails. See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping and https://stripe.com/docs/elements/address-element/collect-addresses?platform=ios#ios-pre-fill-billing"
            case .userSupportsDelayedPaymentMethods:
                return "userSupportsDelayedPaymentMethods: PaymentSheet.Configuration.allowsDelayedPaymentMethods must be set to true."
            case .financialConnectionsSDK:
                return "financialConnectionsSDK: The FinancialConnections SDK must be linked."
            case .validUSBankVerificationMethod:
                return "validUSBankVerificationMethod: Requires a valid US bank verification method."
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
        case missingRequirements([PaymentMethodTypeRequirement])

        var description: String {
            switch self {
            case .supported:
                return "Supported by PaymentSheet."
            case .notSupported:
                return "Not currently supported by PaymentSheet."
            case .unactivated:
                return "Activated for test mode but not activated for live mode:. Visit the Stripe Dashboard to activate the payment method. https://support.stripe.com/questions/activate-a-new-payment-method"
            case .missingRequirements(let missingRequirements):
                return "\(missingRequirements.reduce("") { $0 + $1.debugDescription }) "
            }
        }

        static func ==(lhs: PaymentMethodAvailabilityStatus, rhs: PaymentMethodAvailabilityStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notSupported, .notSupported):
                return true
            case (.supported, .supported):
                return true
            case (.unactivated, .unactivated):
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
