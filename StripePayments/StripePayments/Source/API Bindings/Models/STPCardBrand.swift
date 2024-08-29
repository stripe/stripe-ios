//
//  STPCardBrand.swift
//  StripePayments
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation

/// The various card brands to which a payment card can belong.
@objc public enum STPCardBrand: Int {
    /// Visa card
    case visa
    /// American Express card
    case amex
    /// Mastercard card
    case mastercard
    /// Discover card
    case discover
    /// JCB card
    case JCB
    /// Diners Club card
    case dinersClub
    /// UnionPay card
    case unionPay
    /// Cartes Bancaires
    case cartesBancaires
    /// An unknown card brand type
    case unknown
}

/// :nodoc:
extension STPCardBrand: CaseIterable, Codable {
    // intentionally empty
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "STPStringFromCardBrand has been replaced with STPCardBrandUtilities.stringFrom(brand)"
)
@objc public class STPStringFromCardBrand: NSObject {
}

/// Contains `STPStringFromCardBrand`
public class STPCardBrandUtilities: NSObject {
    /// Returns a string representation for the provided card brand;
    /// i.e. `STPCardBrandUtilities.stringFrom(brand: .visa) == "Visa"`.
    /// - Parameter brand: the brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for displaying to a user.
    @objc(stringFromCardBrand:) public static func stringFrom(_ brand: STPCardBrand) -> String? {
        switch brand {
        case .amex:
            return "American Express"
        case .dinersClub:
            return "Diners Club"
        case .discover:
            return "Discover"
        case .JCB:
            return "JCB"
        case .mastercard:
            return "Mastercard"
        case .unionPay:
            return "UnionPay"
        case .visa:
            return "Visa"
        case .cartesBancaires:
            return "Cartes Bancaires"
        case .unknown:
            return "Unknown"
        }
    }

    /// Returns brand API string value from given card brand.
    ///
    /// - Parameter brand: The `STPCardBrand` to transform into a string.
    /// - Returns: A `String` representing the card brand. This could be "visa",
    @objc(apiValueFromCardBrand:) public static func apiValue(from brand: STPCardBrand) -> String {
        switch brand {
        case .visa:
            return "visa"
        case .amex:
            return "american_express"
        case .mastercard:
            return "mastercard"
        case .discover:
            return "discover"
        case .JCB:
            return "jcb"
        case .dinersClub:
            return "diners_club"
        case .unionPay:
            return "unionpay"
        case .cartesBancaires:
            return "cartes_bancaires"
        default:
            return "unknown"
        }
    }

}

extension STPCardBrand: Comparable {
    public static func < (lhs: StripePayments.STPCardBrand, rhs: StripePayments.STPCardBrand) -> Bool {
        return (STPCardBrandUtilities.stringFrom(lhs) ?? "") < (STPCardBrandUtilities.stringFrom(rhs) ?? "")
    }
}
