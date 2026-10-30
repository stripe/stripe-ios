//
//  STPClientAttributionMetadata+Payments.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/4/25.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

// MARK: - STPFormEncodable
extension STPClientAttributionMetadata: STPFormEncodable {
    public static func rootObjectName() -> String? {
        return "client_attribution_metadata"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPClientAttributionMetadata.clientSessionId: "client_session_id",
            \STPClientAttributionMetadata.elementsSessionConfigId: "elements_session_config_id",
            \STPClientAttributionMetadata.checkoutSessionId: "checkout_session_id",
            \STPClientAttributionMetadata.checkoutConfigId: "checkout_config_id",
            \STPClientAttributionMetadata.merchantIntegrationAdditionalElements: "merchant_integration_additional_elements",
            \STPClientAttributionMetadata.merchantIntegrationSource: "merchant_integration_source",
            \STPClientAttributionMetadata.merchantIntegrationSubtype: "merchant_integration_subtype",
            \STPClientAttributionMetadata.merchantIntegrationVersion: "merchant_integration_version",
            \STPClientAttributionMetadata.paymentIntentCreationFlow: "payment_intent_creation_flow",
            \STPClientAttributionMetadata.paymentMethodSelectionFlow: "payment_method_selection_flow",
        ]
    }
}
