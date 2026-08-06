//
//  STPApplePayContext+Checkout.swift
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

    @MainActor
    static func create(
        checkout: Checkout
    ) -> STPApplePayContext? {
        guard let applePayConfig = checkout.configuration.applePayConfiguration else {
            return nil
        }

        let session = checkout.session
        let countryCode = session.elementsSession.merchantCountryCode ?? "US"
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfig.merchantId,
            country: countryCode,
            currency: session.currency ?? "USD"
        )

        let label = session.businessName ?? checkout.configuration.merchantDisplayName ?? ""
        paymentRequest.paymentSummaryItems = makePaymentSummaryItems(
            for: session,
            label: label,
            currency: session.currency
        )
        if session.requiresShippingAddress {
            paymentRequest.requiredShippingContactFields.formUnion([.postalAddress, .name])
        }

        // All session updates from within the sheet go through this protocol reference.
        let updater: any CheckoutSessionExpressCheckoutUpdater = checkout

        // TODO: Wire up billing address tax updates (didSelectPaymentMethod → updateBillingTaxRegionIfNecessary).
        let paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)? = nil

        // TODO: Wire up shipping contact handler: country validation + shipping tax updates (didSelectShippingContact → updateShippingTaxRegionIfNecessary).
        let shippingContactUpdateHandler: ((PKContact, @escaping (PKPaymentRequestShippingContactUpdate) -> Void) -> Void)? = nil

        let delegate = CheckoutApplePayContextClosureDelegate(
            checkout: updater,
            checkoutSession: checkout.session,
            paymentMethodUpdateHandler: paymentMethodUpdateHandler,
            shippingContactUpdateHandler: shippingContactUpdateHandler
        )

        guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) else {
            delegate.selfRetainer = nil
            return nil
        }

        context.apiClient = checkout.apiClient
        context.returnUrl = checkout.configuration.returnURL
        context.clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(session),
            elementsSession: session.elementsSession
        )
        if let email = session.email {
            var billingDetails = StripeAPI.BillingDetails()
            billingDetails.email = email
            context.fallbackBillingDetails = billingDetails
        }
        return context
    }

    /// Builds Apple Pay summary items from a checkout session's current state.
    /// Falls back to a single total row (or .pending) when line items aren't available.
    static func makePaymentSummaryItems(
        for session: Checkout.Session,
        label: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        guard !session.lineItems.isEmpty, let total = session.total else {
            if let amount = session.expectedAmount() {
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: currency)
                return [PKPaymentSummaryItem(label: label, amount: decimalAmount, type: .final)]
            } else {
                return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
            }
        }

        var summaryItems: [PKPaymentSummaryItem] = []

        for lineItem in session.lineItems {
            let itemLabel = lineItem.quantity > 1
                ? String.Localized.lineItemLabel(name: lineItem.name, quantity: lineItem.quantity)
                : lineItem.name
            let unitMinorUnits = lineItem.unitAmount?.minorUnitsAmount ?? 0
            let amount = NSDecimalNumber.stp_decimalNumber(
                withAmount: unitMinorUnits * lineItem.quantity,
                currency: currency
            )
            summaryItems.append(PKPaymentSummaryItem(label: itemLabel, amount: amount, type: .final))
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

    // Partial billing/shipping address from the Apple Pay sheet (no street until authorization).
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
