//
//  STPApplePayContext+CheckoutSessionLineItems.swift
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
    /// Builds Apple Pay summary items from a CheckoutSession's line items and totals.
    ///
    /// One row per line item, optional Subtotal/Shipping/Tax/Discount rows, then the grand total.
    /// Callers must guard against empty `lineItems` and fall back to default summary items.
    static func makeApplePayPaymentSummaryItems(
        lineItems: [Checkout.LineItem],
        total: Checkout.Total,
        totalLabel: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        var summaryItems: [PKPaymentSummaryItem] = []

        for lineItem in lineItems {
            let label = lineItem.quantity > 1
                ? String.Localized.lineItemLabel(name: lineItem.name, quantity: lineItem.quantity)
                : lineItem.name
            let unitMinorUnits = lineItem.unitAmount?.minorUnitsAmount ?? 0
            let amount = NSDecimalNumber.stp_decimalNumber(
                withAmount: unitMinorUnits * lineItem.quantity,
                currency: currency
            )
            summaryItems.append(PKPaymentSummaryItem(label: label, amount: amount, type: .final))
        }

        let shipping = total.shippingRate.minorUnitsAmount
        let tax = total.taxExclusive.minorUnitsAmount
        let discount = total.discount.minorUnitsAmount

        // Skip the breakdown rows when there's nothing to break down — line items already sum to the total.
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
                label: totalLabel,
                amount: NSDecimalNumber.stp_decimalNumber(
                    withAmount: total.total.minorUnitsAmount,
                    currency: currency
                ),
                type: .final
            )
        )

        return summaryItems
    }

    // Apple Pay summary items for the checkout session's current state. Used both to build the initial
    // request and to refresh the sheet after a tax recalc, so the two stay structurally identical.
    // Prefers itemized line items, falls back to a single total row (or a .pending row if amount unknown).
    static func checkoutPaymentSummaryItems(
        checkout: Checkout,
        label: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        let session: Checkout.Session = checkout.nonisolatedSession
        if !session.lineItems.isEmpty, let total = session.total {
            return makeApplePayPaymentSummaryItems(
                lineItems: session.lineItems,
                total: total,
                totalLabel: label,
                currency: currency
            )
        } else if let amount = session.expectedAmount() {
            let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: currency)
            return [PKPaymentSummaryItem(label: label, amount: decimalAmount, type: .final)]
        } else {
            return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
        }
    }

    // Checkout.Address from the partial billing address Apple Pay exposes while the sheet is open. nil if
    // there's no country to key tax on. line1/line2 are omitted: Apple withholds the street until
    // authorization, so we only get country/city/state/postal here (enough for a tax region).
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

    /// Converts a `Checkout.ContactAddress` into a `PKContact` for pre-populating the Apple Pay sheet.
    static func makeBillingContact(from contactAddress: Checkout.ContactAddress) -> PKContact {
        let contact = PKContact()

        if let name = contactAddress.name {
            contact.name = PersonNameComponentsFormatter().personNameComponents(from: name)
        }

        if let phone = contactAddress.phone {
            contact.phoneNumber = CNPhoneNumber(stringValue: phone)
        }

        let postalAddress = CNMutablePostalAddress()
        let address = contactAddress.address
        postalAddress.isoCountryCode = address.country

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
