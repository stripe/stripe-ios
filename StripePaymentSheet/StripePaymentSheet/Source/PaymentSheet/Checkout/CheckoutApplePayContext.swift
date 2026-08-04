//
//  CheckoutApplePayContext.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - CheckoutApplePayContext

/// Manages the Apple Pay sheet and confirms Checkout Sessions using ConfirmationTokens.
///
/// Unlike `STPApplePayContext`, this class does not go through a PaymentIntent/SetupIntent
/// confirmation flow. It creates a ConfirmationToken from the Apple Pay payment and calls
/// the Checkout Session confirm API directly.
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {

    // MARK: - Properties

    private let checkoutSession: Checkout.Session
    private let apiClient: STPAPIClient
    private let returnURL: String?
    private let clientAttributionMetadata: STPClientAttributionMetadata
    private let fallbackBillingDetails: StripeAPI.BillingDetails?
    private let authenticationContext: STPAuthenticationContext
    private let paymentHandler: STPPaymentHandler
    private let authorizationController: PKPaymentAuthorizationController
    private let paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?
    private let shippingContactUpdateHandler: ((PKContact, @escaping (PKPaymentRequestShippingContactUpdate) -> Void) -> Void)?

    /// Retains `self` until Apple Pay completes.
    private var selfRetainer: CheckoutApplePayContext?
    private var authorizationResult: Checkout.InternalConfirmResult?
    private var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?

    // MARK: - Factory

    @MainActor
    static func create(
        checkout: Checkout,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) -> CheckoutApplePayContext? {
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
        paymentRequest.paymentSummaryItems = STPApplePayContext.makePaymentSummaryItems(
            for: session,
            label: label,
            currency: session.currency
        )
        if session.requiresShippingAddress {
            paymentRequest.requiredShippingContactFields.formUnion([.postalAddress, .name])
        }

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(session),
            elementsSession: session.elementsSession
        )

        var fallbackBillingDetails: StripeAPI.BillingDetails?
        if let email = session.email {
            var details = StripeAPI.BillingDetails()
            details.email = email
            fallbackBillingDetails = details
        }

        // TODO: Wire up billing address tax updates (didSelectPaymentMethod → updateBillingTaxRegionIfNecessary).
        // TODO: Wire up shipping contact handler: country validation + shipping tax updates (didSelectShippingContact → updateShippingTaxRegionIfNecessary).

        return CheckoutApplePayContext(
            checkoutSession: session,
            apiClient: checkout.apiClient,
            returnURL: checkout.configuration.returnURL,
            clientAttributionMetadata: clientAttributionMetadata,
            fallbackBillingDetails: fallbackBillingDetails,
            authenticationContext: authenticationContext,
            paymentHandler: paymentHandler,
            paymentRequest: paymentRequest,
            paymentMethodUpdateHandler: nil,
            shippingContactUpdateHandler: nil
        )
    }

    // MARK: - Init

    init(
        checkoutSession: Checkout.Session,
        apiClient: STPAPIClient,
        returnURL: String?,
        clientAttributionMetadata: STPClientAttributionMetadata,
        fallbackBillingDetails: StripeAPI.BillingDetails?,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        paymentRequest: PKPaymentRequest,
        paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) -> Void)?,
        shippingContactUpdateHandler: ((PKContact, @escaping (PKPaymentRequestShippingContactUpdate) -> Void) -> Void)?
    ) {
        self.checkoutSession = checkoutSession
        self.apiClient = apiClient
        self.returnURL = returnURL
        self.clientAttributionMetadata = clientAttributionMetadata
        self.fallbackBillingDetails = fallbackBillingDetails
        self.authenticationContext = authenticationContext
        self.paymentHandler = paymentHandler
        self.paymentMethodUpdateHandler = paymentMethodUpdateHandler
        self.shippingContactUpdateHandler = shippingContactUpdateHandler
        self.authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        super.init()
        self.authorizationController.delegate = self
    }

    // MARK: - Present

    /// Presents the Apple Pay sheet and awaits the result.
    func present() async -> Checkout.InternalConfirmResult {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.selfRetainer = self
            authorizationController.present()
        }
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task { @MainActor in
            do {
                // 1. Create ConfirmationToken directly from Apple Pay token (no separate PaymentMethod needed)
                let confirmationToken = try await createConfirmationToken(from: payment)

                // 2. Confirm Checkout Session with ConfirmationToken
                let response = try await apiClient.confirmCheckoutSession(
                    sessionId: checkoutSession.id,
                    confirmationToken: confirmationToken.stripeId,
                    expectedAmount: checkoutSession.expectedAmount(),
                    expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
                    returnURL: returnURL,
                    shipping: makeShippingDetailsParams(from: payment),
                    clientAttributionMetadata: clientAttributionMetadata
                )

                // 4. Handle any next actions (e.g. 3DS — uncommon for Apple Pay)
                let paymentSheetResult = try await handleConfirmResponse(response)
                authorizationResult = .init(paymentSheetResult: paymentSheetResult, checkoutSessionResponse: response)
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            } catch {
                authorizationResult = .init(paymentSheetResult: .failed(error: error))
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                let result = self.authorizationResult ?? .init(paymentSheetResult: .canceled)
                self.selfRetainer = nil
                self.continuation?.resume(returning: result)
                self.continuation = nil
            }
        }
    }

    func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return nil
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard let paymentMethodUpdateHandler else {
            stpAssertionFailure("didSelectPaymentMethod called with no handler")
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
            return
        }
        paymentMethodUpdateHandler(paymentMethod, handler)
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        guard let shippingContactUpdateHandler else {
            stpAssertionFailure("didSelectShippingContact called with no handler")
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: []))
            return
        }
        shippingContactUpdateHandler(contact, handler)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(paymentAuthorizationController(_:didSelectPaymentMethod:handler:)) {
            return paymentMethodUpdateHandler != nil
        }
        if aSelector == #selector(paymentAuthorizationController(_:didSelectShippingContact:handler:)) {
            return shippingContactUpdateHandler != nil
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Private

    /// Creates a ConfirmationToken from a PKPayment without a separate PaymentMethod creation step.
    /// Flow: PKPayment → Stripe Token → ConfirmationToken (via paymentMethodData).
    private func createConfirmationToken(from payment: PKPayment) async throws -> STPConfirmationToken {
        let params = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<STPConfirmationTokenParams, Error>) in
            STPConfirmationTokenParams.create(
                apiClient: apiClient,
                payment: payment,
                fallbackBillingDetails: fallbackBillingDetails,
                returnURL: returnURL,
                shipping: makeShippingDetailsParams(from: payment),
                clientAttributionMetadata: clientAttributionMetadata
            ) { result in
                continuation.resume(with: result)
            }
        }
        return try await apiClient.createConfirmationToken(with: params, ephemeralKeySecret: nil)
    }

    @MainActor
    private func handleConfirmResponse(_ response: PaymentPagesAPIResponse) async throws -> PaymentSheetResult {
        if let setupIntent = response.setupIntent {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: setupIntent,
                    with: authenticationContext,
                    returnURL: returnURL
                ) { status, _, error in
                    continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
                }
            }
        } else if let paymentIntent = response.paymentIntent {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: paymentIntent,
                    with: authenticationContext,
                    returnURL: returnURL
                ) { status, _, error in
                    continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
                }
            }
        } else {
            throw PaymentSheetError.unknown(debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent")
        }
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
