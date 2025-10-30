//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension String.Localized {
    static var debitIsMostLikelyToBeAccepted: String {
        return STPLocalizedString("ec924",
            "Label shown in the Link UI indicating that debit cards are more likely to be accepted"
        )
    }

    static func redactedCardDetails(using card: StripeAPI.PaymentMethod.Card) -> String? {
        let brand = stpCardBrand(from: card.brand)
        let brandString = STPCard.string(from: brand)
        guard !brandString.isEmpty, let last4 = card.last4 else {
            return nil
        }

        return String(format: card_details_xxxx, brandString, last4)
    }

    private static func stpCardBrand(from brand: StripeAPI.PaymentMethod.Card.Brand) -> STPCardBrand {
        switch brand {
        case .visa: return .visa
        case .amex: return .amex
        case .mastercard: return .mastercard
        case .discover: return .discover
        case .jcb: return .JCB
        case .diners: return .dinersClub
        case .unionpay: return .unionPay
        case .unknown, .unparsable: return .unknown
        }
    }
}
