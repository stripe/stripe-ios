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

    static var save_your_payment_information_with_link: String {
        STPLocalizedString(
                "Save your payment information with Link, and securely check out in 1-click on Link-supported sites.",
                """
                Label describing the benefit of signing up for Link.
                """
                )
    }

    static var save_for_future_payments: String {
        STPLocalizedString(
            "Save for future payments",
            "The label of a switch indicating whether to save the payment method for future payments."
        )
    }

    static func save_payment_details_for_future_$merchant_payments(merchantDisplayName: String) -> String {
        String(
            format: STPLocalizedString(
                "Save payment details to %@ for future purchases",
                "The label of a switch indicating whether to save the user's payment details for future payment"
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

    static var bank_continue_mandate_text: String {
        STPLocalizedString("By continuing, you agree to authorize payments pursuant to <terms>these terms</terms>.", "Text providing link to terms for ACH payments")
    }

    static var back: String {
        STPLocalizedString("Back", "Text for back button")
    }

    static var manage_us_bank_account: String {
        STPLocalizedString(
            "Manage US bank account",
            "Title shown above a view containing the customer's bank account that they can delete or update"
        )
    }

    static var manage_sepa_debit: String {
        STPLocalizedString(
            "Manage SEPA debit",
            "Title shown above a view containing the customer's SEPA debit that they can delete or update"
        )
    }

    static var manage_card: String {
        STPLocalizedString(
            "Manage card",
            "Title shown above a view containing the customer's card that they can delete or update"
        )
    }

    static var manage_cards: String {
        STPLocalizedString(
            "Manage cards",
            "Title shown above a view containing a list of the customer's cards that they can delete or update"
        )
    }

    static var bank_account_details_cannot_be_changed: String {
        STPLocalizedString(
            "Bank account details cannot be changed.",
            "Text on a screen that indicates bank account details cannot be changed."
        )
    }

    static var sepa_debit_details_cannot_be_changed: String {
        STPLocalizedString(
            "SEPA debit details cannot be changed.",
            "Text on a screen that indicates SEPA debit details cannot be changed."
        )
    }

    static var card_details_cannot_be_changed: String {
        STPLocalizedString(
            "Card details cannot be changed.",
            "Text on a screen that indicates card details cannot be changed."
        )
    }

    static var only_card_brand_can_be_changed: String {
        STPLocalizedString(
            "Only card brand can be changed.",
            "Text on a screen for updating a cobranded card that indicates only card brand can be changed."
        )
    }

    static var save: String {
       STPLocalizedString(
           "Save",
           "Label on a button that when tapped, updates a card brand."
       )
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

    static var confirm_payment_details: String {
        STPLocalizedString(
            "Confirm payment details",
            """
            Title of a screen where the user can update their payment method before continuing
            with the transaction.
            """
        )
    }

    static var update_payment_method: String {
        STPLocalizedString(
            "Update payment method",
            """
            Accessibility label for a button that leads to a screen for updating a payment method.
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

    static var buy_now_or_pay_later_with_klarna: String {
        STPLocalizedString("Buy now or pay later with Klarna", "Promotional text for Klarna, displayed in a button that lets the customer pay with Klarna")
    }
    static var klarna_mandate_text: String {
        STPLocalizedString(
            "By continuing to Klarna, you allow %@ to charge your Klarna account for future payments in accordance with their terms and Klarna's terms. You can change this at any time in your Klarna app or by reaching out to %@.",
            "Klarna mandate text"
        )
    }

    static var amazon_pay_mandate_text: String {
        STPLocalizedString(
            "By continuing to Amazon Pay, you allow %@ to charge your Amazon Pay account for future payments in accordance with their terms.",
            "Amazon Pay mandate text"
        )
    }

    static var select_payment_method: String {
        STPLocalizedString(
            "Select payment method",
            "Title shown above a view containing the customer's payment methods"
        )
    }

    static var select_card: String {
        STPLocalizedString(
            "Select card",
            "Title shown above a view containing the customer's card payment methods"
        )
    }

    static var select_your_payment_method: String {
        STPLocalizedString(
            "Select your payment method",
            "Title shown above a carousel containing the customer's payment methods"
        )
    }

    static var saved: String {
        STPLocalizedString(
            "Saved",
            "Title shown above a button that represents the customer's saved payment method e.g., a saved credit card or bank account."
        )
    }

    static var new_payment_method: String {
        STPLocalizedString(
            "New payment method",
            "Title shown above a section containing payment methods that a customer can choose to pay with e.g. card, bank account, etc."
        )
    }

    static var manage_payment_methods: String {
        STPLocalizedString(
            "Manage payment methods",
            "Title shown above a view containing the customer's payment methods that they can delete or update"
        )
    }

    static var manage_payment_method: String {
        STPLocalizedString(
            "Manage payment method",
            "Title shown above a view containing the customer's payment method that they can delete or update"
        )
    }

    static var view_more: String {
        STPLocalizedString(
            "View more",
            "Text shown on a button that displays a customer's default saved payment method. When tapped, it opens a screen that shows all of the customer's saved payment methods."
        )
    }

    static var add_card: String {
        STPLocalizedString(
            "Add card",
            "Title shown above a view allowing the customer to save their first card."
        )
    }

    static var add_new_card: String {
        STPLocalizedString(
            "Add new card",
            "Title shown above a view allowing the customer to save a card."
        )
    }

    static var add_us_bank_account: String {
        STPLocalizedString(
            "Add US bank account",
            "Title shown above a view allowing the customer to add a US bank account."
        )
    }

    static var buy_now_or_pay_later_with_cash_app_afterpay: String {
        STPLocalizedString(
            "Buy now or pay later with Cash App Afterpay",
            "Subtitle shown on a button allowing a user to select to pay with Afterpay."
        )
    }

    static var buy_now_or_pay_later_with_afterpay: String {
        STPLocalizedString(
            "Buy now or pay later with Afterpay",
            "Subtitle shown on a button allowing a user to select to pay with Afterpay."
        )
    }

    static var buy_now_or_pay_later_with_clearpay: String {
        STPLocalizedString(
            "Buy now or pay later with Clearpay",
            "Subtitle shown on a button allowing a user to select to pay with Clearpay."
        )
    }

    static var link_subtitle_text: String {
        STPLocalizedString(
            "Simple, secure one-click payments",
            "Subtitle shown on a button allowing a user to select to pay with Link."
        )
    }

    static var new_card: String {
        STPLocalizedString(
            "New card",
            "Label of a button that appears on a checkout screen. When tapped, it displays a credit card form. This button is shown next to another button representing the customer's saved card; the word 'new' is meant to differentiate this button's action with the saved card button."
        )
    }

    static var save_this_account_for_future_payments: String {
        STPLocalizedString(
            "Save this account for future %@ payments",
            "Prompt next to checkbox to save bank account."
        )
    }

    static var by_providing_your_card_information_text: String {
        STPLocalizedString(
            "By providing your card information, you allow %@ to charge your card for future payments in accordance with their terms.",
            "Text displayed below a credit card entry form when the card will be saved to make future payments."
        )
    }

    static var confirm_your_cvc: String {
        STPLocalizedString("Confirm your CVC", "Title for prompting for a card's CVC on confirming the payment")
    }

    static var confirm: String {
        STPLocalizedString("Confirm", "Title used for various UIs, including a button that confirms entered payment details or the selection of a payment method.")
    }

    static var bank: String {
        STPLocalizedString("Bank", "A label used in various UIs, including a button that represents a payment method type 'Bank' - where a user can pay with their bank account instead of, say, a credit card.")
    }

    static var pay_over_time_with_affirm: String {
        STPLocalizedString(
            "Pay over time with Affirm",
            "Promotional text for Affirm, displayed in a button that lets the customer pay with Affirm"
        )
    }

    static var default_text: String {
        STPLocalizedString(
            "Default",
            "Label for identifying the default payment method."
       )
    }

    static var default_payment_method: String {
        STPLocalizedString(
            "Default payment method",
            "Label for a disabled checked checkbox identifying the default payment method."
       )
    }

    static var set_as_default_payment_method: String {
        STPLocalizedString(
            "Set as default payment method",
            "Label of a checkbox that when checked makes a payment method as the default one."
        )
    }

    static var change: String {
        STPLocalizedString(
            "Change",
            "Label for a button that lets you change the details of a payment method"
       )
    }

    static var please_choose_a_valid_payment_method: String {
        STPLocalizedString(
            "Please choose a valid payment method.",
            "Error message that's displayed when you try to confirm a payment without a valid payment method"
       )
    }
}
