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
        taxStatus: Checkout.TaxStatus?,
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
        // Use .pending when tax hasn't been calculated yet (address still required),
        // signaling to the user that the total may change.
        let totalType: PKPaymentSummaryItemType
        switch taxStatus {
        case .requiresShippingAddress, .requiresBillingAddress:
            totalType = .pending
        default:
            totalType = .final
        }
        summaryItems.append(
            PKPaymentSummaryItem(
                label: totalLabel,
                amount: NSDecimalNumber.stp_decimalNumber(
                    withAmount: total.total.minorUnitsAmount,
                    currency: currency
                ),
                type: totalType
            )
        )

        return summaryItems
    }

    /// Converts a `Checkout.ShippingOption` into a `PKShippingMethod` for use in Apple Pay.
    static func makePKShippingMethod(from option: Checkout.ShippingOption, currency: String?) -> PKShippingMethod {
        let amount = NSDecimalNumber.stp_decimalNumber(
            withAmount: option.amount.minorUnitsAmount,
            currency: currency
        )
        let method = PKShippingMethod(label: option.displayName ?? option.id, amount: amount)
        method.identifier = option.id
        if let estimate = option.deliveryEstimate {
            method.detail = estimate.localizedDescription
        }
        return method
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

private extension Checkout.DeliveryEstimate {
    var localizedDescription: String? {
        if let min = minimum, let max = maximum, min.unit == max.unit {
            return "\(min.value)–\(max.value) \(max.unit.localizedString)"
        } else if let min = minimum {
            return "\(min.value)+ \(min.unit.localizedString)"
        } else if let max = maximum {
            return "Up to \(max.value) \(max.unit.localizedString)"
        }
        return nil
    }
}

private extension Checkout.DeliveryEstimate.Bound.Unit {
    var localizedString: String {
        switch self {
        case .hour: return "hours"
        case .day: return "days"
        case .businessDay: return "business days"
        case .week: return "weeks"
        case .month: return "months"
        case .unknown: return ""
        }
    }
}
