//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

@_spi(STP) extension String.Localized {
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

        let formattedMessage = STPLocalizedString(
            "%1$@ •••• %2$@",
            "Card preview details displaying the last four digits: {card brand} •••• {last 4} e.g. 'Visa •••• 3155'"
        )
        return String(format: formattedMessage, brand, last4)
    }
}
