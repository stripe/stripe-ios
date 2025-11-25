//
//  LinkPaymentMethodPreview.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/29/25.
//

@_spi(STP) import StripePaymentsUI
import UIKit

struct LinkPaymentMethodPreview {
    let icon: UIImage
    let last4: String

    init(icon: UIImage, last4: String) {
        self.icon = icon
        self.last4 = last4
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
            self.init(icon: icon, last4: last4)
        case .bankAccount:
            let bankIconCode = PaymentSheetImageLibrary.bankIconCode(for: nil)
            guard let icon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankIconCode) else {
                fallthrough
            }
            self.init(icon: icon, last4: last4)
        case .unparsable:
            return nil
        @unknown default:
            return nil
        }
    }
}
