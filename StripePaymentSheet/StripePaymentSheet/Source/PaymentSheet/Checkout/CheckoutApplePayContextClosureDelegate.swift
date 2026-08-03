//
//  CheckoutApplePayContextClosureDelegate.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/31/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

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
    private weak var checkout: (any CheckoutSessionExpressCheckoutUpdater)?
    private let checkoutSession: Checkout.Session
    private let paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?
    private let shippingContactUpdateHandler: ((PKContact, @escaping (PKPaymentRequestShippingContactUpdate) -> Void) -> Void)?
    private var confirmedPaymentStatus: Checkout.PaymentStatus?
    /// Retains this instance until Apple Pay completes.
    var selfRetainer: CheckoutApplePayContextClosureDelegate?

    init(
        checkout: any CheckoutSessionExpressCheckoutUpdater,
        checkoutSession: Checkout.Session,
        paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?,
        shippingContactUpdateHandler: ((PKContact, @escaping (PKPaymentRequestShippingContactUpdate) -> Void) -> Void)?
    ) {
        self.checkout = checkout
        self.checkoutSession = checkoutSession
        self.paymentMethodUpdateHandler = paymentMethodUpdateHandler
        self.shippingContactUpdateHandler = shippingContactUpdateHandler
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
        // TODO: confirm handler
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

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        guard let shippingContactUpdateHandler else {
            stpAssertionFailure("didSelectShippingContact called with no shippingContactUpdateHandler")
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: []))
            return
        }
        shippingContactUpdateHandler(contact, handler)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(applePayContext(_:didSelectPaymentMethod:handler:)) {
            return paymentMethodUpdateHandler != nil
        }
        if aSelector == #selector(applePayContext(_:didSelectShippingContact:handler:)) {
            return shippingContactUpdateHandler != nil
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Private

    /// Confirms the Checkout Session server-side using the Apple Pay payment method.
    @MainActor
    private func handleCheckoutSessionApplePay(
        checkout: any CheckoutSessionExpressCheckoutUpdater,
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

        // 2. Get expected amount from the current (post-tax-update) session
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

        // 5. TODO: Update the Checkout instance with the confirmed session response
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
