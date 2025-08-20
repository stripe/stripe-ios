//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import StripePayments

extension String.Localized {
    static var debitIsMostLikelyToBeAccepted: String {
        return STPLocalizedString(
            "Debit cards are most likely to be accepted.",
            "Label shown in the Link UI indicating that debit cards are more likely to be accepted"
        )
    }

    static func redactedCardDetails(using card: STPPaymentMethodCard) -> String? {
        let brand = STPCard.string(from: card.brand)
        guard !brand.isEmpty, let last4 = card.last4 else {
            return nil
        }

        return String(format: card_details_xxxx, brand, last4)
    }
}
