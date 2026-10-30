//
//  STPPaymentMethodCardParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The user's card details.
public class STPPaymentMethodCardParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// A convenience initializer for creating a payment method from a card source.
    /// This should be used to help with migrations to Payment Methods from Sources.
    public convenience init(
        cardSourceParams: STPCardParams
    ) {
        self.init()
        number = cardSourceParams.number
        expMonth = NSNumber(value: cardSourceParams.expMonth)
        expYear = NSNumber(value: cardSourceParams.expYear)
        cvc = cardSourceParams.cvc
    }

    /// Initializes an empty STPPaymentMethodCardParams.
    public required override init() {
        super.init()
    }

    /// The card number, as a string without any separators. Ex. @"4242424242424242"
    public var number: String?
    /// Number representing the card's expiration month. Ex. @1
    public var expMonth: NSNumber?
    /// Two- or four-digit number representing the card's expiration year.
    public var expYear: NSNumber?
    /// For backwards compatibility, you can alternatively set this as a Stripe token (e.g., for apple pay)
    public var token: String?
    /// Card security code. It is highly recommended to always include this value.
    public var cvc: String?
    /// Information about the networks to use with this payment method.
    public var networks: STPPaymentMethodCardNetworksParams?

    /// The last 4 digits of the card.
    public var last4: String? {
        if number != nil && (number?.count ?? 0) >= 4 {
            return (number as NSString?)?.substring(from: (number?.count ?? 0) - 4) ?? ""
        } else {
            return ""
        }
    }

    // MARK: - Description
    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardParams.self), self),
            // Basic card details
            "last4 = \(last4 ?? "")",
            "expMonth = \(expMonth ?? 0)",
            "expYear = \(expYear ?? 0)",
            "cvc = \(((cvc) != nil ? "<redacted>" : nil) ?? "")",
            "networks = \(networks?.description ?? "")",
            // Token
            "token = \(token ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    public class func rootObjectName() -> String? {
        return "card"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodCardParams.number: "number",
            \STPPaymentMethodCardParams.expMonth: "exp_month",
            \STPPaymentMethodCardParams.expYear: "exp_year",
            \STPPaymentMethodCardParams.cvc: "cvc",
            \STPPaymentMethodCardParams.token: "token",
            \STPPaymentMethodCardParams.networks: "networks",
        ]
    }

    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copyCardParams = type(of: self).init()

        copyCardParams.number = number
        copyCardParams.expMonth = expMonth
        copyCardParams.expYear = expYear
        copyCardParams.cvc = cvc
        copyCardParams.networks = networks
        return copyCardParams
    }

    // MARK: - Equality
    /// :nodoc:
    public override func isEqual(_ other: Any?) -> Bool {
        return isEqual(to: other as? STPPaymentMethodCardParams)
    }

    func isEqual(to other: STPPaymentMethodCardParams?) -> Bool {
        if self === other {
            return true
        }

        if other == nil || !(other != nil) {
            return false
        }

        if let other = other,
            !((additionalAPIParameters as NSDictionary).isEqual(to: other.additionalAPIParameters))
        {
            return false
        }

        return number == other?.number && expMonth == other?.expMonth && expYear == other?.expYear
            && cvc == other?.cvc && token == other?.token && networks?.preferred == other?.networks?.preferred
    }
}
