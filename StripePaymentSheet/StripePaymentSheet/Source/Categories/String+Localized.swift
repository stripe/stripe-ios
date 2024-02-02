//
//  String+Localized.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static var add_new_payment_method: String {
        STPLocalizedString(
            "Add new payment method",
            "Text for a button that, when tapped, displays another screen where the customer can add payment method details"
        )
    }

    static var pay_another_way: String {
        STPLocalizedString(
            "Pay another way",
            "Label of a button that when tapped allows the user to select a different form of payment."
        )
    }

    static func pay_faster_at_$merchant_and_thousands_of_merchants(merchantDisplayName: String) -> String {
        String(
            format: STPLocalizedString(
                "Pay faster at %@ and thousands of businesses.",
                """
                Label describing the benefit of signing up for Link.
                Pay faster at {Merchant Name} and thousands of businesses
                e.g, 'Pay faster at Example, Inc. and thousands of businesses.'
                """
            ),
            merchantDisplayName
        )
    }

    static var save_for_future_payments: String {
        STPLocalizedString(
            "Save for future payments",
            "The label of a switch indicating whether to save the payment method for future payments."
        )
    }

    static func save_this_card_for_future_$merchant_payments(merchantDisplayName: String) -> String {
        String(
            format: STPLocalizedString(
                "Save this card for future %@ payments",
                "The label of a switch indicating whether to save the user's card for future payment"
            ),
            merchantDisplayName
        )
    }

    static var ideal_bank: String {
        STPLocalizedString("iDEAL Bank", "iDEAL bank section title for iDEAL form entry.")
    }

    static var bank_account_sentence_case: String {
        STPLocalizedString("Bank account", "Title for collected bank account information")
    }

    static var pay_with_link: String {
        STPLocalizedString("Pay with Link", "Text for the 'Pay with Link' button. 'Link' is a Stripe brand, please do not translate the word 'Link'.")
    }

    static var back: String {
        STPLocalizedString("Back", "Text for back button")
    }

    static var update_card: String {
        STPLocalizedString(
            "Update card",
            """
            Title for a button that when tapped, presents a screen for updating a card. Also
            the heading the screen itself.
            """
        )
    }

    static var show_menu: String {
        STPLocalizedString(
            "Show menu",
            "Accessibility label for an action or a button that shows a menu."
        )
    }

    static var enter_address_manually: String {
        STPLocalizedString("Enter address manually", "Text for a button that allows manual entry of an address")
    }

    static func does_not_support_shipping_to(countryCode: String) -> String {
        let countryDisplayName = Locale.autoupdatingCurrent.localizedString(forRegionCode: countryCode) ?? countryCode
        return String(
            format: STPLocalizedString(
                "Shipping to %@ is not supported.",
                """
                Text for an error that is shown when a user selects a shipping address that
                is not supported by the merchant
                """
            ),
            countryDisplayName
        )
    }

    static var or: String {
        STPLocalizedString(
            "Or",
            "Separator label between two options"
        )
    }

    static var add_a_payment_method: String {
        STPLocalizedString(
            "Add a payment method",
            "Text for a button that, when tapped, displays another screen where the customer can add a new payment method"
        )
    }

    static var save_address: String {
        STPLocalizedString("Save address", "Title for address entry section")
    }

    static var approve_payment: String {
        STPLocalizedString(
            "Approve payment",
            "Text on a screen asking the user to approve a payment"
        )
    }

    static var cancel_pay_another_way: String {
        STPLocalizedString(
            "Cancel and pay another way",
            "Button text on a screen asking the user to approve a payment"
        )
    }

    static var open_upi_app: String {
        STPLocalizedString(
            "Open your UPI app to approve your payment within %@",
            "Countdown timer text on a screen asking the user to approve a payment"
        )
    }

    static var payment_failed: String {
        STPLocalizedString(
            "Payment failed",
            "Text on a screen that indicates a payment has failed"
        )
    }

    static var please_go_back: String {
        STPLocalizedString(
            "Please go back and select another payment method",
            "Text on a screen that indicates a payment has failed informing the user we are asking the user to try a different payment method"
        )
    }

    static var sepa_mandate_text: String {
        STPLocalizedString(
            "By providing your payment information and confirming this payment, you authorise (A) %@ and Stripe, our payment service provider, to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with those instructions. As part of your rights, you are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited. Your rights are explained in a statement that you can obtain from your bank. You agree to receive notifications for future debits up to 2 days before they occur.",
            "SEPA mandate text"
        )
    }

    static var bacs_mandate_text: String {
        STPLocalizedString(
            "I understand that Stripe will be collecting Direct Debits on behalf of %@ and confirm that I am the account holder and the only person required to authorise debits from this account.",
            "Bacs Debit mandate text"
        )
    }

    static var cash_app_mandate_text: String {
        STPLocalizedString(
            "By continuing, you authorize %@ to debit your Cash App account for this payment and future payments in accordance with %@'s terms, until this authorization is revoked. You can change this anytime in your Cash App Settings.",
            "Cash App mandate text"
        )
    }

    static var revolut_pay_mandate_text: String {
        STPLocalizedString(
            "By continuing to Revolut Pay, you allow %@ to charge your Revolut Pay account for future payments in accordance with their terms.",
            "Revolut Pay mandate text"
        )
    }

    static var paypal_mandate_text_payment: String {
        STPLocalizedString(
            "By confirming your payment with PayPal, you allow %@ to charge your PayPal account for future payments in accordance with their terms.",
            "Paypal mandate text"
        )
    }

    static var paypal_mandate_text_setup: String {
        STPLocalizedString(
            "By continuing to PayPal, you allow %@ to charge your PayPal account for future payments in accordance with their terms.",
            "Paypal mandate text"
        )
    }

    static var blik_confirm_payment: String {
        STPLocalizedString("Confirm the payment in your bank's app within %@ to complete the purchase.",
                           "Text for alert message when user needs to confirm payment in their banking app")
    }

    static var contact_information: String {
        STPLocalizedString("Contact information", "Title for the contact information section")
    }

    static var paynow_confirm_payment: String {
        STPLocalizedString("Confirm the payment in your bank or payment app within %@ to complete the purchase.",
                           "Text for alert message when user needs to confirm payment in their banking app")
    }

    static var cpf_cpnj: String {
        STPLocalizedString("CPF/CPNJ", "Label for CPF/CPNJ (Brazil tax ID) field")
    }
}
