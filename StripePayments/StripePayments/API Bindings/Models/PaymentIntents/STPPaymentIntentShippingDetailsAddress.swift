//
//  STPPaymentIntentShippingDetailsAddress.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Shipping address for a PaymentIntent's shipping details.
/// You cannot directly instantiate an `STPPaymentIntentShippingDetailsAddress`.
/// You should only use one that is part of an existing `STPPaymentMethod` object.
/// - seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping
public class STPPaymentIntentShippingDetailsAddress: NSObject {

    /// City/District/Suburb/Town/Village.
    @objc public let city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    @objc public let country: String?

    /// Address line 1 (Street address/PO Box/Company name).
    @objc public let line1: String?

    /// Address line 2 (Apartment/Suite/Unit/Building).
    @objc public let line2: String?

    /// ZIP or postal code.
    @objc public let postalCode: String?

    /// State/County/Province/Region.
    @objc public let state: String?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPPaymentIntentShippingDetailsAddress.self),
                self
            ),
            // Properties
            "line1 = \(String(describing: line1))",
            "line2 = \(String(describing: line2))",
            "city = \(String(describing: city))",
            "state = \(String(describing: state))",
            "postalCode = \(String(describing: postalCode))",
            "country = \(String(describing: country))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        city: String?,
        country: String?,
        line1: String?,
        line2: String?,
        postalCode: String?,
        state: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.city = city
        self.country = country
        self.line1 = line1
        self.line2 = line2
        self.postalCode = postalCode
        self.state = state
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPPaymentIntentShippingDetailsAddress: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response else {
            return nil
        }

        return STPPaymentIntentShippingDetailsAddress(
            city: dict["city"] as? String,
            country: dict["country"] as? String,
            line1: dict["line1"] as? String,
            line2: dict["line2"] as? String,
            postalCode: dict["postal_code"] as? String,
            state: dict["state"] as? String,
            allResponseFields: dict
        ) as? Self
    }

}
