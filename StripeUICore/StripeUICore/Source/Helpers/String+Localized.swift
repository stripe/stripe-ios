//
//  String+Localized.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
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

    static var given_name: String {
        STPLocalizedString("First", "Label for first (given) name field")
    }

    static var family_name: String {
        STPLocalizedString("Last", "Label for last (family) name field")
    }

    static var nameOnAccount: String {
        STPLocalizedString("Name on account", "Label for Name on account field on form")
    }

    static var invalid_email: String {
        STPLocalizedString("Your email is invalid.", "Error message when email is invalid")
    }
    
    static var phone: String {
        STPLocalizedString("Phone", "Caption for Phone field on address form")
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
    // Mark: - Account
    static var auBECSAccount: String {
        STPLocalizedString(
            "AU BECS account number",
            """
            Caption for AU BECS account number
            """
        )
    }

    // MARK: - Control strings
    static var cancel: String {
        STPLocalizedString("Cancel", "Button title to cancel action in an alert")
    }

    static var ok: String {
        STPLocalizedString("OK", "ok button")
    }

    static var `continue`: String {
        STPLocalizedString("Continue", "Text for continue button")
    }
}
