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
    var paymentConfiguration: STPPaymentConfiguration { get }
    var additionalParams: [String: Any] { get }
}

extension PaymentAnalytic {
    var params: [String: Any] {
        let configurationDictionary = STPAnalyticsClient.serializeConfiguration(paymentConfiguration)
        return additionalParams.merging(configurationDictionary) { (_, new) in new }
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
    let paymentConfiguration: STPPaymentConfiguration
    let additionalParams: [String : Any]
}
