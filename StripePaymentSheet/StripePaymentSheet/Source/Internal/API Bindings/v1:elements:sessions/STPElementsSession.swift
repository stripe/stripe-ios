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
        isApplePayEnabled: Bool
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
            isApplePayEnabled: true
        )
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsSession: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        // Required fields:
        guard let dict = response,
              let paymentMethodPrefDict = dict["payment_method_preference"] as? [AnyHashable: Any],
              let paymentMethodTypeStrings = paymentMethodPrefDict["ordered_payment_method_types"] as? [String],
              let sessionID = dict["session_id"] as? String,
              let applePayPreference = dict["apple_pay_preference"] as? String
        else {
            return nil
        }
        let isApplePayEnabled = applePayPreference != "disabled"

        // Optional fields:
        let unactivatedPaymentMethodTypeStrings = dict["unactivated_payment_method_types"] as? [String] ?? []
        let cardBrandChoice = STPCardBrandChoice.decodedObject(fromAPIResponse: dict["card_brand_choice"] as? [AnyHashable: Any])

        return self.init(
            allResponseFields: dict,
            sessionID: sessionID,
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            merchantCountryCode: dict["merchant_country"] as? String,
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
            ),
            paymentMethodSpecs: dict["payment_method_specs"] as? [[AnyHashable: Any]],
            cardBrandChoice: cardBrandChoice,
            isApplePayEnabled: isApplePayEnabled
        )
    }
}
