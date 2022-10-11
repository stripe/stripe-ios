//
//  String+Localized.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
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

    static var add_a_payment_method: String {
        STPLocalizedString(
            "Add a payment method",
            "Text for a button that, when tapped, displays another screen where the customer can add a new payment method"
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
    
    static var save_for_future_payments: String {
        STPLocalizedString("Save for future payments", "The label of a switch indicating whether to save the payment method for future payments.")
    }
    
    static func save_this_card_for_future_$merchant_payments(merchantDisplayName: String) -> String {
        String(
            format: STPLocalizedString(
                "Save this card for future %@ payments",
                "The label of a switch indicating whether to save the user's card for future payment"
            ),
            merchantDisplayName
        )
    }

    static func pay_faster_at_$merchant_and_thousands_of_merchants(merchantDisplayName: String) -> String {
        String(
            format: STPLocalizedString(
                "Pay faster at %@ and thousands of merchants.",
                """
                Label describing the benefit of signing up for Link.
                Pay faster at {Merchant Name} and thousands of merchants
                e.g, 'Pay faster at Example, Inc. and thousands of merchants.'
                """
            ),
            merchantDisplayName
        )
    }

    static var back: String {
        STPLocalizedString("Back", "Text for back button")
    }

    static var update_card: String {
        STPLocalizedString(
            "Update card",
            """
            Title for a button that when tapped, presents a screen for updating a card. Also
            the heading the screen itself.
            """
        )
    }

    static var show_menu: String {
        STPLocalizedString(
            "Show menu",
            "Accessibility label for an action or a button that shows a menu."
        )
    }

    static var pay_another_way: String {
        STPLocalizedString(
            "Pay another way",
            "Label of a button that when tapped allows the user to select a different form of payment."
        )
    }
    
    static var shipping_address: String {
            STPLocalizedString("Shipping Address", "Title for shipping address entry section")
    }

    static var save_address: String {
        STPLocalizedString("Save address", "Title for address entry section")
    }
    
    static var enter_address_manually: String {
        STPLocalizedString("Enter address manually", "Text for a button that allows manual entry of an address")
    }
    
    static func does_not_support_shipping_to(countryCode: String) -> String {
        let countryDisplayName = Locale.autoupdatingCurrent.localizedString(forRegionCode: countryCode) ?? countryCode
        return String(
            format: STPLocalizedString(
                "Shipping to %@ is not supported.",
                """
                Text for an error that is shown when a user selects a shipping address that
                is not supported by the merchant
                """
            ),
            countryDisplayName
        )
    }

    static var or: String {
        STPLocalizedString(
            "Or",
            "Separator label between two options"
        )
    }
    
    static var approve_payment: String {
        STPLocalizedString(
            "Approve payment",
            "Text on a screen asking the user to approve a payment"
        )
    }
    
    static var cancel_pay_another_way: String {
        STPLocalizedString(
            "Cancel and pay another way",
            "Button text on a screen asking the user to approve a payment"
        )
    }
    
    static var open_upi_app: String {
        STPLocalizedString(
            "Open your UPI app to approve your payment within %@",
            "Countdown timer text on a screen asking the user to approve a payment"
        )
    }
    
    static var payment_failed: String {
        STPLocalizedString(
            "Payment failed",
            "Text on a screen that indicates a payment has failed"
        )
    }
    
    static var please_go_back: String {
        STPLocalizedString(
            "Please go back and select another payment method",
            "Text on a screen that indicates a payment has failed informing the user we are asking the user to try a different payment method"
        )
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
