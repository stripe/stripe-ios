//
//  STPElementsSession.swift
//  StripePayments
//
//  Created by Nick Porter on 2/15/23.
//

import Foundation
@_spi(STP) import StripePayments

/// The response returned by v1/elements/sessions
@_spi(STP) public final class STPElementsSession: NSObject {

    /// The ordered payment method preference for this ElementsSession.
    public let orderedPaymentMethodTypes: [STPPaymentMethodType]

    /// A list of payment method types that are not activated in live mode, but activated in test mode.
    public let unactivatedPaymentMethodTypes: [STPPaymentMethodType]

    /// Link-specific settings for this ElementsSession.
    public let linkSettings: LinkSettings?

    /// Country code of the user.
    public let countryCode: String?

    /// A map describing payment method types form specs.
    public let paymentMethodSpecs: [[AnyHashable: Any]]?

    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPElementsSession.self), self),
            "orderedPaymentMethodTypes = \(String(describing: orderedPaymentMethodTypes))",
            "unactivatedPaymentMethodTypes = \(String(describing: unactivatedPaymentMethodTypes))",
            "linkSettings = \(String(describing: linkSettings))",
            "countryCode = \(String(describing: countryCode))",
            "paymentMethodSpecs = \(String(describing: paymentMethodSpecs))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        linkSettings: LinkSettings?,
        paymentMethodSpecs: [[AnyHashable: Any]]?
    ) {
        self.allResponseFields = allResponseFields
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        self.countryCode = countryCode
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
            let paymentMethodTypeStrings = paymentMethodPrefDict["ordered_payment_method_types"] as? [String]
        else {
            return nil
        }
        let unactivatedPaymentMethodTypeStrings = dict["unactivated_payment_method_types"] as? [String] ?? []

        return STPElementsSession(
            allResponseFields: dict,
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
            ),
            paymentMethodSpecs: dict["payment_method_specs"] as? [[AnyHashable: Any]]
        ) as? Self
    }

}
