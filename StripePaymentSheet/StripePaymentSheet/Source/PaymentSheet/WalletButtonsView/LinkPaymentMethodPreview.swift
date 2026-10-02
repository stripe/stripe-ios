//
//  LinkPaymentMethodPreview.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/29/25.
//

@_spi(STP) import StripePaymentsUI
import UIKit

struct LinkPaymentMethodPreview: Equatable {
    let icon: UIImage
    let last4: String
    /// A human-readable name for the payment method (e.g. "Visa"), used for accessibility.
    let accessibilityName: String?

    var accessibilityValue: String {
        [accessibilityName, last4].compactMap { $0 }.joined(separator: " ")
    }

    init(icon: UIImage, last4: String, accessibilityName: String? = nil) {
        self.icon = icon
        self.last4 = last4
        self.accessibilityName = accessibilityName
    }

    init?(from paymentDetails: ConsumerSession.DisplayablePaymentDetails?) {
        guard let paymentDetails else {
            return nil
        }

        // Required fields
        guard let last4 = paymentDetails.last4, let paymentMethodType = paymentDetails.defaultPaymentType else {
            return nil
        }

        switch paymentMethodType {
        case .card:
            guard let brand = paymentDetails.defaultCardBrand else {
                return nil
            }
            let cardBrand = STPCard.brand(from: brand)
            let icon = STPImageLibrary.unpaddedCardBrandImage(for: cardBrand)
            self.init(icon: icon, last4: last4, accessibilityName: STPCardBrandUtilities.stringFrom(cardBrand))
        case .bankAccount:
            let bankIconCode = PaymentSheetImageLibrary.bankIconCode(for: nil)
            guard let icon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankIconCode) else {
                fallthrough
            }
            self.init(icon: icon, last4: last4, accessibilityName: String.Localized.bank)
        case .unparsable:
            return nil
        @unknown default:
            return nil
        }
    }

    init?(from paymentDetails: ConsumerPaymentDetails) {
        switch paymentDetails.details {
        case .card(let card):
            let icon = STPImageLibrary.unpaddedCardBrandImage(for: card.stpBrand)
            self.init(icon: icon, last4: card.last4, accessibilityName: STPCardBrandUtilities.stringFrom(card.stpBrand))
        case .bankAccount(let bankAccount):
            let bankIconCode = PaymentSheetImageLibrary.bankIconCode(for: bankAccount.name)
            guard let icon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankIconCode)
                    ?? PaymentSheetImageLibrary.bankInstitutionIcon(for: PaymentSheetImageLibrary.bankIconCode(for: nil)) else {
                return nil
            }
            self.init(icon: icon, last4: bankAccount.last4, accessibilityName: bankAccount.name)
        case .generic:
            return nil
        }
    }
}
