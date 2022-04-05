//
//  Intent.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
//  This file contains types that abstract over PaymentIntent and SetupIntent for convenience.

import Foundation

// MARK: - Intent

/// An internal type representing either a PaymentIntent or a SetupIntent
enum Intent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)
    
    var clientSecret: String {
        switch self {
        case .paymentIntent(let pi):
            return pi.clientSecret
        case .setupIntent(let si):
            return si.clientSecret
        }
    }
    
    var unactivatedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.unactivatedPaymentMethodTypes
        case .setupIntent(let si):
            return si.unactivatedPaymentMethodTypes
        }
    }
    
    /// A sorted list of payment method types supported by the Intent and PaymentSheet, ordered from most recommended to least recommended.
    var recommendedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.orderedPaymentMethodTypes
        case .setupIntent(let si):
            return si.orderedPaymentMethodTypes
        }
    }

    var isPaymentIntent: Bool {
        if case .paymentIntent(_) = self {
            return true
        }

        return false
    }

    var supportsLink: Bool {
        return recommendedPaymentMethodTypes.contains(.link)
    }
}

// MARK: - IntentClientSecret

/// An internal type representing a PaymentIntent or SetupIntent client secret
enum IntentClientSecret {
    /// The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    case paymentIntent(clientSecret: String)
    
    /// The [client secret](https://stripe.com/docs/api/setup_intents/object#setup_intent_object-client_secret) of a Stripe SetupIntent object
    case setupIntent(clientSecret: String)
}

// MARK: - IntentConfirmParams

/// An internal type representing both `STPPaymentIntentParams` and `STPSetupIntentParams`
/// - Note: Assumes you're confirming with a new payment method
class IntentConfirmParams {

    let paymentMethodParams: STPPaymentMethodParams
    let paymentMethodType: STPPaymentMethodType
    
    /// True if the customer opts to save their payment method for future payments.
    /// - Note: PaymentIntent-only
    var shouldSavePaymentMethod: Bool = false
    /// - Note: PaymentIntent-only
    var paymentMethodOptions: STPConfirmPaymentMethodOptions?
    
    convenience init(type: STPPaymentMethodType) {
        self.init(params: STPPaymentMethodParams(type: type))
    }

    init(params: STPPaymentMethodParams) {
        self.paymentMethodType = params.type
        self.paymentMethodParams = params
    }
    
    func makeParams(paymentIntentClientSecret: String) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodParams = paymentMethodParams
        let options = paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
        options.setSetupFutureUsageIfNecessary(shouldSavePaymentMethod, paymentMethodType: paymentMethodType)
        params.paymentMethodOptions = options

        return params
    }
    
    func makeParams(setupIntentClientSecret: String) -> STPSetupIntentConfirmParams {
        let params = STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret)
        params.paymentMethodParams = paymentMethodParams
        return params
    }
    
    func makeDashboardParams(paymentIntentClientSecret: String, paymentMethodID: String) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodId = paymentMethodID
        
        // Dashboard only supports a specific payment flow today
        assert(paymentMethodOptions == nil)
        assert(shouldSavePaymentMethod == false)
        params.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        let cardOptions = STPConfirmCardOptions()
        cardOptions.additionalAPIParameters["moto"] = true
        params.paymentMethodOptions?.cardOptions = cardOptions
        return params
    }
}

extension STPConfirmPaymentMethodOptions {
    /**
     Sets `payment_method_options[card][setup_future_usage]`
     
     - Note: PaymentSheet uses this `setup_future_usage` (SFU) value very differently from the top-level one:
        We read the top-level SFU to know the merchant’s desired save behavior
        We write payment method options SFU to set the customer’s desired save behavior
     */
    func setSetupFutureUsageIfNecessary(_ shouldSave: Bool, paymentMethodType: STPPaymentMethodType) {
        guard paymentMethodType == .card else {
            // Only support card setup_future_usage in payment_method_options
            return
        }
        
        additionalAPIParameters["card"] = [
            // We pass an empty string to 'unset' this value. This makes the PaymentIntent inherit the top-level setup_future_usage.
            "setup_future_usage": shouldSave ? "off_session" : ""
        ]
    }
}
