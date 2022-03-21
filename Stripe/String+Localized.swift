//
//  String+Localized.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static var add_new_payment_method: String {
        STPLocalizedString(
            "Add new payment method",
            "Text for a button that, when tapped, displays another screen where the customer can add payment method details"
        )
    }

    static var ideal_bank: String {
        STPLocalizedString("iDEAL Bank", "iDEAL bank section title for iDEAL form entry.")
    }

    static var bank_account: String {
        STPLocalizedString("Bank Account", "Label for Bank Account selection or detail entry form")
    }

    static var billing_address: String {
        STPLocalizedString("Billing Address", "Title for billing address entry section")
    }

    static var card_brand_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ ending in %2$@",
            "Details of a saved card. '{card brand} ending in {last 4}' e.g. 'VISA ending in 4242'"
        )
    }

    static var pay_with_payment_method: String {
        // TODO(ramont): Re-translate this string as some of the existing translations
        // contain punctuation or don't read as a sentence.
        STPLocalizedString("Pay with %@", "Pay with {payment method}")
    }
    
    static var bank_account_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ ending in %2$@",
            "Details of a saved bank account. '{Bank name} account ending in {last 4}' e.g. 'Wells Fargo account ending in 4242'"
        )
    }
    
    static var card_number: String {
        STPLocalizedString("Card number", "Label for card number entry text field")
    }
    
    static var your_card_number_is_incomplete: String {
        STPLocalizedString("Your card number is incomplete.", "Error message for card form when card number is incomplete")
    }
    
    static var your_card_number_is_invalid: String {
        STPLocalizedString("Your card number is invalid.", "Error message for card form when card number is invalid")
    }
    
    static var card_information: String {
        STPLocalizedString("Card information", "Card details entry form header title")
    }
    
    static var cvv: String {
        STPLocalizedString("CVV", "Label for entering CVV in text field")
    }
    
    static var cvc: String {
        STPLocalizedString("CVC", "Label for entering CVC in text field")
    }
    
    static var your_cards_security_code_is_incomplete: String {
        STPLocalizedString("Your card's security code is incomplete.", "Error message for card entry form when CVC/CVV is incomplete.")
    }
    
    static var mm_yy: String {
        STPLocalizedString("MM / YY", "label for text field to enter card expiry")
    }
    
    static var your_cards_expiration_date_is_invalid: String {
        STPLocalizedString("Your card's expiration date is invalid.", "Error message for card details form when expiration date is invalid")
    }
    
    static var your_cards_expiration_date_is_incomplete: String {
        STPLocalizedString("Your card's expiration date is incomplete.", "Error message for card details form when expiration date isn't entered completely")
    }
    
    static var your_cards_expiration_month_is_invalid: String {
        STPLocalizedString("Your card's expiration month is invalid.", "String to describe an invalid month in expiry date.")
    }
    
    static var your_cards_expiration_year_is_invalid: String {
        STPLocalizedString("Your card's expiration year is invalid.", "String to describe an invalid year in expiry date.")
    }
}

// MARK: - Legacy strings

/// Legacy strings
struct StripeSharedStrings {
    static func localizedStateString(for countryCode: String?) -> String {
        switch countryCode {
        case "US":
            return String.Localized.state
        case "CA":
            return String.Localized.province
        case "GB":
            return String.Localized.county
        default:
            return STPLocalizedString(
                "State / Province / Region",
                "Caption for generalized state/province/region field on address form (not tied to a specific country's format)"
            )
        }
    }
    
    static func localizedPostalCodeString(for countryCode: String?) -> String {
        return countryCode == "US"
            ? STPLocalizedString(
                "ZIP Code",
                "Caption for Zip Code field on address form (only shown when country is United States only)"
            )
            : STPLocalizedString(
                "Postal Code",
                "Caption for Postal Code field on address form (only shown in countries other than the United States)"
            )
    }
}
