//
//  Analytic.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An analytic that can be logged to our analytics system
protocol Analytic {
    var event: STPAnalyticEvent { get }
    var params: [String: Any] { get }
}

/**
 An analytic specific to payments that serializes a payment configuration into its params.
 */
protocol PaymentAnalytic: Analytic {
    var paymentConfiguration: STPPaymentConfiguration? { get }
    var productUsage: Set<String> { get }
    var additionalParams: [String: Any] { get }
}

extension PaymentAnalytic {
    var params: [String: Any] {
        var params = additionalParams

        if let paymentConfiguration = paymentConfiguration {
            let configurationDictionary = STPAnalyticsClient.serializeConfiguration(paymentConfiguration)
            params = params.merging(configurationDictionary) { (_, new) in new }
        }
        
        params["ui_usage_level"] = STPAnalyticsClient.uiUsageLevelString(from: productUsage)
        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = STPAnalyticsClient.ocrTypeString()
        return params
    }
}

/**
 A generic analytic type.
 - NOTE: This should only be used to support legacy analytics.
 Any new analytic events should create a new type and conform to `Analytic`.
 */
struct GenericAnalytic: Analytic {
    let event: STPAnalyticEvent
    let params: [String : Any]
}

/**
 A generic analytic type.
 - NOTE: This should only be used to support legacy analytics.
 Any new analytic events should create a new type and conform to `PaymentAnalytic`.
 */
struct GenericPaymentAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let paymentConfiguration: STPPaymentConfiguration?
    let productUsage: Set<String>
    let additionalParams: [String : Any]
}
