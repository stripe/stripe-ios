//
//  STPPaymentIntentShippingDetails.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Shipping information for a PaymentIntent
/// You cannot directly instantiate an `STPPaymentIntentShippingDetails`.
/// You should only use one that is part of an existing `STPPaymentMethod` object.
/// - seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping
public class STPPaymentIntentShippingDetails: NSObject {

    /// Shipping address.
    @objc public let address: STPPaymentIntentShippingDetailsAddress?

    /// Recipient name.
    @objc public let name: String?

    /// The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
    @objc public let carrier: String?

    /// Recipient phone (including extension).
    @objc public let phone: String?

    /// The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
    @objc public let trackingNumber: String?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentIntentShippingDetails.self), self),
            // Properties
            "address = \(String(describing: address))",
            "name = \(String(describing: name))",
            "carrier = \(String(describing: carrier))",
            "phone = \(String(describing: phone))",
            "trackingNumber = \(String(describing: trackingNumber))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        address: STPPaymentIntentShippingDetailsAddress?,
        name: String?,
        carrier: String?,
        phone: String?,
        trackingNumber: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.address = address
        self.name = name
        self.carrier = carrier
        self.phone = phone
        self.trackingNumber = trackingNumber
        self.allResponseFields = allResponseFields
        super.init()
    }

}

// MARK: - STPAPIResponseDecodable
extension STPPaymentIntentShippingDetails: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response else {
            return nil
        }

        return STPPaymentIntentShippingDetails(
            address: STPPaymentIntentShippingDetailsAddress.decodedObject(
                fromAPIResponse: dict["address"] as? [AnyHashable: Any]),
            name: dict["name"] as? String,
            carrier: dict["carrier"] as? String,
            phone: dict["phone"] as? String,
            trackingNumber: dict["tracking_number"] as? String,
            allResponseFields: dict) as? Self
    }

}
