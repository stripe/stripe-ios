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
        .iDEAL, .bancontact, .SEPADebit, .EPS, .przelewy24,
        .USBankAccount,
        .AUBECSDebit,
        .UPI,
        .cashApp,
        .blik,
        .grabPay,
        .FPX,
        .bacsDebit,
        .alipay,
        .OXXO, .zip, .revolutPay, .amazonPay, .alma, .mobilePay, .konbini, .paynow, .promptPay,
        .sunbit,
        .billie,
        .satispay,
        .crypto,
        .boleto,
        .swish,
        .twint,
        .multibanco,
    ]

    /// A list of `STPPaymentMethodType` that can be saved in PaymentSheet
    static let supportedSavedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit, .link]

    /// A list of `STPPaymentMethodType` that can be set as default in PaymentSheet when opted in to the "set as default" feature
    static let supportedDefaultPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

    /// Canonical source of truth for whether Apple Pay is enabled
    static func isApplePayEnabled(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> Bool {
        return StripeAPI.deviceSupportsApplePay()
            && configuration.applePay != nil
            && elementsSession.isApplePayEnabled
    }

    /// Canonical source of truth for whether Link is enabled
    static func isLinkEnabled(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> Bool {
        return linkDisabledReasons(elementsSession: elementsSession, configuration: configuration).isEmpty
    }

    /// Canonical source of truth for reasons why Link is disabled
    static func linkDisabledReasons(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> [LinkDisabledReason] {
        var reasons = [LinkDisabledReason]()

        if !elementsSession.supportsLink {
            reasons.append(.notSupportedInElementsSession)
        }

        if !configuration.link.shouldDisplay {
            reasons.append(.linkConfiguration)
        }

        // Disable Link web if the merchant is using card brand filtering
        if configuration.cardBrandAcceptance != .all && !deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) {
            reasons.append(.cardBrandFiltering)
        }

        if !elementsSession.isCompatibleWithBillingDetailsCollection(in: configuration) {
            reasons.append(.billingDetailsCollection)
        }

        return reasons
    }

    static func isLinkSignupEnabled(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> Bool {
        return linkSignupDisabledReasons(elementsSession: elementsSession, configuration: configuration).isEmpty
    }

    static func linkSignupDisabledReasons(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> [LinkSignupDisabledReason] {
        var reasons = [LinkSignupDisabledReason]()

        if !isLinkEnabled(elementsSession: elementsSession, configuration: configuration) {
            reasons.append(.linkNotEnabled)
        }

        if !elementsSession.supportsLinkCard {
            reasons.append(.linkCardNotSupported)
        }

        if elementsSession.disableLinkSignup && !elementsSession.linkSignupOptInFeatureEnabled {
            reasons.append(.disabledInElementsSession)
        }

        if elementsSession.linkSignupOptInFeatureEnabled && LinkAccountContext.shared.account == nil {
            reasons.append(.signupOptInFeatureNoEmailProvided)
        }

        // If attestation is enabled for this app but the specific device doesn't support attestation,
        // don't show inline signup: It's unlikely to provide a good experience. We'll only allow the web popup flow.
        let useAttestationEndpoints = elementsSession.linkSettings?.useAttestationEndpoints ?? false
        if useAttestationEndpoints && !deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) {
            reasons.append(.attestationIssues)
        }

        // In live mode, we only show signup if the customer hasn't used Link in the merchant app before.
        // In test mode, we continue to show it to make testing easier.
        if UserDefaults.standard.customerHasUsedLink && !configuration.apiClient.isTestmode {
            reasons.append(.linkUsedBefore)
        }

        return reasons
    }

    /// An unordered list of paymentMethodTypes that can be used with Link in PaymentSheet
    /// - Note: This is a var because it depends on the authenticated Link user
    ///
    /// :nodoc:
    internal static var supportedLinkPaymentMethods: [STPPaymentMethodType] = []
}

private extension STPElementsSession {
    func isCompatibleWithBillingDetailsCollection(in configuration: PaymentElementConfiguration) -> Bool {
        // We can't collect billing details if we're in the web flow, so turn Link off for those cases.
        let nativeLink = deviceCanUseNativeLink(elementsSession: self, configuration: configuration)
        return nativeLink || !configuration.requiresBillingDetailCollection()
    }
}

// MARK: - PaymentMethodRequirementProvider

/// Defines an instance type who provides a set of `PaymentMethodTypeRequirement` it satisfies
protocol PaymentMethodRequirementProvider {

    /// The set of payment requirements provided by this instance
    var fulfilledRequirements: [PaymentMethodTypeRequirement] { get }
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
    enum PaymentMethodTypeRequirement: Hashable {

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

        /// The email collection configuration is invalid for this payment method.
        case invalidEmailCollectionConfiguration

        /// The Bank payment method is disabled.
        case instantDebitsDisabledForOnboarding

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
            case .invalidEmailCollectionConfiguration:
                return "The provided configuration must either collect an email, or a default email must be provided. See https://docs.stripe.com/payments/payment-element/control-billing-details-collection"
            case .instantDebitsDisabledForOnboarding:
                return "The Bank tab is configured to be hidden for your account."
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
            let separator = "\n\t* "
            switch self {
            case .supported:
                return "Supported by PaymentSheet."
            case .notSupported:
                return "This payment method is not currently supported by PaymentSheet."
            case .unactivated:
                return "This payment method is enabled for test mode, but is not activated for live mode. Visit the Stripe Dashboard to activate the payment method. https://support.stripe.com/questions/activate-a-new-payment-method"
            case .missingRequirements(let missingRequirements):
                return "\t* \(missingRequirements.map { $0.debugDescription }.joined(separator: separator))"
            }
        }

        static func ==(lhs: PaymentMethodAvailabilityStatus, rhs: PaymentMethodAvailabilityStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notSupported, .notSupported),
                 (.supported, .supported),
                 (.unactivated, .unactivated):
                  return true
            case (.missingRequirements(let requirements), .missingRequirements(let otherRequirements)):
                // Using `==` on two sets does not consider the order of items in the set.
                return requirements == otherRequirements
            default:
                return false
            }
        }
    }
}

// MARK: - STPPaymentMethodType Mandate Data Helpers

@_spi(STP) extension STPPaymentMethodType {

    /// Payment method types that require mandate data for PaymentIntents when setup_future_usage is off_session
    static var requiresMandateDataForPaymentIntent: Set<STPPaymentMethodType> {
        [.payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay]
    }

    /// Payment method types that require mandate data for SetupIntents
    static var requiresMandateDataForSetupIntent: Set<STPPaymentMethodType> {
        [.payPal, .revolutPay, .satispay]
    }
}
