//
//  String+Localized.swift
//  StripePayments
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    @_spi(STP) public static var cvc: String {
        STPLocalizedString("CVC", "Label for entering CVC in text field")
    }

    @_spi(STP) public static var mm_yy: String {
        STPLocalizedString("MM / YY", "label for text field to enter card expiry")
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

    @_spi(STP) public static var your_cards_security_code_is_incomplete: String {
        STPLocalizedString(
            "Your card's security code is incomplete.",
            "Error message for card entry form when CVC is incomplete."
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
    @_spi(STP) public static var card_number: String {
        STPLocalizedString("Card number", "Label for card number entry text field")
    }
}
