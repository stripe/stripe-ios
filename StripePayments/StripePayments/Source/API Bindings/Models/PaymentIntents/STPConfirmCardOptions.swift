//
//  STPConfirmCardOptions.swift
//  StripePayments
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Options to update a Card PaymentMethod during PaymentIntent confirmation.
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-card
public class STPConfirmCardOptions: NSObject {

    /// CVC value with which to update the Card PaymentMethod.
    @objc public var cvc: String?

    /// Selected network to process this PaymentIntent on. Depends on the available networks of the card attached to the PaymentIntent. Can be only set confirm-time.
    @objc public var network: String?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "cvc = \(String(describing: cvc))",
            "network = \(String(describing: network))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

}

// MARK: - STPFormEncodable
extension STPConfirmCardOptions: STPFormEncodable {

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: cvc)): "cvc",
            NSStringFromSelector(#selector(getter: network)): "network",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "card"
    }
}
