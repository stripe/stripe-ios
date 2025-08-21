//
//  MandateVariant.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 8/20/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI

enum MandateVariant {
    // The original mandate that describes reuse of the payment method by the merchant.
    case original
    // The updated mandate that describes reuse of the payment method by the merchant and optional Link signup.
    case updated(shouldSignUpToLink: Bool)

    func create(forMerchant merchant: String) -> NSAttributedString {
        let formatText = switch self {
        case .original:
            String.Localized.by_providing_your_card_information_text
        case .updated(let shouldSaveToLink):
            if shouldSaveToLink {
                String.Localized.by_continuing_you_agree_to_save_your_information_to_merchant_and_link
            } else {
                String.Localized.by_continuing_you_agree_to_save_your_information_to_merchant
            }
        }

        let terms = String(format: formatText, merchant).removeTrailingDots()

        if case .updated(true) = self {
            let links = [
                "link": URL(string: "https://link.com")!,
                "terms": URL(string: "https://link.com/terms")!,
                "privacy": URL(string: "https://link.com/privacy")!,
            ]
            return STPStringUtils.applyLinksToString(template: terms, links: links)
        } else {
            return NSAttributedString(string: terms)
        }
    }
}

private extension String {
    func removeTrailingDots() -> String {
        return hasSuffix("..") ? String(dropLast()) : self
    }
}
