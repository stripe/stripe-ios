//
//  STPAPIClient+PaymentsCore.swift
//  StripePayments
//
//  Created by David Estes on 1/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {

    /// - Parameter additionalValues: A list of values to append to the `payment_user_agent`. e.g. `["deferred-intent", "autopm"]` will append "; deferred-intent; autopm" to the `payment_user_agent`.
    @_spi(STP) public class func paramsAddingPaymentUserAgent(
        _ params: [String: Any],
        additionalValues: [String] = []
    ) -> [String: Any] {
        var newParams = params
        newParams["payment_user_agent"] = ([PaymentsSDKVariant.paymentUserAgent] + additionalValues).joined(separator: "; ")
        return newParams
    }

    @_spi(STP) public class func paramsAddingClientAttributionMetadata(
        _ params: [String: Any],
        additionalClientAttributionMetadata: [String: String] = [:]
    ) -> [String: Any] {
        var newParams = params
        newParams["client_attribution_metadata"] = ["client_session_id": AnalyticsHelper.shared.sessionID]
            .merging(PaymentsSDKVariant.clientAttributionMetadata){ _, new in new}
            .merging(additionalClientAttributionMetadata) { _, new in new}
        return newParams
    }
}
