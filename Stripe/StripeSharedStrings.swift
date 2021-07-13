//
//  StripeSharedStrings.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
struct StripeSharedStrings {
    static func localizedNameString() -> String {
        return STPLocalizedString("Name", "Label for Name field on form")
    }

    static func localizedEmailString() -> String {
        return STPLocalizedString("Email", "Label for Email field on form")
    }

    static func localizedBankAccountString() -> String {
        return STPLocalizedString(
            "Bank Account", "Label for Bank Account selection or detail entry form")
    }

    static func localizedPhoneString() -> String {
        return STPLocalizedString("Phone", "Caption for Phone field on address form")
    }

    static func localizedAddressLine1String() -> String {
        return STPLocalizedString("Address", "Caption for Address field on address form")
    }

    static func localizedAddressLine2String() -> String {
        return STPLocalizedString(
            "Apt.", "Caption for Apartment/Address line 2 field on address form")
    }

    static func localizedCityString() -> String {
        return STPLocalizedString("City", "Caption for City field on address form")
    }

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

    static func localizedCountryString() -> String {
        return STPLocalizedString("Country", "Caption for Country field on address form")
    }
}
