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
        clientAttributionMetadata: STPClientAttributionMetadata
    ) -> [String: Any] {
        stpAssert(
            params["client_attribution_metadata"] == nil,
            "Overwriting existing client_attribution_metadata"
        )
        var newParams = params
        do {
            newParams["client_attribution_metadata"] = try clientAttributionMetadata.encodeJSONDictionary()
        } catch {
            stpAssertionFailure("Could not encode clientAttributionMetadata to JSON: \(error)")
        }
        return newParams
    }
}
