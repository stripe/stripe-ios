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
@_spi(STP) extension String.Localized {

    public static var address: String {
        STPLocalizedString(
            "Address",
            """
            Caption for Address field on address form
            Section header for address fields
            """
        )
    }

    public static var address_line1: String {
        STPLocalizedString(
            "Address line 1",
            "Address line 1 placeholder for billing address form.\nLabel for address line 1 field"
        )
    }

    public static var address_line2: String {
        STPLocalizedString("Address line 2", "Label for address line 2 field")
    }

    public static var country_or_region: String {
        STPLocalizedString(
            "Country or region",
            "Country selector and postal code entry form header title\nLabel of an address field"
        )
    }

    public static var country: String {
        STPLocalizedString("Country", "Caption for Country field on address form")
    }

    public static var email: String {
        STPLocalizedString("Email", "Label for Email field on form")
    }

    public static var name: String {
        STPLocalizedString("Name", "Label for Name field on form")
    }

    public static var full_name: String {
        STPLocalizedString("Full name", "Label for Full name field on form")
    }

    public static var given_name: String {
        STPLocalizedString("First", "Label for first (given) name field")
    }

    public static var family_name: String {
        STPLocalizedString("Last", "Label for last (family) name field")
    }

    public static var nameOnAccount: String {
        STPLocalizedString("Name on account", "Label for Name on account field on form")
    }

    public static var company: String {
        STPLocalizedString("Company", "Label for Company field on form")
    }

    public static var invalid_email: String {
        STPLocalizedString("Your email is invalid.", "Error message when email is invalid")
    }

    public static var billing_same_as_shipping: String {
        STPLocalizedString(
            "Billing address is same as shipping",
            "Label for a checkbox that makes customers billing address same as their shipping address"
        )
    }

    // MARK: - Phone number

    public static var phone: String {
        STPLocalizedString("Phone", "Caption for Phone field on address form")
    }

    public static var incomplete_phone_number: String {
        STPLocalizedString(
            "Incomplete phone number",
            "Error description for incomplete phone number"
        )
    }

    public static var invalid_phone_number: String {
        STPLocalizedString(
            "Unable to parse phone number",
            "Error string when we can't parse a phone number"
        )
    }

    public static var optional_field: String {
        STPLocalizedString(
            "%@ (optional)",
            "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
        )
    }

    public static var other: String {
        STPLocalizedString(
            "Other",
            "An option in a dropdown selector indicating the customer's desired selection is not in the list. e.g., 'Choose your bank: Bank1, Bank2, Other'"
        )
    }

    // MARK: City field labels

    public static var city: String {
        STPLocalizedString("City", "Caption for City field on address form")
    }

    public static var district: String {
        STPLocalizedString("District", "Label for the district field on an address form")
    }

    public static var suburb: String {
        STPLocalizedString("Suburb", "Label of an address field")
    }

    public static var post_town: String {
        STPLocalizedString("Town or city", "Label of an address field")
    }

    public static var suburb_or_city: String {
        STPLocalizedString("Suburb or city", "Label of an address field")
    }

    // MARK: Postal code field labels

    public static var eircode: String {
        STPLocalizedString("Eircode", "Label of an address field")
    }

    public static var postal_pin: String {
        "PIN"  // Intentionally left as-is
    }

    public static var postal_code: String {
        STPLocalizedString(
            "Postal code",
            """
            Label of an address field
            Short string for postal code (text used in non-US countries)
            """
        )
    }

    public static var zip: String {
        STPLocalizedString(
            "ZIP",
            """
            Label of an address field
            Short string for zip code (United States only)
            Zip code placeholder US only
            """
        )
    }

    public static var your_zip_is_incomplete: String {
        STPLocalizedString(
            "Your ZIP is incomplete.",
            "Error message for when ZIP code in form is incomplete (US only)"
        )
    }

    public static var your_postal_code_is_incomplete: String {
        STPLocalizedString(
            "Your postal code is incomplete.",
            "Error message for when postal code in form is incomplete"
        )
    }

    // MARK: State field labels

    public static var area: String {
        STPLocalizedString("Area", "Label of an address field")
    }

    public static var county: String {
        STPLocalizedString(
            "County",
            """
            Caption for County field on address form (only countries that use county, like United Kingdom)
            Label of an address field
            """
        )
    }

    public static var department: String {
        STPLocalizedString("Department", "Label of an address field")
    }

    public static var do_si: String {
        STPLocalizedString("Do Si", "Label of an address field")
    }

    public static var emirate: String {
        STPLocalizedString("Emirate", "Label of an address field")
    }

    public static var island: String {
        STPLocalizedString("Island", "Label of an address field")
    }

    public static var oblast: String {
        STPLocalizedString("Oblast", "Label of an address field")
    }

    public static var parish: String {
        STPLocalizedString("Parish", "Label of an address field")
    }

    public static var prefecture: String {
        STPLocalizedString("Prefecture", "Label of an address field")
    }

    public static var province: String {
        STPLocalizedString(
            "Province",
            """
            Caption for Province field on address form (only countries that use province, like Canada)
            Label of an address field
            """
        )
    }

    public static var state: String {
        STPLocalizedString(
            "State",
            """
            Caption for State field on address form (only countries that use state , like United States)
            Label of an address field
            """
        )
    }

    // MARK: - Account
    public static var accountNumber: String {
        STPLocalizedString(
            "Account number",
            """
            Caption for account number
            """
        )
    }
    public static var incompleteBSBEntered: String {
        STPLocalizedString(
            "The BSB you entered is incomplete.",
            "Error string displayed to user when they have entered an incomplete BSB number."
        )
    }

    public static var removeBankAccountEndingIn: String {
        STPLocalizedString(
            "Remove bank account ending in %@",
            "Content for alert popup prompting to confirm removing a saved bank account. e.g. 'Remove bank account ending in 4242'"
        )
    }

    public static var removeBankAccount: String {
        STPLocalizedString(
            "Remove bank account",
            "Title for confirmation alert to remove a saved bank account payment method"
        )
    }

    // MARK: - Control strings
    public static var error: String {
        return STPLocalizedString("Error", "Text for error labels")
    }

    public static var cancel: String {
        STPLocalizedString("Cancel", "Button title to cancel action in an alert")
    }

    public static var ok: String {
        STPLocalizedString("OK", "ok button")
    }

    public static var `continue`: String {
        STPLocalizedString("Continue", "Text for continue button")
    }

    public static var remove: String {
        STPLocalizedString(
            "Remove",
            "Button title for confirmation alert to remove a saved payment method"
        )
    }

    public static var useRotorToAccessLinks: String {
        STPLocalizedString(
            "Use rotor to access links",
            "Accessibility hint indicating to use the accessibility rotor to open links. The word 'rotor' should be localized to match Apple's language here: https://support.apple.com/HT204783"
        )
    }

    // MARK: UPI

    public static var upi_id: String {
        STPLocalizedString("UPI ID", "Label for UPI ID number field on form")
    }

    public static var invalid_upi_id: String {
        STPLocalizedString("Invalid UPI ID", "Error message when UPI ID is invalid")
    }
}
