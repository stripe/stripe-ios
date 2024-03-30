//
//  STPAnalyticsClient+Payments.swift
//  StripeApplePay
//
//  Created by David Estes on 1/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// An analytic specific to payments that serializes payment-specific
/// information into its params.
@_spi(STP) public protocol PaymentAnalytic: Analytic {
    var additionalParams: [String: Any] { get }
}

@_spi(STP) extension PaymentAnalytic {
    public var params: [String: Any] {
        var params = additionalParams

        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = PaymentsSDKVariant.ocrTypeString
        params["pay_var"] = PaymentsSDKVariant.variant
        return params
    }
}
