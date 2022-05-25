//
//  STPAPIClient+PaymentsCore.swift
//  StripeApplePay
//
//  Created by David Estes on 1/25/22.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    @_spi(STP) public static var paymentUserAgent: String {
        var paymentUserAgent = "stripe-ios/\(STPAPIClient.STPSDKVersion)"
        let variant = "variant.\(STPAnalyticsClient.paymentsSDKVariant)"
        let components = [paymentUserAgent, variant] + STPAnalyticsClient.sharedClient.productUsage
        paymentUserAgent = components.joined(separator: "; ")
        return paymentUserAgent
    }
    
    @_spi(STP) public class func paramsAddingPaymentUserAgent(_ params: [String: Any]) -> [String: Any] {
        var newParams = params
        newParams["payment_user_agent"] = Self.paymentUserAgent
        return newParams
    }
}
