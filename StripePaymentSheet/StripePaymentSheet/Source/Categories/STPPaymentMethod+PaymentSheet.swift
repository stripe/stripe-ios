//
//  STPPaymentMethod+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

extension STPPaymentMethod {
    var paymentSheetLabel: String {
        switch type {
        case .card:
            // Link payment details here are for Link card brand
            return linkPaymentDetails?.label ?? "•••• \(card?.last4 ?? "")"
        case .SEPADebit:
            // The missing space is not an oversight, but on purpose
            return "••••\(sepaDebit?.last4 ?? "")"
        case .USBankAccount:
            // The missing space is not an oversight, but on purpose
            return "••••\(usBankAccount?.last4 ?? "")"
        case .link:
            return linkPaymentDetails?.label ?? type.displayName
        default:
            return type.displayName
        }
    }

    var paymentSheetAccessibilityLabel: String? {
        switch type {
        case .card:
            if let linkPaymentDetails {
                // Link card brand
                return linkPaymentDetails.paymentSheetAccessibilityLabel
            } else if let card {
                return makeCardAccessibilityLabel(cardBrand: card.preferredDisplayBrand, last4: card.last4 ?? "")
            } else {
                return nil
            }
        case .USBankAccount:
            guard let usBankAccount = self.usBankAccount else {
                return nil
            }
            return String(format: String.Localized.bank_name_account_ending_in_last_4, usBankAccount.bankName, usBankAccount.last4)
        case .link:
            switch linkPaymentDetails {
            case .card(let cardDetails):
                return makeCardAccessibilityLabel(cardBrand: cardDetails.brand, last4: cardDetails.last4)
            case .bankAccount(let bankDetails):
                return String(format: String.Localized.bank_name_account_ending_in_last_4, bankDetails.bankName, bankDetails.last4)
            default:
                return nil
            }
        default:
            return nil
        }
    }

    func paymentOptionLabel(confirmParams: IntentConfirmParams?) -> String {
        if let instantDebitsLinkedBank = confirmParams?.instantDebitsLinkedBank {
            return "••••\(instantDebitsLinkedBank.last4 ?? "")"
        } else {
            return paymentSheetLabel
        }
    }

    var expandedPaymentSheetLabel: String {
        switch type {
        case .card:
            if isLinkPaymentMethod || isLinkPassthroughMode {
                return STPPaymentMethodType.link.displayName
            } else if let card {
                return STPCardBrandUtilities.stringFrom(card.preferredDisplayBrand) ?? STPPaymentMethodType.card.displayName
            } else {
                return STPPaymentMethodType.card.displayName
            }
        case .USBankAccount:
            if isLinkPassthroughMode {
                return STPPaymentMethodType.link.displayName
            } else {
                return usBankAccount?.bankName ?? type.displayName
            }
        default:
            return type.displayName
        }
    }

    var paymentSheetSublabel: String? {
        switch type {
        case .card:
            return linkPaymentDetailsFormattedString ?? paymentSheetLabel
        case .USBankAccount:
            return paymentSheetLabel
        case .link:
            return linkPaymentDetailsFormattedString
        default:
            return nil
        }
    }

    var linkPaymentDetailsFormattedString: String? {
        guard let linkPaymentDetails else {
            return nil
        }

        let components = [linkPaymentDetails.label, linkPaymentDetails.sublabel].compactMap { $0 }
        return components.joined(separator: " ")
    }

    func hasUpdatedCardParams(_ updatedParams: STPPaymentMethodCardParams?) -> Bool {
        guard let currCard = self.card,
              let updatedParams = updatedParams else {
            return false
        }
        let updatedExpMM = NSNumber(value: currCard.expMonth) != updatedParams.expMonth
        let updatedExpYY = currCard.twoDigitYear != updatedParams.expYear

        return updatedExpMM || updatedExpYY
    }

    func hasUpdatedAutomaticBillingDetailsParams(_ updatedParams: STPPaymentMethodBillingDetails?) -> Bool {
        guard let updatedParams = updatedParams else {
            return false
        }
        let updatedCountry = self.billingDetails?.address?.country != updatedParams.address?.country
        let updatedPostalCode = self.billingDetails?.address?.postalCode != updatedParams.address?.postalCode
        return updatedCountry || updatedPostalCode
    }

    func hasUpdatedFullBillingDetailsParams(_ updatedParams: STPPaymentMethodBillingDetails?) -> Bool {
        guard let updatedParams = updatedParams else {
            return false
        }
        let updatedLine1 = self.billingDetails?.address?.line1 != updatedParams.address?.line1
        let updatedLine2 = self.billingDetails?.address?.line2 ?? "" != updatedParams.address?.line2 ?? ""
        let updatedCity = self.billingDetails?.address?.city != updatedParams.address?.city
        let updatedState = self.billingDetails?.address?.state != updatedParams.address?.state

        let updatedCountry = self.billingDetails?.address?.country != updatedParams.address?.country
        let updatedPostalCode = self.billingDetails?.address?.postalCode != updatedParams.address?.postalCode

        return updatedLine1 || updatedLine2 || updatedCity || updatedState || updatedCountry || updatedPostalCode
    }
}

private extension LinkPaymentDetails {
    var paymentSheetAccessibilityLabel: String {
        switch self {
        case .card(let cardDetails):
            return makeCardAccessibilityLabel(cardBrand: cardDetails.brand, last4: cardDetails.last4)
        case .bankAccount(let bankDetails):
            return String(format: String.Localized.bank_name_account_ending_in_last_4, bankDetails.bankName, bankDetails.last4)
        }
    }
}

private func makeCardAccessibilityLabel(cardBrand: STPCardBrand, last4: String) -> String {
    let brand = STPCardBrandUtilities.stringFrom(cardBrand) ?? ""
    let last4Spaced = last4.map { String($0) }.joined(separator: " ")
    let localized = String.Localized.card_brand_ending_in_last_4
    return String(format: localized, brand, last4Spaced)
}
