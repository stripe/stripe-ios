//
//  StripeSharedStrings.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
extension String {
    enum Localized {
        static var name: String {
            STPLocalizedString("Name", "Label for Name field on form")
        }
        
        static var email: String {
            return STPLocalizedString("Email", "Label for Email field on form")
        }
        
        static var bank_account: String {
            return STPLocalizedString("Bank Account", "Label for Bank Account selection or detail entry form")
        }
        
        static var phone: String {
            return STPLocalizedString("Phone", "Caption for Phone field on address form")
        }
        
        static var address_line1: String {
            return STPLocalizedString("Address line 1", nil)
        }
        
        static var address_line2: String {
            return STPLocalizedString("Address line 2", nil)
        }
        
        static var country: String {
            return STPLocalizedString("Country", "Caption for Country field on address form")
        }
        
        static var country_or_region: String {
            return STPLocalizedString("Country or region", "Label of an address field")
        }

        // MARK: City field labels
        
        static var city: String {
            return STPLocalizedString("City", "Caption for City field on address form")
        }

        static var district: String {
            return STPLocalizedString("District", "Label for the district field on an address form")
        }
        
        static var suburb: String {
            return STPLocalizedString("Suburb", "Label of an address field")
        }
        
        static var post_town: String {
            return STPLocalizedString("Town or city", "Label of an address field")
        }
        
        static var suburb_or_city: String {
            return STPLocalizedString("Suburb or city", "Label of an address field")
        }

        // MARK: Postal code field labels
        
        static var eircode: String {
            return STPLocalizedString("Eircode", "Label of an address field")
        }
        
        static var postal_pin: String {
            return "PIN" // Intentionally left as-is
        }
        
        static var postal_code: String {
            return STPLocalizedString("Postal code", "Label of an address field")
        }
        
        static var zip: String {
            return STPLocalizedString("ZIP", "Label of an address field")
        }
        
        // MARK: State field labels
        
        static var area: String {
            return STPLocalizedString("Area", "Label of an address field")
        }
        
        static var county: String {
            return STPLocalizedString("County", "Label of an address field")
        }
        
        static var department: String {
            return STPLocalizedString("Department", "Label of an address field")
        }
        
        static var do_si: String {
            return STPLocalizedString("Do Si", "Label of an address field")
        }
        
        static var emirate: String {
            return STPLocalizedString("Emirate", "Label of an address field")
        }
        
        static var island: String {
            return STPLocalizedString("Island", "Label of an address field")
        }
        
        static var oblast: String {
            return STPLocalizedString("Oblast", "Label of an address field")
        }
        
        static var parish: String {
            return STPLocalizedString("Parish", "Label of an address field")
        }
        
        static var prefecture: String {
            return STPLocalizedString("Prefecture", "Label of an address field")
        }
        
        static var province: String {
            return STPLocalizedString("Province", "Label of an address field")
        }

        static var state: String {
            return STPLocalizedString("State", "Label of an address field")
        }
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
