//
//  STPPaymentIntentShippingDetailsParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Shipping information for a PaymentIntent
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-shipping
public class STPPaymentIntentShippingDetailsParams: NSObject {

    /// Shipping address.
    public var address: STPPaymentIntentShippingDetailsAddressParams

    /// Recipient name.
    public var name: String

    /// The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
    public var carrier: String?

    /// Recipient phone (including extension).
    public var phone: String?

    /// The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
    public var trackingNumber: String?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize an `STPPaymentIntentShippingDetailsParams` with required properties.
    public init(
        address: STPPaymentIntentShippingDetailsAddressParams,
        name: String
    ) {
        self.address = address
        self.name = name
        super.init()

    }

    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPPaymentIntentShippingDetailsParams.self),
                self
            ),
            // Properties
            "address = \(address)",
            "name = \(name)",
            "carrier = \(String(describing: carrier))",
            "phone = \(String(describing: phone))",
            "trackingNumber = \(String(describing: trackingNumber))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return other.name == name && other.carrier == carrier && other.phone == phone
            && other.trackingNumber == trackingNumber && other.address == address
    }
}

// MARK: - STPFormEncodable
extension STPPaymentIntentShippingDetailsParams: STPFormEncodable {

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentIntentShippingDetailsParams.address: "address",
            \STPPaymentIntentShippingDetailsParams.name: "name",
            \STPPaymentIntentShippingDetailsParams.carrier: "carrier",
            \STPPaymentIntentShippingDetailsParams.phone: "phone",
            \STPPaymentIntentShippingDetailsParams.trackingNumber: "tracking_number",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }

}

// MARK: - NSCopying
extension STPPaymentIntentShippingDetailsParams: NSCopying {
    /// :nodoc:
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = STPPaymentIntentShippingDetailsParams(address: address, name: name)

        copy.carrier = carrier
        copy.phone = phone
        copy.trackingNumber = trackingNumber
        copy.additionalAPIParameters = additionalAPIParameters

        return copy
    }

}
