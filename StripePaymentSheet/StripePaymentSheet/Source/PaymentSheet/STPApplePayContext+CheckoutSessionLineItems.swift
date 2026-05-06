//
//  STPApplePayContext+CheckoutSessionLineItems.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

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
        totals: Checkout.Totals,
        totalLabel: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        var summaryItems: [PKPaymentSummaryItem] = []

        for lineItem in lineItems {
            let label = lineItem.quantity > 1
                ? String.Localized.lineItemLabel(name: lineItem.name, quantity: lineItem.quantity)
                : lineItem.name
            let amount = NSDecimalNumber.stp_decimalNumber(
                withAmount: lineItem.unitAmount * lineItem.quantity,
                currency: currency
            )
            summaryItems.append(PKPaymentSummaryItem(label: label, amount: amount, type: .final))
        }

        // Skip the breakdown rows when there's nothing to break down — line items already sum to the total.
        let hasModifiers = totals.shipping != 0 || totals.tax != 0 || totals.discount != 0
        if hasModifiers {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: String.Localized.subtotal,
                    amount: NSDecimalNumber.stp_decimalNumber(withAmount: totals.subtotal, currency: currency),
                    type: .final
                )
            )
            if totals.shipping != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.shipping,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: totals.shipping, currency: currency),
                        type: .final
                    )
                )
            }
            if totals.tax != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.tax,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: totals.tax, currency: currency),
                        type: .final
                    )
                )
            }
            if totals.discount != 0 {
                // `totals.discount` is non-negative; flip the sign so Apple Pay shows it as a deduction.
                let amount = NSDecimalNumber.stp_decimalNumber(withAmount: totals.discount, currency: currency)
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
                amount: NSDecimalNumber.stp_decimalNumber(withAmount: totals.total, currency: currency),
                type: .final
            )
        )

        return summaryItems
    }
}
