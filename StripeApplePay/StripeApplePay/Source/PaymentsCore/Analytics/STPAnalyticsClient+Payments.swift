//
//  STPAnalyticsClient+Payments.swift
//  StripeApplePay
//
//  Created by David Estes on 1/24/22.
//

import Foundation
@_spi(STP) import StripeCore

/**
 An analytic specific to payments that serializes payment-specific
 information into its params.
 */
@_spi(STP) public protocol PaymentAnalytic: Analytic {
    var productUsage: Set<String> { get }
    var additionalParams: [String: Any] { get }
}

@_spi(STP) public extension PaymentAnalytic {
    var params: [String: Any] {
        var params = additionalParams

        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = STPAnalyticsClient.ocrTypeString()
        params["pay_var"] = STPAnalyticsClient.paymentsSDKVariant
        return params
    }
}

extension STPAnalyticsClient {
    @_spi(STP) public class func ocrTypeString() -> String {
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            // "STPCardScanner" is STPCardScanner.stp_analyticsIdentifier, but STPCardScanner only exists in Stripe.framework.
            if STPAnalyticsClient.sharedClient.productUsage.contains(
                "STPCardScanner")
            {
                return "stripe"
            }
        }
        return "none"
    }
    
    @_spi(STP) public static let paymentsSDKVariant: String = {
        if NSClassFromString("STPPaymentContext") != nil {
            // This is the full legacy Payments SDK, including Basic Integration.
            return "legacy"
        }
        
        // TODO (MOBILESDK-593): Add a value for the PaymentSheet-only SDK.
        
        // This is the Apple Pay-only SDK.
        return "applepay"
    }()
}
