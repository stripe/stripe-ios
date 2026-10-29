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
    @_spi(InternalOnlyAPI) public static var card_number: String {
        STPLocalizedString("Card number", "Label for card number entry text field")
    }

    @_spi(InternalOnlyAPI) public static var card_brand_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ ending in %2$@",
            "Details of a saved card. '{card brand} ending in {last 4}' e.g. 'VISA ending in 4242'"
        )
    }

    @_spi(InternalOnlyAPI) public static var bank_name_account_ending_in_last_4: String {
        STPLocalizedString(
            "%1$@ account ending in %2$@",
            "Details of a saved bank account. '{bank name} account ending in {last 4}' e.g. 'Chase account ending in 4242'"
        )
    }

    @_spi(InternalOnlyAPI) public static var apple_pay: String {
        STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
    }

    @_spi(InternalOnlyAPI) public static var allow_camera_access: String {
        STPLocalizedString(
            "To scan your card, allow camera access in Settings.",
            "Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."
        )
    }

    @_spi(InternalOnlyAPI) public static var shipping_address: String {
        STPLocalizedString("Shipping Address", "Title for shipping address entry section")
    }

    @_spi(InternalOnlyAPI) public static var cvc_section_title: String {
        STPLocalizedString(
            "Confirm your %@",
            "Section title for entering your CVC. e.g. 'Confirm your CVC'"
        )
    }

    @_spi(InternalOnlyAPI) public static var card_information: String {
        STPLocalizedString("Card information", "Card details entry form header title")
    }

    @_spi(InternalOnlyAPI) public static var your_card_has_expired: String {
        STPLocalizedString(
            "Your card has expired.",
            "Error message for card details form when expiration date has passed"
        )
    }

    @_spi(InternalOnlyAPI) public static var your_cards_expiration_year_is_invalid: String {
        STPLocalizedString(
            "Your card's expiration year is invalid.",
            "String to describe an invalid year in expiry date."
        )
    }

    @_spi(InternalOnlyAPI) public static var brand_not_allowed: String {
        STPLocalizedString(
            "%1$@ is not accepted",
            "String to inform a user that specific card brands are not accepted. E.g. American Express is not accepted"
        )
    }

    @_spi(InternalOnlyAPI) public static var generic_brand_not_allowed: String {
        STPLocalizedString(
            "The selected brand is not allowed",
            "String to inform a user that specific card brands are not accepted."
        )
    }

    // MARK: - Card Funding Filter Messages
    // Complete strings for each funding type combination to ensure proper localization context

    // Single funding types
    @_spi(InternalOnlyAPI) public static var only_debit_cards_accepted: String {
        STPLocalizedString(
            "Only debit cards are accepted",
            "Warning shown when only debit cards are accepted"
        )
    }

    @_spi(InternalOnlyAPI) public static var only_credit_cards_accepted: String {
        STPLocalizedString(
            "Only credit cards are accepted",
            "Warning shown when only credit cards are accepted"
        )
    }

    @_spi(InternalOnlyAPI) public static var only_prepaid_cards_accepted: String {
        STPLocalizedString(
            "Only prepaid cards are accepted",
            "Warning shown when only prepaid cards are accepted"
        )
    }

    // Two funding types
    @_spi(InternalOnlyAPI) public static var only_debit_and_credit_cards_accepted: String {
        STPLocalizedString(
            "Only debit and credit cards are accepted",
            "Warning shown when only debit and credit cards are accepted"
        )
    }

    @_spi(InternalOnlyAPI) public static var only_debit_and_prepaid_cards_accepted: String {
        STPLocalizedString(
            "Only debit and prepaid cards are accepted",
            "Warning shown when only debit and prepaid cards are accepted"
        )
    }

    @_spi(InternalOnlyAPI) public static var only_credit_and_prepaid_cards_accepted: String {
        STPLocalizedString(
            "Only credit and prepaid cards are accepted",
            "Warning shown when only credit and prepaid cards are accepted"
        )
    }

    @_spi(InternalOnlyAPI) public enum Funding {
        @_spi(InternalOnlyAPI) public static var credit: String {
            STPLocalizedString(
                "%1$@ Credit",
                "Label a credit funding source. E.g. in english 'Visa Credit', or in german 'Visa-Kreditkarte'"
            )
        }

        @_spi(InternalOnlyAPI) public static var debit: String {
            STPLocalizedString(
                "%1$@ Debit",
                "Label a debit funding source. E.g. 'Visa Debit'"
            )
        }

        @_spi(InternalOnlyAPI) public static var prepaid: String {
            STPLocalizedString(
                "%1$@ Prepaid",
                "Label a prepaid funding source. E.g. 'Visa Prepaid'"
            )
        }

        @_spi(InternalOnlyAPI) public static var `default`: String {
            STPLocalizedString(
                "%1$@ Card",
                "Label a default funding source, which we treat as a generic card. E.g. 'Visa Card'"
            )
        }
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
