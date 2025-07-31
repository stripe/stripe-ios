//
//  STPClientAttributionMetadata.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/31/25.
//

import Foundation
@_spi(STP) import StripeCore

// See https://docs.google.com/document/d/11wWdHwWzTJGe_29mHsk71fk-kG4lwvp8TLBBf4ws9JM/edit?usp=sharing
@objc @_spi(STP) public class STPClientAttributionMetadata: NSObject {
    
    public enum IntentCreationFlow: String {
        case standard
        case deferred
    }
    
    public enum PaymentMethodSelectionFlow: String {
        case automatic
        case merchantSpecified = "merchant_specified"
    }
    
    public var additionalAPIParameters: [AnyHashable: Any] = [:]
    
    /// The identifier string for the session
    @objc public let clientSessionId: String?
    /// The identifier string for the elements session
    @objc public var elementsSessionConfigId: String?
    /// The source for the merchant integration
    @objc public let merchantIntegrationSource: String
    /// The subtype for the merchant integration
    @objc public let merchantIntegrationSubtype: String
    /// The version for the merchant integration
    @objc public let merchantIntegrationVersion: String
    /// The intent creation flow for the merchant integration. Can be `standard` or `deferred`
    @objc public var paymentIntentCreationFlow: String?
    /// The payment method selection for the merchant integration. Can be `automatic` or `merchant_specified`
    @objc public var paymentMethodSelectionFlow: String?
    
    public init(elementsSessionConfigId: String? = nil,
                paymentIntentCreationFlow: IntentCreationFlow? = nil,
                paymentMethodSelectionFlow: PaymentMethodSelectionFlow? = nil) {
        self.clientSessionId = AnalyticsHelper.shared.sessionID
        self.elementsSessionConfigId = elementsSessionConfigId
        self.merchantIntegrationSource = "elements"
        self.merchantIntegrationSubtype = "mobile"
        self.merchantIntegrationVersion = "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)"
        self.paymentIntentCreationFlow = paymentIntentCreationFlow?.rawValue
        self.paymentMethodSelectionFlow = paymentMethodSelectionFlow?.rawValue
        super.init()
    }
}

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

// MARK: - Encodable
extension STPClientAttributionMetadata: Encodable {
    enum CodingKeys: String, CodingKey {
        case clientSessionId = "client_session_id"
        case elementsSessionConfigId = "elements_session_config_id"
        case merchantIntegrationSource = "merchant_integration_source"
        case merchantIntegrationSubtype = "merchant_integration_subtype"
        case merchantIntegrationVersion = "merchant_integration_version"
        case paymentIntentCreationFlow = "payment_intent_creation_flow"
        case paymentMethodSelectionFlow = "payment_method_selection_flow"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(clientSessionId, forKey: .clientSessionId)
        try container.encodeIfPresent(elementsSessionConfigId, forKey: .elementsSessionConfigId)
        try container.encode(merchantIntegrationSource, forKey: .merchantIntegrationSource)
        try container.encode(merchantIntegrationSubtype, forKey: .merchantIntegrationSubtype)
        try container.encode(merchantIntegrationVersion, forKey: .merchantIntegrationVersion)
        try container.encodeIfPresent(paymentIntentCreationFlow, forKey: .paymentIntentCreationFlow)
        try container.encodeIfPresent(paymentMethodSelectionFlow, forKey: .paymentMethodSelectionFlow)
    }
}
