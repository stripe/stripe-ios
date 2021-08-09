//
//  String+Localized.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static var ideal_bank: String {
        STPLocalizedString("iDEAL Bank", "iDEAL bank section title for iDEAL form entry.")
    }

    static var other: String {
        STPLocalizedString("Other", "An option in a dropdown selector indicating the customer's desired selection is not in the list. e.g., 'Choose your bank: Bank1, Bank2, Other'")
    }

    static var name: String {
        STPLocalizedString("Name", "Label for Name field on form")
    }

    static var email: String {
        STPLocalizedString("Email", "Label for Email field on form")
    }

    static var bank_account: String {
        STPLocalizedString("Bank Account", "Label for Bank Account selection or detail entry form")
    }

    static var phone: String {
        STPLocalizedString("Phone", "Caption for Phone field on address form")
    }

    static var billing_address: String {
        STPLocalizedString("Billing Address", "Title for billing address entry section")
    }

    static var address_line1: String {
        STPLocalizedString("Address line 1", nil)
    }

    static var address_line2: String {
        STPLocalizedString("Address line 2", nil)
    }

    static var country: String {
        STPLocalizedString("Country", "Caption for Country field on address form")
    }

    static var country_or_region: String {
        STPLocalizedString("Country or region", "Label of an address field")
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
        STPLocalizedString("Postal code", "Label of an address field")
    }

    static var zip: String {
        STPLocalizedString("ZIP", "Label of an address field")
    }

    // MARK: State field labels

    static var area: String {
        STPLocalizedString("Area", "Label of an address field")
    }

    static var county: String {
        STPLocalizedString("County", "Label of an address field")
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
        STPLocalizedString("Province", "Label of an address field")
    }

    static var state: String {
        STPLocalizedString("State", "Label of an address field")
    }
}

// MARK: - Legacy strings

/// Legacy strings
struct StripeSharedStrings {
    static func localizedStateString(for countryCode: String?) -> String {
        switch countryCode {
        case "US":
            return STPLocalizedString(
                "State",
                "Caption for State field on address form (only countries that use state , like United States)"
            )
        case "CA":
            return STPLocalizedString(
                "Province",
                "Caption for Province field on address form (only countries that use province, like Canada)"
            )
        case "GB":
            return STPLocalizedString(
                "County",
                "Caption for County field on address form (only countries that use county, like United Kingdom)"
            )
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
