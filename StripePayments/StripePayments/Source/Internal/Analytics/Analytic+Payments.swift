//
//  Analytic+Payments.swift
//  StripePayments
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// A generic analytic type.
/// - NOTE: This should only be used to support legacy analytics.
/// Any new analytic events should create a new type and conform to `PaymentAnalytic`.
struct GenericPaymentAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let paymentConfiguration: NSObject?
    let additionalParams: [String: Any]
}

/// Represents a generic payment error analytic
struct GenericPaymentErrorAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let paymentConfiguration: NSObject?
    let additionalParams: [String: Any]
    let error: Error
}

extension GenericPaymentAnalytic {
    var params: [String: Any] {
        var params = additionalParams

        params["company_name"] = Bundle.stp_applicationName() ?? ""
        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = PaymentsSDKVariant.ocrTypeString
        params["pay_var"] = PaymentsSDKVariant.variant

        if let paymentConfiguration = paymentConfiguration,
            let analyticsSerializerClass = GenericPaymentAnalytic.STPBasicUIAnalyticsSerializerClass
        {
            let configurationDictionary = analyticsSerializerClass.serializeConfiguration(
                paymentConfiguration
            )
            params = params.merging(configurationDictionary) { (_, new) in new }
        }

        return params
    }

    static let STPBasicUIAnalyticsSerializerClass: STPAnalyticsSerializer.Type? =
        NSClassFromString("Stripe.STPBasicUIAnalyticsSerializer") as? STPAnalyticsSerializer.Type

}

@_spi(STP) public protocol STPAnalyticsSerializer {
    static func serializeConfiguration(_ configuration: NSObject) -> [String: String]
}
