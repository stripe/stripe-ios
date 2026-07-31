//
//  Checkout+ApplePay.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/31/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - CheckoutApplePayContextClosureDelegate

/// Handles Apple Pay confirmation for Checkout Session flows.
///
/// Conforms to `ApplePayContextDelegate` and uses `COMPLETE_WITHOUT_CONFIRMING_INTENT`
/// to signal `STPApplePayContext` to skip intent-based confirmation after confirming
/// the Checkout Session server-side.
final class CheckoutApplePayContextClosureDelegate: NSObject, ApplePayContextDelegate {
    private let checkoutSession: Checkout.Session
    private weak var checkout: CheckoutSessionBillingAddressUpdater?
    private let confirmHandler: (Checkout.ConfirmResult) -> Void
    private let paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?
    private var confirmedPaymentStatus: Checkout.PaymentStatus?
    /// Retains this instance until Apple Pay completes.
    var selfRetainer: CheckoutApplePayContextClosureDelegate?

    init(
        checkoutSession: Checkout.Session,
        checkout: CheckoutSessionBillingAddressUpdater,
        paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?,
        confirmHandler: @escaping (Checkout.ConfirmResult) -> Void
    ) {
        self.checkoutSession = checkoutSession
        self.checkout = checkout
        self.paymentMethodUpdateHandler = paymentMethodUpdateHandler
        self.confirmHandler = confirmHandler
        super.init()
        self.selfRetainer = self
    }

    // MARK: - ApplePayContextDelegate

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment
    ) async throws -> String {
        guard let checkout else {
            let message = "Missing Checkout controller for CheckoutSession Apple Pay confirmation."
            stpAssertionFailure(message)
            throw PaymentSheetError.unknown(debugDescription: message)
        }
        return try await handleCheckoutSessionApplePay(
            checkout: checkout,
            checkoutSession: checkoutSession,
            paymentMethod: paymentMethod,
            paymentInformation: paymentInformation,
            context: context
        )
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        switch status {
        case .success:
            confirmHandler(.succeeded(paymentStatus: confirmedPaymentStatus ?? .unknown))
        case .error:
            confirmHandler(.failed(error ?? STPApplePayContext.makeUnknownError(message: "Unknown Apple Pay error")))
        case .userCancellation:
            confirmHandler(.canceled)
        }
        selfRetainer = nil
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard let paymentMethodUpdateHandler else {
            stpAssertionFailure("didSelectPaymentMethod called with no paymentMethodUpdateHandler")
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
            return
        }
        paymentMethodUpdateHandler(paymentMethod, handler)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(applePayContext(_:didSelectPaymentMethod:handler:)) {
            return paymentMethodUpdateHandler != nil
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Private

    /// Handles Apple Pay confirmation for CheckoutSession by calling the confirm API with the payment method.
    private func handleCheckoutSessionApplePay(
        checkout: CheckoutSessionBillingAddressUpdater,
        checkoutSession: Checkout.Session,
        paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        context: STPApplePayContext
    ) async throws -> String {
        // 1. Build client attribution metadata
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: checkoutSession.elementsSession
        )

        // 2. Get expected amount from checkout session
        let expectedAmount = checkoutSession.expectedAmount()

        // 3. Extract shipping details from PKPayment (if provided)
        let shipping = makeShippingDetailsParams(from: paymentInformation)

        // 4. Call confirm API with the Apple Pay payment method
        let response = try await context.apiClient.confirmCheckoutSession(
            sessionId: checkoutSession.id,
            paymentMethod: paymentMethod.id,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
            returnURL: context.returnUrl,
            shipping: shipping,
            paymentMethodOptions: nil,
            clientAttributionMetadata: clientAttributionMetadata
        )

        // 5. Update the Checkout instance with the confirmed session response
        try await checkout.commitSession(response)

        confirmedPaymentStatus = response.paymentStatus

        // 6. Return client secret based on checkout session mode
        return try response.intentClientSecret()
    }

    private func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let shippingContact = payment.shippingContact,
              let nameComponents = shippingContact.name else {
            return nil
        }

        let name = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
        let shippingAddress = STPAddress(pkContact: shippingContact)

        guard let line1 = shippingAddress.line1 else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = shippingAddress.line2
        addressParams.city = shippingAddress.city
        addressParams.state = shippingAddress.state
        addressParams.postalCode = shippingAddress.postalCode
        addressParams.country = shippingAddress.country

        let shippingDetailsParams = STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
        shippingDetailsParams.phone = shippingAddress.phone

        return shippingDetailsParams
    }
}

// MARK: - Checkout Apple Pay

extension Checkout {

    /// Called by ExpressCheckoutElement when the user taps the Apple Pay button.
    func confirmApplePay() {
        let confirmHandler = configuration.expressCheckoutElement.confirmHandler
        guard let context = STPApplePayContext.create(checkout: self, confirmHandler: { result in
            confirmHandler?(result)
        }) else {
            confirmHandler?(.failed(CheckoutError.applePayNotSupportedOrMisconfigured))
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await enqueueSessionUpdate {
                context.presentApplePay()
            }
        }
    }
}

// MARK: - STPApplePayContext + Checkout

extension STPApplePayContext {

    @MainActor
    static func create(
        checkout: Checkout,
        confirmHandler: @escaping (Checkout.ConfirmResult) -> Void
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
        if session.collectsTaxFromBillingAddress {
            paymentRequest.requiredBillingContactFields.insert(.postalAddress)
        }

        let paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)? = {
            guard session.collectsTaxFromBillingAddress else { return nil }
            let currency = session.currency
            return { [weak checkout] pkPaymentMethod, completionHandler in
                guard let checkout else {
                    completionHandler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
                    return
                }
                Task { @MainActor [weak checkout] in
                    guard let checkout else {
                        completionHandler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
                        return
                    }
                    if let postalAddress = pkPaymentMethod.billingAddress?.postalAddresses.first?.value,
                       let address = makeCheckoutAddress(from: postalAddress) {
                        try? await checkout.updateBillingTaxRegionIfNecessary(address: address, canUpdateWhileSheetPresented: true)
                    }
                    completionHandler(PKPaymentRequestPaymentMethodUpdate(
                        paymentSummaryItems: makePaymentSummaryItems(for: checkout.session, label: label, currency: currency)
                    ))
                }
            }
        }()

        let delegate = CheckoutApplePayContextClosureDelegate(
            checkoutSession: session,
            checkout: checkout,
            paymentMethodUpdateHandler: paymentMethodUpdateHandler,
            confirmHandler: confirmHandler
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
