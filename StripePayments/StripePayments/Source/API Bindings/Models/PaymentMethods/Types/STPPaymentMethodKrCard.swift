//
//  STPPaymentMethodKrCard.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Korean cards Payment Method.
/// - seealso: https://docs.stripe.com/payments/kr-card/accept-a-payment?payment-ui=direct-api
public class STPPaymentMethodKrCard: NSObject, STPAPIResponseDecodable {
    /// The local credit or debit card brand.
    @objc public private(set) var brand: STPPaymentMethodKrCardBrand = .unknown
    /// The last four digits of the card. This may not be present for American Express cards.
    @objc public private(set) var last4: String?
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodKrCard.self), self),
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
        brand = STPPaymentMethodKrCardBrand(string: dictionary.stp_string(forKey: "brand"))
        last4 = dictionary.stp_string(forKey: "last4")
        super.init()
        allResponseFields = dictionary
    }
}

/// The local brand of a Korean cards Payment Method.
@objc public enum STPPaymentMethodKrCardBrand: Int {
    /// An unknown card brand.
    case unknown
    case bc
    case citi
    case hana
    case hyundai
    case jeju
    case jeonbuk
    case kakaoBank
    case kBank
    case kdbBank
    case kookmin
    case kwangju
    case lotte
    case mg
    case nh
    case post
    case samsung
    case savingsBank
    case shinhan
    case shinhyup
    case suhyup
    case tossBank
    case woori

    @_spi(STP) public init(string: String?) {
        switch string?.lowercased() {
        case "bc": self = .bc
        case "citi": self = .citi
        case "hana": self = .hana
        case "hyundai": self = .hyundai
        case "jeju": self = .jeju
        case "jeonbuk": self = .jeonbuk
        case "kakaobank": self = .kakaoBank
        case "kbank": self = .kBank
        case "kdbbank": self = .kdbBank
        case "kookmin": self = .kookmin
        case "kwangju": self = .kwangju
        case "lotte": self = .lotte
        case "mg": self = .mg
        case "nh": self = .nh
        case "post": self = .post
        case "samsung": self = .samsung
        case "savingsbank": self = .savingsBank
        case "shinhan": self = .shinhan
        case "shinhyup": self = .shinhyup
        case "suhyup": self = .suhyup
        case "tossbank": self = .tossBank
        case "woori": self = .woori
        default: self = .unknown
        }
    }

    @_spi(STP) public var stringValue: String? {
        switch self {
        case .unknown: return nil
        case .bc: return "bc"
        case .citi: return "citi"
        case .hana: return "hana"
        case .hyundai: return "hyundai"
        case .jeju: return "jeju"
        case .jeonbuk: return "jeonbuk"
        case .kakaoBank: return "kakaobank"
        case .kBank: return "kbank"
        case .kdbBank: return "kdbbank"
        case .kookmin: return "kookmin"
        case .kwangju: return "kwangju"
        case .lotte: return "lotte"
        case .mg: return "mg"
        case .nh: return "nh"
        case .post: return "post"
        case .samsung: return "samsung"
        case .savingsBank: return "savingsbank"
        case .shinhan: return "shinhan"
        case .shinhyup: return "shinhyup"
        case .suhyup: return "suhyup"
        case .tossBank: return "tossbank"
        case .woori: return "woori"
        }
    }
}
