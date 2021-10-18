//
//  PaymentSheet+PaymentMethodAvailability.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension PaymentSheet {
    
    /// An unordered list of paymentMethod types that can be used with PaymentSheet
    /// - Note: This is a var so that we can enable experimental payment methods in PaymentSheetTestPlayground.
    /// Modifying this property in a production app can lead to unexpected behavior.
    ///
    /// :nodoc:
    @_spi(STP) public static var supportedPaymentMethods: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort, .SEPADebit]

    /// Returns whether or not PaymentSheet, with the given `PaymentMethodRequirementProvider`s, should make the given `paymentMethod` available to add.
    /// Note: This doesn't affect the availability of saved PMs.
    /// - Parameters:
    ///   - paymentMethod: the `STPPaymentMethodType` in question
    ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
    ///   - supportedPaymentMethods: the payment methods that PaymentSheet can display UI for
    /// - Returns: true if `paymentMethod` should be available in the PaymentSheet, false otherwise
    static func supportsAdding(
        paymentMethod: STPPaymentMethodType,
        configuration: PaymentSheet.Configuration,
        intent: Intent,
        supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
    ) -> Bool {
        let requirements: [PaymentMethodTypeRequirement] = {
            switch paymentMethod {
            case .blik, .card, .cardPresent, .UPI, .weChatPay:
                return []
            case .alipay, .EPS, .FPX, .giropay, .grabPay, .netBanking, .payPal, .przelewy24:
                return [.returnURL]
            case .AUBECSDebit, .OXXO, .boleto:
                return [.userSupportsDelayedPaymentMethods]
            case .bancontact, .iDEAL:
                return [.returnURL, .notSettingUp]
            case .SEPADebit:
                return [.notSettingUp, .userSupportsDelayedPaymentMethods]
            case .bacsDebit:
                return [.returnURL, .userSupportsDelayedPaymentMethods]
            case .sofort:
                return [.returnURL, .notSettingUp, .userSupportsDelayedPaymentMethods]
            case .afterpayClearpay:
                return [.returnURL, .shippingAddress]
            case .unknown:
                return [.unavailable]
            }
        }()
        
        return supports(
            paymentMethod: paymentMethod,
            requirements: requirements,
            configuration: configuration,
            intent: intent,
            supportedPaymentMethods: supportedPaymentMethods
        )
    }
    
    /// Returns whether or not PaymentSheet should make the given `paymentMethod` available to save for future use, set up, and reuse
    /// i.e. available for a PaymentIntent with setupFutureUsage or SetupIntent or saved payment method
    /// - Parameters:
    ///   - paymentMethod: the `STPPaymentMethodType` in question
    ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
    ///   - supportedPaymentMethods: the payment methods that PaymentSheet can display UI for
    /// - Returns: true if `paymentMethod` should be available in the PaymentSheet, false otherwise
    static func supportsSaveAndReuse(
        paymentMethod: STPPaymentMethodType,
        configuration: PaymentSheet.Configuration,
        intent: Intent,
        supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
    ) -> Bool {
        let requirements: [PaymentMethodTypeRequirement] = {
            switch paymentMethod {
            case .card:
                return []
            case .alipay:
                return [.returnURL]
            case .iDEAL, .bancontact, .sofort:
                // SEPA-family PMs are disallowed until we can reuse them for PI+sfu and SI.
                // n.b. While iDEAL and bancontact are themselves not delayed, they turn into SEPA upon save, which IS delayed.
                return [.returnURL, .userSupportsDelayedPaymentMethods, .unavailable]
            case .SEPADebit:
                // SEPA-family PMs are disallowed until we can reuse them for PI+sfu and SI.
                return [.userSupportsDelayedPaymentMethods, .unavailable]
            case .AUBECSDebit:
                return [.userSupportsDelayedPaymentMethods]
            case .bacsDebit:
                return [.returnURL, .userSupportsDelayedPaymentMethods]
            case .cardPresent, .blik, .weChatPay, .grabPay, .FPX, .giropay, .przelewy24, .EPS,
                    .netBanking, .OXXO, .afterpayClearpay, .payPal, .UPI, .boleto, .unknown:
                return [.unavailable]
            }
        }()
        
        return supports(
            paymentMethod: paymentMethod,
            requirements: requirements,
            configuration: configuration,
            intent: intent,
            supportedPaymentMethods: supportedPaymentMethods
        )
    }
    
    /// DRY helper method
    static func supports(
        paymentMethod: STPPaymentMethodType,
        requirements: [PaymentMethodTypeRequirement],
        configuration: PaymentSheet.Configuration,
        intent: Intent,
        supportedPaymentMethods: [STPPaymentMethodType]
    ) -> Bool {
        guard supportedPaymentMethods.contains(paymentMethod) else {
            return false
        }
        
        // Hide a payment method type if we are in live mode and it is unactivated
        if !configuration.apiClient.isTestmode && intent.unactivatedPaymentMethodTypes.contains(paymentMethod) {
            return false
        }
        
        let fulfilledRequirements = [configuration, intent].reduce([]) {
            (accumulator: [PaymentMethodTypeRequirement], element: PaymentMethodRequirementProvider) in
            return accumulator + element.fulfilledRequirements
        }
        
        return Set(requirements).isSubset(of: fulfilledRequirements)
    }
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
                   shippingInfo.address?.postalCode != nil {
                    reqs.append(.shippingAddress)
                }
            }
            
            // Not setting up
            if paymentIntent.setupFutureUsage == .none {
                reqs.append(.notSettingUp)
            }
            return reqs
        case .setupIntent:
            return []
        }
    }
}

typealias PaymentMethodTypeRequirement = PaymentSheet.PaymentMethodTypeRequirement

extension PaymentSheet {
    enum PaymentMethodTypeRequirement {
        
        /// A special case that indicates the payment method is unavailable
        case unavailable
        
        /// Indicates that a payment method requires a return URL
        case returnURL
        
        /// Indicates that a payment method requires shipping information
        case shippingAddress
        
        /// Requires that we are not using a PaymentIntent+setupFutureUsage or SetupIntent with this PaymentMethod
        case notSettingUp
        
        /// Requires that the user declare support for asynchronous payment methods
        case userSupportsDelayedPaymentMethods
    }
}
