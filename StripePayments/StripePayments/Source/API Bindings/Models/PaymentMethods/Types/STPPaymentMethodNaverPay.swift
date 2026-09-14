//
//  STPPaymentMethodNaverPay.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Naver Pay Payment Method.
/// - seealso: https://docs.stripe.com/payments/naver-pay/accept-a-payment
public class STPPaymentMethodNaverPay: NSObject, STPAPIResponseDecodable {
    /// Uniquely identifies this Naver Pay account.
    @objc public private(set) var buyerId: String?
    /// Whether the transaction is funded with a card or Naver Pay points.
    @objc public private(set) var funding: STPPaymentMethodNaverPayFunding = .unknown
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodNaverPay.self), self),
            "buyerId = \(buyerId ?? "")",
            "funding = \(funding.stringValue ?? "")",
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
        buyerId = dictionary.stp_string(forKey: "buyer_id")
        funding = STPPaymentMethodNaverPayFunding(string: dictionary.stp_string(forKey: "funding"))
        super.init()
        allResponseFields = dictionary
    }
}

/// The source used to fund a Naver Pay Payment Method.
@objc public enum STPPaymentMethodNaverPayFunding: Int {
    /// An unknown funding source.
    case unknown
    /// A card.
    case card
    /// Naver Pay points.
    case points

    @_spi(STP) public init(string: String?) {
        switch string?.lowercased() {
        case "card":
            self = .card
        case "points":
            self = .points
        default:
            self = .unknown
        }
    }

    @_spi(STP) public var stringValue: String? {
        switch self {
        case .unknown:
            return nil
        case .card:
            return "card"
        case .points:
            return "points"
        }
    }
}
