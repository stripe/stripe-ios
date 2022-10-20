//
//  CardBrand.swift
//  StripeApplePay
//
//  Created by David Estes on 4/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension StripeAPI {
    /// The various card brands to which a payment card can belong.
    enum CardBrand: String, SafeEnumCodable {
        /// Visa card
        case visa = "Visa"
        /// American Express card
        case amex = "American Express"
        /// Mastercard card
        case mastercard = "MasterCard"
        /// Discover card
        case discover = "Discover"
        /// JCB card
        case JCB = "JCB"
        /// Diners Club card
        case dinersClub = "Diners Club"
        /// UnionPay card
        case unionPay = "UnionPay"
        /// An unknown card brand type
        case unknown = "Unknown"
        /// An unparsable card brand
        case unparsable
    }
}
