//
//  STPElementsSession.swift
//  StripePayments
//
//  Created by Nick Porter on 2/15/23.
//

import Foundation
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

    let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPElementsSession.self), self),
            "sessionID = \(sessionID)",
            "orderedPaymentMethodTypes = \(String(describing: orderedPaymentMethodTypes))",
            "unactivatedPaymentMethodTypes = \(String(describing: unactivatedPaymentMethodTypes))",
            "linkSettings = \(String(describing: linkSettings))",
            "countryCode = \(String(describing: countryCode))",
            "merchantCountryCode = \(String(describing: merchantCountryCode))",
            "paymentMethodSpecs = \(String(describing: paymentMethodSpecs))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        sessionID: String,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        merchantCountryCode: String?,
        linkSettings: LinkSettings?,
        paymentMethodSpecs: [[AnyHashable: Any]]?
    ) {
        self.allResponseFields = allResponseFields
        self.sessionID = sessionID
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        self.countryCode = countryCode
        self.merchantCountryCode = merchantCountryCode
        self.linkSettings = linkSettings
        self.paymentMethodSpecs = paymentMethodSpecs
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsSession: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let paymentMethodPrefDict = dict["payment_method_preference"] as? [AnyHashable: Any],
              let paymentMethodTypeStrings = paymentMethodPrefDict["ordered_payment_method_types"] as? [String],
              let sessionID = dict["session_id"] as? String
        else {
            return nil
        }
        let unactivatedPaymentMethodTypeStrings = dict["unactivated_payment_method_types"] as? [String] ?? []

        return STPElementsSession(
            allResponseFields: dict,
            sessionID: sessionID,
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            merchantCountryCode: dict["merchant_country"] as? String,
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
            ),
            paymentMethodSpecs: dict["payment_method_specs"] as? [[AnyHashable: Any]]
        ) as? Self
    }
}
