//
//  CheckoutElementsApplePayContextClosureDelegate.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/30/26.
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Apple Pay context delegate for Checkout Session confirmation.
///
/// Handles the confirmation token flow: creates a confirmation token from the Apple Pay
/// payment method, then confirms the checkout session with it.
final class CheckoutElementsApplePayContextClosureDelegate: NSObject, ApplePayContextDelegate {
    let completion: PaymentSheetResultCompletionBlock
    /// Retains this instance until Apple Pay completes.
    var selfRetainer: CheckoutElementsApplePayContextClosureDelegate?
    let checkoutSession: Checkout.Session
    let elementsSession: STPElementsSession
    private weak var checkout: CheckoutSessionBillingAddressUpdater?
    // Non-nil only for checkout sessions that source tax from the billing address.
    let paymentMethodUpdateHandler:
        ((PKPaymentMethod, @escaping ((PKPaymentRequestPaymentMethodUpdate) -> Void)) -> Void)?

    init(
        checkoutSession: Checkout.Session,
        elementsSession: STPElementsSession,
        checkout: CheckoutSessionBillingAddressUpdater,
        paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        self.checkoutSession = checkoutSession
        self.elementsSession = elementsSession
        self.checkout = checkout
        self.paymentMethodUpdateHandler = paymentMethodUpdateHandler
        self.completion = completion
        super.init()
        self.selfRetainer = self
    }

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
        return try await confirmCheckoutSession(
            checkout: checkout,
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
            completion(.completed, nil)
        case .error:
            completion(.failed(error: error!), nil)
        case .userCancellation:
            completion(.canceled, nil)
        }
        selfRetainer = nil
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        if let paymentMethodUpdateHandler {
            paymentMethodUpdateHandler(paymentMethod) { result in
                handler(result)
            }
        } else {
            stpAssertionFailure("This method should not be called unless paymentMethodUpdateHandler is set")
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
        }
    }

    // Only advertise `didSelectPaymentMethod` if we have a handler for it, otherwise it'd get called
    // when there's nothing to do.
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(applePayContext(_:didSelectPaymentMethod:handler:)) {
            return paymentMethodUpdateHandler != nil
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Private

    private func confirmCheckoutSession(
        checkout: CheckoutSessionBillingAddressUpdater,
        paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        context: STPApplePayContext
    ) async throws -> String {
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            checkoutSession: checkoutSession,
            elementsSession: elementsSession
        )

        // Use the live session amount — may differ from the snapshot if billing tax was updated
        // via paymentMethodUpdateHandler before confirmation.
        let expectedAmount = await checkout.session.expectedAmount()

        let shipping = makeShippingDetailsParams(from: paymentInformation)

        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethod = paymentMethod.id
        confirmationTokenParams.returnURL = context.returnUrl
        confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata
        confirmationTokenParams.shipping = shipping
        let confirmationToken = try await context.apiClient.createConfirmationToken(
            with: confirmationTokenParams,
            ephemeralKeySecret: nil
        )

        let response = try await context.apiClient.confirmCheckoutSession(
            sessionId: checkoutSession.id,
            confirmationToken: confirmationToken.stripeId,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
            returnURL: context.returnUrl,
            shipping: shipping,
            clientAttributionMetadata: clientAttributionMetadata
        )

        try await checkout.commitSession(response)
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
