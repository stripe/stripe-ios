//
//  String+Localized.swift
//  StripePaymentsUI
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    @_spi(STP) public static var bank_account: String {
        STPLocalizedString("Bank Account", "Label for Bank Account selection or detail entry form")
    }

    @_spi(STP) public static var expiration_date_accessibility_label: String {
        STPLocalizedString("expiration date", "accessibility label for text field")
    }

    @_spi(STP) public static var allow_camera_access: String {
        STPLocalizedString(
            "To scan your card, allow camera access in Settings.",
            "Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."
        )
    }

    @_spi(STP) public static var shipping_address: String {
        STPLocalizedString("Shipping Address", "Title for shipping address entry section")
    }

    @_spi(STP) public static var billing_address_lowercase: String {
        STPLocalizedString("Billing address", "Billing address section title for card form entry.")
    }
}

@_spi(STP) public struct StripeSharedStrings {
    @_spi(STP) public static func localizedStateString(for countryCode: String?) -> String {
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
