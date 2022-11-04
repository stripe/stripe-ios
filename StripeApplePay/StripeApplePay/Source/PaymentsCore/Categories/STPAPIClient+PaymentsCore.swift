//
//  STPAPIClient+PaymentsCore.swift
//  StripeApplePay
//
//  Created by David Estes on 1/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    @_spi(STP) public class func paramsAddingPaymentUserAgent(
        _ params: [String: Any]
    ) -> [String: Any] {
        var newParams = params
        newParams["payment_user_agent"] = PaymentsSDKVariant.paymentUserAgent
        return newParams
    }
}
