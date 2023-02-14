//
//  IntentRepresentable.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/13/23.
//

import Foundation
@_spi(STP) import StripePayments

protocol IntentRepresentable: PaymentMethodRequirementProvider {
    
    /// The list of payment method types that this Intent is allowed to use.
    var recommendedPaymentSheetMethodTypes: [PaymentSheet.PaymentMethodType] { get }
    
    /// The list of payment method types that this Intent is allowed to use.
    var recommendedPaymentMethodTypes: [STPPaymentMethodType] { get }
    
    // The list of payment method types that are not activated in your Stripe dashboard.
    var unactivatedPaymentMethodTypes: [STPPaymentMethodType] { get }
    
    /// Three-letter ISO currency code, in lowercase.
    /// - Note: Required to be non-nil when representing a PaymentIntent.
    var currency: String? { get }
    
    /// Amount intended to be collected by this PaymentIntent.
    /// - Note: Required to be non-nil when representing a PaymentIntent.
    var amount: Int? { get }
    
    /// Indicates that you intend to make future payments with this Intent's payment method.
    var setupFutureUsage: STPPaymentIntentSetupFutureUsage? { get }
}

extension IntentRepresentable {
    var supportsLink: Bool {
        return recommendedPaymentMethodTypes.contains(.link)
    }
    
    var isPaymentIntent: Bool {
        // payment intents require both currency and amount
        if currency != nil && amount != nil {
            return true
        }
        
        return false
    }
    
    var isSettingUp: Bool {
        if isPaymentIntent {
            return (setupFutureUsage ?? .none) != .none
        }
        
        // is a setup intent
        return true
    }
    
    var callToAction: ConfirmButton.CallToActionType {
        if let amount = amount, let currency = currency {
            return .pay(amount: amount, currency: currency)
        } else {
            return .setup
        }
    }
}

extension Intent: IntentRepresentable {
    var recommendedPaymentSheetMethodTypes: [PaymentSheet.PaymentMethodType] {
        switch self {
        case .paymentIntent(let paymentIntent):
            guard
                let paymentMethodTypeStrings = paymentIntent.allResponseFields["payment_method_types"] as? [String]
            else {
                return []
            }
            let paymentTypesString =
                paymentIntent.allResponseFields["ordered_payment_method_types"] as? [String]
                ?? paymentMethodTypeStrings
            return paymentTypesString.map { PaymentSheet.PaymentMethodType(from: $0) }
        case .setupIntent(let setupIntent):
            guard let paymentMethodTypeStrings = setupIntent.allResponseFields["payment_method_types"] as? [String]
            else {
                return []
            }
            let paymentTypesString =
                setupIntent.allResponseFields["ordered_payment_method_types"] as? [String]
                ?? paymentMethodTypeStrings
            return paymentTypesString.map { PaymentSheet.PaymentMethodType(from: $0) }
        }
    }
    
    var amount: Int? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.amount
        case .setupIntent:
            return nil
        }
    }
    
    var setupFutureUsage: STPPaymentIntentSetupFutureUsage? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.setupFutureUsage
        case .setupIntent:
            return nil
        }
    }
    
}
