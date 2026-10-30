//
//  String+Localized.swift
//  StripePaymentsUI
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    @_spi(InternalOnlyAPI) public static var your_cards_expiration_year_is_invalid: String {
        STPLocalizedString(
            "Your card's expiration year is invalid.",
            "String to describe an invalid year in expiry date."
        )
    }
}

@_spi(InternalOnlyAPI) public struct StripeSharedStrings {
    @_spi(InternalOnlyAPI) public static func localizedStateString(for countryCode: String?) -> String {
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
