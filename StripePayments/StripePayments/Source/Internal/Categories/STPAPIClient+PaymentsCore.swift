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
        elementsSessionConfigId: String?,
        paymentIntentCreationFlow: String?,
        paymentMethodSelectionFlow: String?
    ) -> [String: Any] {
        var newParams = params
        var clientAttributionMetadataDict: [String: Any] = [:]
        clientAttributionMetadataDict["client_session_id"] = AnalyticsHelper.shared.sessionID
        clientAttributionMetadataDict["elements_session_config_id"] = elementsSessionConfigId
        clientAttributionMetadataDict["merchant_integration_source"] = "elements"
        clientAttributionMetadataDict["merchant_integration_subtype"] = "mobile"
        clientAttributionMetadataDict["merchant_integration_version"] = "stripe-ios/\(STPAPIClient.STPSDKVersion)"
        clientAttributionMetadataDict["payment_intent_creation_flow"] = paymentIntentCreationFlow
        clientAttributionMetadataDict["payment_method_selection_flow"] = paymentMethodSelectionFlow
        newParams["client_attribution_metadata"] = clientAttributionMetadataDict
        return newParams
    }
}
