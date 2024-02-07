//
//  STPElementsSession.swift
//  StripePayments
//
//  Created by Nick Porter on 2/15/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The response returned by v1/elements/sessions
final class STPElementsSession: NSObject {
    #if DEBUG && targetEnvironment(simulator)
    public static let countryCodeOverride: String? = nil
    #endif
    /// Elements Session ID for analytics purposes, looks like "elements_session_1234"
    let sessionID: String

    /// The ordered payment method preference for this ElementsSession.
    let orderedPaymentMethodTypes: [STPPaymentMethodType]

    /// A list of payment method types that are not activated in live mode, but activated in test mode.
    let unactivatedPaymentMethodTypes: [STPPaymentMethodType]

    /// Link-specific settings for this ElementsSession.
    let linkSettings: LinkSettings?

    /// Country code of the user.
    let countryCode: String?

    /// Country code of the merchant.
    let merchantCountryCode: String?

    /// A map describing payment method types form specs.
    let paymentMethodSpecs: [[AnyHashable: Any]]?

    /// Card brand choice settings for the merchant.
    let cardBrandChoice: STPCardBrandChoice?

    let isApplePayEnabled: Bool

    /// An ordered list of external payment methods to display
    let externalPaymentMethods: [ExternalPaymentMethod]

    let allResponseFields: [AnyHashable: Any]

    private init(
        allResponseFields: [AnyHashable: Any],
        sessionID: String,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        merchantCountryCode: String?,
        linkSettings: LinkSettings?,
        paymentMethodSpecs: [[AnyHashable: Any]]?,
        cardBrandChoice: STPCardBrandChoice?,
        isApplePayEnabled: Bool,
        externalPaymentMethods: [ExternalPaymentMethod]
    ) {
        self.allResponseFields = allResponseFields
        self.sessionID = sessionID
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        self.countryCode = countryCode
        self.merchantCountryCode = merchantCountryCode
        self.linkSettings = linkSettings
        self.paymentMethodSpecs = paymentMethodSpecs
        self.cardBrandChoice = cardBrandChoice
        self.isApplePayEnabled = isApplePayEnabled
        self.externalPaymentMethods = externalPaymentMethods
        super.init()
    }

    /// Returns a "best effort" STPElementsSessions object to be used as a last resort fallback if the endpoint failed to return a response or we failed to parse it.
    static func makeBackupElementsSession(with paymentIntent: STPPaymentIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: paymentIntent.allResponseFields,
            paymentMethodTypes: paymentIntent.paymentMethodTypes.map { STPPaymentMethodType.init(rawValue: $0.intValue) ?? .unknown }
        )
    }

    static func makeBackupElementsSession(with setupIntent: STPSetupIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: setupIntent.allResponseFields,
            paymentMethodTypes: setupIntent.paymentMethodTypes.map { STPPaymentMethodType.init(rawValue: $0.intValue) ?? .unknown }
        )
    }

    /// Returns a "best effort" STPElementsSessions object to be used as a last resort fallback if the endpoint failed to return a response or we failed to parse it.
    static func makeBackupElementsSession(allResponseFields: [AnyHashable: Any], paymentMethodTypes: [STPPaymentMethodType]) -> STPElementsSession {
        return STPElementsSession(
            allResponseFields: allResponseFields,
            sessionID: UUID().uuidString,
            orderedPaymentMethodTypes: paymentMethodTypes,
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            linkSettings: nil,
            paymentMethodSpecs: nil,
            cardBrandChoice: STPCardBrandChoice.decodedObject(fromAPIResponse: [:]),
            isApplePayEnabled: true,
            externalPaymentMethods: []
        )
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsSession: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        // Required fields:
        guard let response,
              let paymentMethodPrefDict = response["payment_method_preference"] as? [AnyHashable: Any],
              let paymentMethodTypeStrings = paymentMethodPrefDict["ordered_payment_method_types"] as? [String],
              let sessionID = response["session_id"] as? String
        else {
            return nil
        }

        // Optional fields:
        let unactivatedPaymentMethodTypeStrings = response["unactivated_payment_method_types"] as? [String] ?? []
        let cardBrandChoice = STPCardBrandChoice.decodedObject(fromAPIResponse: response["card_brand_choice"] as? [AnyHashable: Any])
        let applePayPreference = response["apple_pay_preference"] as? String
        let isApplePayEnabled = applePayPreference != "disabled"
        let externalPaymentMethods: [ExternalPaymentMethod] = {
            let externalPaymentMethodDataKey = "external_payment_method_data"
            guard response[externalPaymentMethodDataKey] != nil, !(response[externalPaymentMethodDataKey] is NSNull) else {
                return []
            }
            guard
                let epmsJSON = response[externalPaymentMethodDataKey] as? [[AnyHashable: Any]],
                let epms = ExternalPaymentMethod.decoded(fromAPIResponse: epmsJSON)
            else {
                // We don't want to fail the entire v1/elements/sessions request if we fail to parse external_payment_methods_data
                // Instead, fall back to an empty array and log an error.
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionEPMLoadFailed)
                return []
            }
            return epms
        }()

        return self.init(
            allResponseFields: response,
            sessionID: sessionID,
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            merchantCountryCode: response["merchant_country"] as? String,
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: response["link_settings"] as? [AnyHashable: Any]
            ),
            paymentMethodSpecs: response["payment_method_specs"] as? [[AnyHashable: Any]],
            cardBrandChoice: cardBrandChoice,
            isApplePayEnabled: isApplePayEnabled,
            externalPaymentMethods: externalPaymentMethods
        )
    }
}
