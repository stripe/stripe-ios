//
//  STPClientAttributionMetadata+Payments.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/4/25.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - STPFormEncodable
extension STPClientAttributionMetadata: STPFormEncodable {
    public static func rootObjectName() -> String? {
        return "client_attribution_metadata"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: clientSessionId)): "client_session_id",
            NSStringFromSelector(#selector(getter: elementsSessionConfigId)): "elements_session_config_id",
            NSStringFromSelector(#selector(getter: merchantIntegrationSource)): "merchant_integration_source",
            NSStringFromSelector(#selector(getter: merchantIntegrationSubtype)): "merchant_integration_subtype",
            NSStringFromSelector(#selector(getter: merchantIntegrationVersion)): "merchant_integration_version",
            NSStringFromSelector(#selector(getter: paymentIntentCreationFlow)): "payment_intent_creation_flow",
            NSStringFromSelector(#selector(getter: paymentMethodSelectionFlow)): "payment_method_selection_flow",
        ]
    }
}
