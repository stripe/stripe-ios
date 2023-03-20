//
//  Analytic+Payments.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeApplePay

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

/// Represents a generic payment error analytic
struct GenericPaymentErrorAnalytic: PaymentAnalytic, ErrorAnalytic {
    let event: STPAnalyticEvent
    let paymentConfiguration: STPPaymentConfiguration?
    let productUsage: Set<String>
    let additionalParams: [String : Any]
    let error: Error
}


extension GenericPaymentAnalytic {
    var params: [String: Any] {
        var params = additionalParams

        if let paymentConfiguration = paymentConfiguration {
            let configurationDictionary = STPAnalyticsClient.serializeConfiguration(paymentConfiguration)
            params = params.merging(configurationDictionary) { (_, new) in new }
        }

        params["ui_usage_level"] = STPAnalyticsClient.uiUsageLevelString(from: productUsage)
        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = STPAnalyticsClient.ocrTypeString()
        params["pay_var"] = STPAnalyticsClient.paymentsSDKVariant
        return params
    }
}
