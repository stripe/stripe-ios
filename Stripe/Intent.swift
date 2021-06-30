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

    var paymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.paymentMethodTypes.map({
                STPPaymentMethodType(rawValue: $0.intValue) ?? .unknown
            })
        case .setupIntent(let si):
            return si.paymentMethodTypes.map({
                STPPaymentMethodType(rawValue: $0.intValue) ?? .unknown
            })
        }
    }

    var orderedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.orderedPaymentMethodTypes
        case .setupIntent(let si):
            return si.orderedPaymentMethodTypes
        }
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
class IntentConfirmParams {
    var paymentMethodParams: STPPaymentMethodParams = STPPaymentMethodParams()

    /// - Note: PaymentIntent-only
    var savePaymentMethod: Bool = false
    /// - Note: PaymentIntent-only
    var paymentMethodOptions: STPConfirmPaymentMethodOptions?
    
    func makeParams(paymentIntentClientSecret: String) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodParams = paymentMethodParams
        params.paymentMethodOptions = paymentMethodOptions
        if savePaymentMethod {
            params.setupFutureUsage = .offSession
        }
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
        assert(savePaymentMethod == false)
        params.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        let cardOptions = STPConfirmCardOptions()
        cardOptions.additionalAPIParameters["moto"] = true
        params.paymentMethodOptions?.cardOptions = cardOptions
        return params
    }
}
