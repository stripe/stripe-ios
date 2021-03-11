//
//  STPPaymentIntentShippingDetailsParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Shipping information for a PaymentIntent
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-shipping
public class STPPaymentIntentShippingDetailsParams: NSObject {

    /// Shipping address.
    @objc public var address: STPPaymentIntentShippingDetailsAddressParams

    /// Recipient name.
    @objc public var name: String

    /// The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
    @objc public var carrier: String?

    /// Recipient phone (including extension).
    @objc public var phone: String?

    /// The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
    @objc public var trackingNumber: String?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize an `STPPaymentIntentShippingDetailsParams` with required properties.
    @objc
    public init(address: STPPaymentIntentShippingDetailsAddressParams, name: String) {
        self.address = address
        self.name = name
        super.init()

    }

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p", NSStringFromClass(STPPaymentIntentShippingDetailsParams.self),
                self),
            // Properties
            "address = \(address)",
            "name = \(name)",
            "carrier = \(String(describing: carrier))",
            "phone = \(String(describing: phone))",
            "trackingNumber = \(String(describing: trackingNumber))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

}

// MARK: - STPFormEncodable
extension STPPaymentIntentShippingDetailsParams: STPFormEncodable {

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:address)): "address",
            NSStringFromSelector(#selector(getter:name)): "name",
            NSStringFromSelector(#selector(getter:carrier)): "carrier",
            NSStringFromSelector(#selector(getter:phone)): "phone",
            NSStringFromSelector(#selector(getter:trackingNumber)): "tracking_number",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

}

// MARK: - NSCopying
extension STPPaymentIntentShippingDetailsParams: NSCopying {
    /// :nodoc:
    @objc
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = STPPaymentIntentShippingDetailsParams(address: address, name: name)

        copy.carrier = carrier
        copy.phone = phone
        copy.trackingNumber = trackingNumber
        copy.additionalAPIParameters = additionalAPIParameters

        return copy
    }

}
