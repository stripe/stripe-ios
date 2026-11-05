//
//  STPPaymentIntentShippingDetailsAddressParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation

/// Shipping address for a PaymentIntent's shipping details.
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-shipping-address
public class STPPaymentIntentShippingDetailsAddressParams: NSObject {

    /// City/District/Suburb/Town/Village.
    public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    public var country: String?

    /// Address line 1 (Street address/PO Box/Company name).
    public var line1: String

    /// Address line 2 (Apartment/Suite/Unit/Building).
    public var line2: String?

    /// ZIP or postal code.
    public var postalCode: String?

    /// State/County/Province/Region.
    public var state: String?

    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize an `STPPaymentIntentShippingDetailsAddressParams` instance with required properties.
    public init(
        line1: String
    ) {
        self.line1 = line1
        super.init()
    }

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPPaymentIntentShippingDetailsAddressParams.self),
                self
            ),
            // Properties
            "line1 = \(line1)",
            "line2 = \(String(describing: line2))",
            "city = \(String(describing: city))",
            "state = \(String(describing: state))",
            "postalCode = \(String(describing: postalCode))",
            "country = \(String(describing: country))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return other.city == city && other.country == country && other.line1 == line1
            && other.line2 == line2 && other.postalCode == postalCode && other.state == state
    }
}

// MARK: - STPFormEncodable
extension STPPaymentIntentShippingDetailsAddressParams: STPFormEncodable {

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentIntentShippingDetailsAddressParams.line1: "line1",
            \STPPaymentIntentShippingDetailsAddressParams.line2: "line2",
            \STPPaymentIntentShippingDetailsAddressParams.city: "city",
            \STPPaymentIntentShippingDetailsAddressParams.country: "country",
            \STPPaymentIntentShippingDetailsAddressParams.state: "state",
            \STPPaymentIntentShippingDetailsAddressParams.postalCode:
                "postal_code",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }

}

// MARK: - NSCopying
extension STPPaymentIntentShippingDetailsAddressParams: NSCopying {
    /// :nodoc:
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = STPPaymentIntentShippingDetailsAddressParams(line1: line1)

        copy.line1 = line1
        copy.line2 = line2
        copy.city = city
        copy.country = country
        copy.state = state
        copy.postalCode = postalCode
        copy.additionalAPIParameters = additionalAPIParameters

        return copy
    }

}
