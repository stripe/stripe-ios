//
//  String+Localized.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
@_spi(STP) public extension String.Localized {

    static var address: String {
        STPLocalizedString(
            "Address",
            """
            Caption for Address field on address form
            Section header for address fields
            """
        )
    }

    static var address_line1: String {
        STPLocalizedString("ee760", "Address line 1 placeholder for billing address form.\nLabel for address line 1 field")
    }

    static var address_line2: String {
        STPLocalizedString("350b2", "Label for address line 2 field")
    }

    static var country_or_region: String {
        STPLocalizedString("8d236", "Country selector and postal code entry form header title\nLabel of an address field")
    }

    static var country: String {
        STPLocalizedString("701d0", "Caption for Country field on address form")
    }

    static var email: String {
        STPLocalizedString("969cc", "Label for Email field on form")
    }

    static var name: String {
        STPLocalizedString("dcd1d", "Label for Name field on form")
    }

    static var full_name: String {
        STPLocalizedString("f13a6", "Label for Full name field on form")
    }

    static var given_name: String {
        STPLocalizedString("a151c", "Label for first (given) name field")
    }

    static var family_name: String {
        STPLocalizedString("eb970", "Label for last (family) name field")
    }

    static var nameOnAccount: String {
        STPLocalizedString("59f3a", "Label for Name on account field on form")
    }

    static var company: String {
        STPLocalizedString("de474", "Label for Company field on form")
    }

    static var invalid_email: String {
        STPLocalizedString("57c28", "Error message when email is invalid")
    }

    static var billing_same_as_shipping: String {
        STPLocalizedString("a03f3", "Label for a checkbox that makes customers billing address same as their shipping address")
    }

    // MARK: - Phone number

    static var phoneNumber: String {
        STPLocalizedString("306f1", "Caption for Phone number field on address form")
    }

    static var incomplete_phone_number: String {
        STPLocalizedString("6d2d3", "Error description for incomplete phone number")
    }

    static var invalid_phone_number: String {
        STPLocalizedString("72356", "Error string when we can't parse a phone number")
    }

    static var optional_field: String {
        STPLocalizedString(
            "%@ (optional)",
            "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
        )
    }

    static var other: String {
        STPLocalizedString("f97e9", "An option in a dropdown selector indicating the customer's desired selection is not in the list. e.g., 'Choose your bank: Bank1, Bank2, Other'")
    }

    // MARK: City field labels

    static var city: String {
        STPLocalizedString("fc33f", "Caption for City field on address form")
    }

    static var district: String {
        STPLocalizedString("50f18", "Label for the district field on an address form")
    }

    static var suburb: String {
        STPLocalizedString("9e843", "Label of an address field")
    }

    static var post_town: String {
        STPLocalizedString("9ce56", "Label of an address field")
    }

    static var suburb_or_city: String {
        STPLocalizedString("c3273", "Label of an address field")
    }

    // MARK: Postal code field labels

    static var eircode: String {
        STPLocalizedString("113d9", "Label of an address field")
    }

    static var postal_pin: String {
        "PIN" // Intentionally left as-is
    }

    static var postal_code: String {
        STPLocalizedString(
            "Postal code",
            """
            Label of an address field
            Short string for postal code (text used in non-US countries)
            """
        )
    }

    static var zip: String {
        STPLocalizedString(
            "ZIP",
            """
            Label of an address field
            Short string for zip code (United States only)
            Zip code placeholder US only
            """
        )
    }

    static var your_zip_is_incomplete: String {
        STPLocalizedString("3e686", "Error message for when ZIP code in form is incomplete (US only)")
    }

    static var your_postal_code_is_incomplete: String {
        STPLocalizedString("52c55", "Error message for when postal code in form is incomplete")
    }

    static var your_zip_is_invalid: String {
        STPLocalizedString("f029b", "Error message for when ZIP code in form is invalid (US only)")
    }

    static var your_postal_code_is_invalid: String {
        STPLocalizedString("037ec", "Error message for when postal code in form is invalid")
    }

    // MARK: State field labels

    static var area: String {
        STPLocalizedString("024dc", "Label of an address field")
    }

    static var county: String {
        STPLocalizedString(
            "County",
            """
            Caption for County field on address form (only countries that use county, like United Kingdom)
            Label of an address field
            """
        )
    }

    static var department: String {
        STPLocalizedString("5304a", "Label of an address field")
    }

    static var do_si: String {
        STPLocalizedString("32c9d", "Label of an address field")
    }

    static var emirate: String {
        STPLocalizedString("4309c", "Label of an address field")
    }

    static var island: String {
        STPLocalizedString("730f5", "Label of an address field")
    }

    static var oblast: String {
        STPLocalizedString("2ba5c", "Label of an address field")
    }

    static var parish: String {
        STPLocalizedString("45ab6", "Label of an address field")
    }

    static var prefecture: String {
        STPLocalizedString("50571", "Label of an address field")
    }

    static var province: String {
        STPLocalizedString(
            "Province",
            """
            Caption for Province field on address form (only countries that use province, like Canada)
            Label of an address field
            """
        )
    }

    static var state: String {
        STPLocalizedString(
            "State",
            """
            Caption for State field on address form (only countries that use state , like United States)
            Label of an address field
            """
        )
    }

    // MARK: - Account
    static var accountNumber: String {
        STPLocalizedString(
            "Account number",
            """
            Caption for account number
            """
        )
    }
    static var incompleteBSBEntered: String {
        STPLocalizedString(
            "The BSB you entered is incomplete.",
            "Error string displayed to user when they have entered an incomplete BSB number.")
    }

    static var invalidSortCodeEntered: String {
        STPLocalizedString(
            "The sort code you entered is invalid.",
            "Error string displayed to user when they have entered an invalid 'sort code' (a bank routing number used in the UK and Ireland)")
    }

    static var incompleteAccountNumber: String {
        STPLocalizedString("e10dd", "Error description for incomplete account number")
    }

    static var bank_account_xxxx: String {
        STPLocalizedString(
            "Bank account •••• %@",
            "Content for alert popup prompting to confirm removing a saved bank account. e.g. 'Bank account •••• 4242'")
    }

    static var removeBankAccount: String {
        STPLocalizedString(
            "Remove bank account?",
            "Title for confirmation alert to remove a saved bank account payment method")
    }

    // MARK: - Control strings
    static var error: String {
        return STPLocalizedString("54a0e", "Text for error labels")
    }

    static var cancel: String {
        STPLocalizedString("19766e", "Button title to cancel action in an alert")
    }

    static var closeFormTitle: String {
        STPLocalizedString("6ebfc",
                           "Used as the title for prompting the user if they want to close the sheet")
    }

    static var paymentInfoWontBeSaved: String {
        STPLocalizedString("cc532",
                           "Used as the title for prompting the user if they want to close the sheet")
    }

    static var ok: String {
        STPLocalizedString("56533", "ok button")
    }

    static var `continue`: String {
        STPLocalizedString("31fbe", "Text for continue button")
    }

    static var remove: String {
        STPLocalizedString("c3812", "Button title for confirmation alert to remove a saved payment method")
    }

    static var search: String {
        STPLocalizedString("49c26", "Title of a button with a 🔍 (magnifying glass) icon that starts a search when tapped")
    }

    static var useRotorToAccessLinks: String {
        STPLocalizedString(
            "Use rotor to access links",
            "Accessibility hint indicating to use the accessibility rotor to open links. The word 'rotor' should be localized to match Apple's language here: https://support.apple.com/HT204783"
        )
    }

    static var edit: String {
        STPLocalizedString(
            "Edit",
            "Button title to enter editing mode"
        )
    }

    // MARK: - UPI

    static var upi_id: String {
        STPLocalizedString("cec4a", "Label for UPI ID number field on form")
    }

    static var invalid_upi_id: String {
        STPLocalizedString("14cf3", "Error message when UPI ID is invalid")
    }

    // MARK: - Blik

    static var blik_code: String {
        STPLocalizedString("35cc2", "Label for BLIK code number field on form")
    }

    static var incomplete_blik_code: String {
        STPLocalizedString("6c0af", "Error message when BLIK code is incomplete")
    }

    static var invalid_blik_code: String {
        STPLocalizedString("224bb", "Error message when BLIK code is invalid")
    }

    // MARK: - Card brand choice

    static var card_brand_dropdown_placeholder: String {
        STPLocalizedString("4dc47", "Message when a user is selecting a card brand in a dropdown")
    }

    static var card_brand: String {
        STPLocalizedString("45022", "Label an input field to update card brand")
    }

    static var remove_card: String {
        STPLocalizedString("dcf7d", "Label on a button for removing a card")
    }

    static var brand_not_accepted: String {
        STPLocalizedString(
            "(not accepted)",
            "Shown in a dropdown picker next to a card brand that is not accepted by a merchant. E.g. \"Visa (not accepted)\""
       )
    }

    // MARK: - Payment preview

    static var card_details_xxxx: String {
        STPLocalizedString(
            "%1$@ •••• %2$@",
            "Card preview details displaying the last four digits: {card brand} •••• {last 4} e.g. 'Visa •••• 3155'"
        )
    }
}
