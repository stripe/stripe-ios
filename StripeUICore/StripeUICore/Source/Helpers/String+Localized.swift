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
        STPLocalizedString("Address line 1", "Address line 1 placeholder for billing address form.\nLabel for address line 1 field")
    }

    static var address_line2: String {
        STPLocalizedString("Address line 2", "Label for address line 2 field")
    }

    static var country_or_region: String {
        STPLocalizedString("Country or region", "Country selector and postal code entry form header title\nLabel of an address field")
    }

    static var country: String {
        STPLocalizedString("Country", "Caption for Country field on address form")
    }

    static var email: String {
        STPLocalizedString("Email", "Label for Email field on form")
    }

    static var name: String {
        STPLocalizedString("Name", "Label for Name field on form")
    }

    static var full_name: String {
        STPLocalizedString("Full name", "Label for Full name field on form")
    }

    static var given_name: String {
        STPLocalizedString("First", "Label for first (given) name field")
    }

    static var family_name: String {
        STPLocalizedString("Last", "Label for last (family) name field")
    }

    static var nameOnAccount: String {
        STPLocalizedString("Name on account", "Label for Name on account field on form")
    }

    static var company: String {
        STPLocalizedString("Company", "Label for Company field on form")
    }

    static var invalid_email: String {
        STPLocalizedString("Your email is invalid.", "Error message when email is invalid")
    }

    static var billing_same_as_shipping: String {
        STPLocalizedString("Billing address is same as shipping", "Label for a checkbox that makes customers billing address same as their shipping address")
    }

    // MARK: - Phone number

    static var phoneNumber: String {
        STPLocalizedString("Phone number", "Caption for Phone number field on address form")
    }

    static var incomplete_phone_number: String {
        STPLocalizedString("Incomplete phone number", "Error description for incomplete phone number")
    }

    static var invalid_phone_number: String {
        STPLocalizedString("Unable to parse phone number", "Error string when we can't parse a phone number")
    }

    static var optional_field: String {
        STPLocalizedString(
            "%@ (optional)",
            "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
        )
    }

    static var other: String {
        STPLocalizedString("Other", "An option in a dropdown selector indicating the customer's desired selection is not in the list. e.g., 'Choose your bank: Bank1, Bank2, Other'")
    }

    // MARK: City field labels

    static var city: String {
        STPLocalizedString("City", "Caption for City field on address form")
    }

    static var district: String {
        STPLocalizedString("District", "Label for the district field on an address form")
    }

    static var suburb: String {
        STPLocalizedString("Suburb", "Label of an address field")
    }

    static var post_town: String {
        STPLocalizedString("Town or city", "Label of an address field")
    }

    static var suburb_or_city: String {
        STPLocalizedString("Suburb or city", "Label of an address field")
    }

    // MARK: Postal code field labels

    static var eircode: String {
        STPLocalizedString("Eircode", "Label of an address field")
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
        STPLocalizedString("Your ZIP is incomplete.", "Error message for when ZIP code in form is incomplete (US only)")
    }

    static var your_postal_code_is_incomplete: String {
        STPLocalizedString("Your postal code is incomplete.", "Error message for when postal code in form is incomplete")
    }

    // MARK: State field labels

    static var area: String {
        STPLocalizedString("Area", "Label of an address field")
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
        STPLocalizedString("Department", "Label of an address field")
    }

    static var do_si: String {
        STPLocalizedString("Do Si", "Label of an address field")
    }

    static var emirate: String {
        STPLocalizedString("Emirate", "Label of an address field")
    }

    static var island: String {
        STPLocalizedString("Island", "Label of an address field")
    }

    static var oblast: String {
        STPLocalizedString("Oblast", "Label of an address field")
    }

    static var parish: String {
        STPLocalizedString("Parish", "Label of an address field")
    }

    static var prefecture: String {
        STPLocalizedString("Prefecture", "Label of an address field")
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
        STPLocalizedString("The account number you entered is incomplete.", "Error description for incomplete account number")
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
        return STPLocalizedString("Error", "Text for error labels")
    }

    static var cancel: String {
        STPLocalizedString("Cancel", "Button title to cancel action in an alert")
    }

    static var closeFormTitle: String {
        STPLocalizedString("Do you want to close this form?",
                           "Used as the title for prompting the user if they want to close the sheet")
    }

    static var paymentInfoWontBeSaved: String {
        STPLocalizedString("Your payment information will not be saved.",
                           "Used as the title for prompting the user if they want to close the sheet")
    }

    static var ok: String {
        STPLocalizedString("OK", "ok button")
    }

    static var `continue`: String {
        STPLocalizedString("Continue", "Text for continue button")
    }

    static var remove: String {
        STPLocalizedString("Remove", "Button title for confirmation alert to remove a saved payment method")
    }

    static var search: String {
        STPLocalizedString("Search", "Title of a button with a 🔍 (magnifying glass) icon that starts a search when tapped")
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
        STPLocalizedString("UPI ID", "Label for UPI ID number field on form")
    }

    static var invalid_upi_id: String {
        STPLocalizedString("Invalid UPI ID", "Error message when UPI ID is invalid")
    }

    // MARK: - Blik

    static var blik_code: String {
        STPLocalizedString("BLIK code", "Label for BLIK code number field on form")
    }

    static var incomplete_blik_code: String {
        STPLocalizedString("Your BLIK code is incomplete.", "Error message when BLIK code is incomplete")
    }

    static var invalid_blik_code: String {
        STPLocalizedString("Your BLIK code is invalid.", "Error message when BLIK code is invalid")
    }

    // MARK: - Card brand choice

    static var card_brand_dropdown_placeholder: String {
        STPLocalizedString("Select card brand (optional)", "Message when a user is selecting a card brand in a dropdown")
    }

    static var card_brand: String {
        STPLocalizedString("Card brand", "Label an input field to update card brand")
    }

    static var remove_card: String {
        STPLocalizedString("Remove card", "Label on a button for removing a card")
    }
    
    static var brand_not_accepted: String {
        STPLocalizedString(
            "(not accepted)",
            "Shown in a dropdown picker next to a card brand that is not accepted by a merchant. E.g. \"Visa (not accepted)\""
       )
    }
}
