//
//  STPPaymentMethodNgCard.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// A Naira card Payment Method.
/// - seealso: https://docs.stripe.com/payments/ng-card/accept-a-payment?payment-ui=direct-api
public class STPPaymentMethodNgCard: NSObject, STPAPIResponseDecodable {
    /// The local credit or debit card brand.
    @objc public private(set) var brand: STPPaymentMethodNgCardBrand = .unknown
    /// The last four digits of the card.
    @objc public private(set) var last4: String?
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodNgCard.self), self),
            "brand = \(brand.stringValue ?? "")",
            "last4 = \(last4 ?? "")",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    @objc public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }
        return self.init(dictionary: response.stp_dictionaryByRemovingNulls())
    }

    required init(dictionary: [AnyHashable: Any]) {
        brand = STPPaymentMethodNgCardBrand(string: dictionary.stp_string(forKey: "brand"))
        last4 = dictionary.stp_string(forKey: "last4")
        super.init()
        allResponseFields = dictionary
    }
}

/// The local brand of a Naira card Payment Method.
@objc public enum STPPaymentMethodNgCardBrand: Int {
    /// An unknown card brand.
    case unknown
    case amex
    case mastercard
    case verve
    case visa

    @_spi(STP) public init(string: String?) {
        switch string?.lowercased() {
        case "amex": self = .amex
        case "mastercard": self = .mastercard
        case "verve": self = .verve
        case "visa": self = .visa
        default: self = .unknown
        }
    }

    @_spi(STP) public var stringValue: String? {
        switch self {
        case .unknown: return nil
        case .amex: return "amex"
        case .mastercard: return "mastercard"
        case .verve: return "verve"
        case .visa: return "visa"
        }
    }
}
