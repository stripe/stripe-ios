//
//  STPPaymentIntentShippingDetailsAddressParams.swift
//  Stripe
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
    @objc public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    @objc public var country: String?

    /// Address line 1 (Street address/PO Box/Company name).
    @objc public var line1: String

    /// Address line 2 (Apartment/Suite/Unit/Building).
    @objc public var line2: String?

    /// ZIP or postal code.
    @objc public var postalCode: String?

    /// State/County/Province/Region.
    @objc public var state: String?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize an `STPPaymentIntentShippingDetailsAddressParams` instance with required properties.
    @objc
    public init(line1: String) {
        self.line1 = line1
        super.init()
    }

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPPaymentIntentShippingDetailsAddressParams.self), self
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

}

// MARK: - STPFormEncodable
extension STPPaymentIntentShippingDetailsAddressParams: STPFormEncodable {

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:line1)): "line1",
            NSStringFromSelector(#selector(getter:line2)): "line2",
            NSStringFromSelector(#selector(getter:city)): "city",
            NSStringFromSelector(#selector(getter:country)): "country",
            NSStringFromSelector(#selector(getter:state)): "state",
            NSStringFromSelector(#selector(getter:CNMutablePostalAddress.postalCode)):
                "postal_code",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

}

// MARK: - NSCopying
extension STPPaymentIntentShippingDetailsAddressParams: NSCopying {
    /// :nodoc:
    @objc
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
