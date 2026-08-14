//
//  STPApplePayContext+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPApplePayContext {
    /// Builds Apple Pay summary items from a checkout session's current state.
    /// Returns a pending total row when no payment is required or the total is unavailable.
    static func makePaymentSummaryItems(
        for session: Checkout.Session,
        label: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        guard !session.noPaymentRequired, let total = session.total else {
            return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
        }

        var summaryItems: [PKPaymentSummaryItem] = []

        for orderSummaryItem in session.orderSummaryItems {
            switch orderSummaryItem {
            case .oneTimePrice(let oneTimePrice):
                for item in oneTimePrice.items {
                    let itemLabel = item.quantity > 1
                        ? String.Localized.lineItemLabel(name: item.displayName, quantity: item.quantity)
                        : item.displayName
                    // Prefer unitAmountDecimal for the edge case where the Stripe API doesn't return a `unitAmount`
                    // (and so becomes 0) for prices with sub-cent precision like $0.1234.
                    let unitAmount = item.unitAmountDecimal ?? item.unitAmount
                    let amount = NSDecimalNumber(value: unitAmount.minorUnitsAmount)
                        .multiplying(by: NSDecimalNumber(value: item.quantity))
                        .multiplying(by: NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency))
                    summaryItems.append(
                        PKPaymentSummaryItem(label: itemLabel, amount: amount, type: .final)
                    )
                }
            }
        }

        let shipping = total.shippingRate.minorUnitsAmount
        let tax = total.taxExclusive.minorUnitsAmount
        let discount = total.discount.minorUnitsAmount

        // Skip the breakdown rows when there's nothing to break down — the product rows already sum to the total.
        let hasModifiers = shipping != 0 || tax != 0 || discount != 0
        if hasModifiers {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: String.Localized.subtotal,
                    amount: NSDecimalNumber.stp_decimalNumber(
                        withAmount: total.subtotal.minorUnitsAmount,
                        currency: currency
                    ),
                    type: .final
                )
            )
            if shipping != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.shipping,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: shipping, currency: currency),
                        type: .final
                    )
                )
            }
            if tax != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.tax,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: tax, currency: currency),
                        type: .final
                    )
                )
            }
            if discount != 0 {
                // `discount` is non-negative; flip the sign so Apple Pay shows it as a deduction.
                let amount = NSDecimalNumber.stp_decimalNumber(withAmount: discount, currency: currency)
                let negativeAmount = NSDecimalNumber(decimal: -amount.decimalValue)
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.discount,
                        amount: negativeAmount,
                        type: .final
                    )
                )
            }
        }

        // Apple Pay convention: the last item is the grand total.
        summaryItems.append(
            PKPaymentSummaryItem(
                label: label,
                amount: NSDecimalNumber.stp_decimalNumber(
                    withAmount: total.total.minorUnitsAmount,
                    currency: currency
                ),
                type: .final
            )
        )

        return summaryItems
    }

    // Partial billing address from the Apple Pay sheet (no street until authorization).
    // Returns nil if there's no country to key tax on.
    static func makeCheckoutAddress(from postalAddress: CNPostalAddress) -> Checkout.Address? {
        guard let country = postalAddress.isoCountryCode.nonEmpty else {
            return nil
        }
        return Checkout.Address(
            country: country,
            line1: nil,
            line2: nil,
            city: postalAddress.city.nonEmpty,
            state: postalAddress.state.nonEmpty,
            postalCode: postalAddress.postalCode.nonEmpty
        )
    }

    /// Converts default billing details into a `PKContact` for pre-populating the Apple Pay sheet.
    static func makeBillingContact(from billingDetails: PaymentSheet.BillingDetails) -> PKContact {
        let contact = PKContact()

        if let name = billingDetails.name {
            contact.name = PersonNameComponentsFormatter().personNameComponents(from: name)
        }

        if let phone = billingDetails.phone {
            contact.phoneNumber = CNPhoneNumber(stringValue: phone)
        }

        let postalAddress = CNMutablePostalAddress()
        let address = billingDetails.address
        postalAddress.isoCountryCode = address.country ?? ""

        var streetComponents: [String] = []
        if let line1 = address.line1 { streetComponents.append(line1) }
        if let line2 = address.line2 { streetComponents.append(line2) }
        if !streetComponents.isEmpty {
            postalAddress.street = streetComponents.joined(separator: "\n")
        }

        if let city = address.city {
            postalAddress.city = city
        }

        if let state = address.state {
            postalAddress.state = state
        }

        if let postalCode = address.postalCode {
            postalAddress.postalCode = postalCode
        }

        contact.postalAddress = postalAddress
        return contact
    }
}
