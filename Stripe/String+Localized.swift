//
//  String+Localized.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static var ideal_bank: String {
        STPLocalizedString("iDEAL Bank", "iDEAL bank section title for iDEAL form entry.")
    }

    static var other: String {
        STPLocalizedString("Other", "An option in a dropdown selector indicating the customer's desired selection is not in the list. e.g., 'Choose your bank: Bank1, Bank2, Other'")
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

    // MARK: Payment Sheet
    static var `continue`: String {
        STPLocalizedString("Continue", "Text for continue button")
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
