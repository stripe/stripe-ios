//
//  String+Localized.swift
//  StripePaymentsUI
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    @_spi(STP) public static var bank_account: String {
        STPLocalizedString("Bank Account", "Label for Bank Account selection or detail entry form")
    }

    @_spi(STP) public static var card_number: String {
        STPLocalizedString("Card number", "Label for card number entry text field")
    }

    @_spi(STP) public static var card_brand_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ ending in %2$@",
            "Details of a saved card. '{card brand} ending in {last 4}' e.g. 'VISA ending in 4242'"
        )
    }

    @_spi(STP) public static var bank_name_account_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ account ending in %2$@",
            "Details of a saved bank account. '{bank name} account ending in {last 4}' e.g. 'Chase account ending in 4242'"
        )
    }

    @_spi(STP) public static var apple_pay: String {
        STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
    }

    @_spi(STP) public static var expiration_date_accessibility_label: String {
        STPLocalizedString("expiration date", "accessibility label for text field")
    }

    @_spi(STP) public static var allow_camera_access: String {
        STPLocalizedString(
            "To scan your card, allow camera access in Settings.",
            "Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."
        )
    }

    @_spi(STP) public static var shipping_address: String {
        STPLocalizedString("Shipping Address", "Title for shipping address entry section")
    }

    @_spi(STP) public static var billing_address: String {
        STPLocalizedString("Billing Address", "Title for billing address entry section")
    }

    @_spi(STP) public static var billing_address_lowercase: String {
        STPLocalizedString("Billing address", "Billing address section title for card form entry.")
    }

    @_spi(STP) public static var your_card_number_is_incomplete: String {
        STPLocalizedString(
            "Your card number is incomplete.",
            "Error message for card form when card number is incomplete"
        )
    }

    @_spi(STP) public static var your_card_number_is_invalid: String {
        STPLocalizedString(
            "Your card number is invalid.",
            "Error message for card form when card number is invalid"
        )
    }

    @_spi(STP) public static var cvv: String {
        STPLocalizedString("CVV", "Label for entering CVV in text field")
    }

    @_spi(STP) public static var cvc: String {
        STPLocalizedString("CVC", "Label for entering CVC in text field")
    }

    @_spi(STP) public static var card_information: String {
        STPLocalizedString("Card information", "Card details entry form header title")
    }

    @_spi(STP) public static var mm_yy: String {
        STPLocalizedString("MM / YY", "label for text field to enter card expiry")
    }

    @_spi(STP) public static var your_cards_security_code_is_incomplete: String {
        STPLocalizedString(
            "Your card's security code is incomplete.",
            "Error message for card entry form when CVC/CVV is incomplete."
        )
    }

    @_spi(STP) public static var your_cards_expiration_date_is_invalid: String {
        STPLocalizedString(
            "Your card's expiration date is invalid.",
            "Error message for card details form when expiration date is invalid"
        )
    }

    @_spi(STP) public static var your_cards_expiration_date_is_incomplete: String {
        STPLocalizedString(
            "Your card's expiration date is incomplete.",
            "Error message for card details form when expiration date isn't entered completely"
        )
    }

    @_spi(STP) public static var your_cards_expiration_month_is_invalid: String {
        STPLocalizedString(
            "Your card's expiration month is invalid.",
            "String to describe an invalid month in expiry date."
        )
    }

    @_spi(STP) public static var your_cards_expiration_year_is_invalid: String {
        STPLocalizedString(
            "Your card's expiration year is invalid.",
            "String to describe an invalid year in expiry date."
        )
    }
}

@_spi(STP) public struct StripeSharedStrings {
    @_spi(STP) public static func localizedStateString(for countryCode: String?) -> String {
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
}
