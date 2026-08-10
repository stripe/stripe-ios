//
//  Checkout+ApplePay.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - ApplePayPaymentState

enum ApplePayPaymentState {
    case notStarted
    case pending    // confirm is in flight — cannot cancel
    case success
    case error
}

// MARK: - CheckoutApplePaySession

struct CheckoutApplePaySession {
    let bridge: CheckoutApplePayBridge
    var controller: PKPaymentAuthorizationController
    var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?
    var result: Checkout.InternalConfirmResult?
    var paymentState: ApplePayPaymentState = .notStarted
    /// Set when Apple Pay times out or the user cancels while a confirm call is in flight.
    /// Dismissal is deferred until the in-flight confirm finishes.
    var didCancelOrTimeoutWhilePending = false
    let sessionSnapshot: Checkout.Session
    let merchantLabel: String
    let clientAttributionMetadata: STPClientAttributionMetadata
    let fallbackBillingDetails: StripeAPI.BillingDetails?
    let returnURL: String?
    let authenticationContext: STPAuthenticationContext
}

// MARK: - CheckoutApplePayBridge

/// Private NSObject bridge that satisfies `PKPaymentAuthorizationControllerDelegate`'s
/// `NSObjectProtocol` requirement and forwards all delegate calls to the owning `Checkout` instance.
final class CheckoutApplePayBridge: NSObject, PKPaymentAuthorizationControllerDelegate {
    unowned let checkout: Checkout
    /// Captured at bridge creation time so `responds(to:)` can be called nonisolated.
    private let shouldUpdateBillingTaxRegion: Bool
    private let shouldUpdateShipping: Bool

    init(checkout: Checkout, sessionSnapshot: Checkout.Session) {
        self.checkout = checkout
        self.shouldUpdateBillingTaxRegion = sessionSnapshot.shouldSendTaxRegion(for: "billing")
        self.shouldUpdateShipping = sessionSnapshot.requiresShippingAddress
            || sessionSnapshot.shouldSendTaxRegion(for: "shipping")
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        checkout.applePayDidAuthorizePayment(payment, handler: completion)
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        checkout.applePayControllerDidFinish(controller)
    }

    func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return nil
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        checkout.applePayDidSelectPaymentMethod(paymentMethod, handler: handler)
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        checkout.applePayDidSelectShippingContact(contact, handler: handler)
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        checkout.applePayDidChangeCouponCode(couponCode, handler: handler)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(paymentAuthorizationController(_:didSelectPaymentMethod:handler:)) {
            return shouldUpdateBillingTaxRegion
        }
        if aSelector == #selector(paymentAuthorizationController(_:didSelectShippingContact:handler:)) {
            return shouldUpdateShipping
        }
        if aSelector == #selector(paymentAuthorizationController(_:didChangeCouponCode:handler:)) {
            return false
        }
        return super.responds(to: aSelector)
    }
}

// MARK: - extension Checkout (Apple Pay logic)

extension Checkout {

    // MARK: - Present

    func presentApplePay(
        checkoutSession: Session,
        authenticationContext: STPAuthenticationContext
    ) async -> InternalConfirmResult {
        guard let applePayConfig = configuration.applePayConfiguration else {
            return .init(paymentSheetResult: .failed(error: CheckoutError.applePayNotSupportedOrMisconfigured))
        }

        let countryCode = checkoutSession.elementsSession.merchantCountryCode ?? "US"
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfig.merchantId,
            country: countryCode,
            currency: checkoutSession.currency ?? "USD"
        )

        let merchantLabel = checkoutSession.businessName ?? configuration.merchantDisplayName ?? ""
        paymentRequest.paymentSummaryItems = STPApplePayContext.makePaymentSummaryItems(
            for: checkoutSession,
            label: merchantLabel,
            currency: checkoutSession.currency
        )
        if checkoutSession.requiresShippingAddress {
            paymentRequest.requiredShippingContactFields.formUnion([.postalAddress, .name])
        }

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: checkoutSession.elementsSession
        )

        var fallbackBillingDetails: StripeAPI.BillingDetails?
        if let email = checkoutSession.email {
            var details = StripeAPI.BillingDetails()
            details.email = email
            fallbackBillingDetails = details
        }

        let bridge = CheckoutApplePayBridge(checkout: self, sessionSnapshot: checkoutSession)
        let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        controller.delegate = bridge

        applePaySession = CheckoutApplePaySession(
            bridge: bridge,
            controller: controller,
            sessionSnapshot: checkoutSession,
            merchantLabel: merchantLabel,
            clientAttributionMetadata: clientAttributionMetadata,
            fallbackBillingDetails: fallbackBillingDetails,
            returnURL: configuration.returnURL,
            authenticationContext: authenticationContext
        )

        return await withCheckedContinuation { continuation in
            applePaySession?.continuation = continuation
            controller.present()
        }
    }

    // MARK: - Delegate Handlers

    func applePayDidAuthorizePayment(
        _ payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task { @MainActor in
            guard let ap = self.applePaySession else { return }
            do {
                // 1. Create PaymentMethod (PaymentState still .notStarted here — failure is recoverable)
                let paymentMethodId = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    StripeAPI.PaymentMethod.create(
                        apiClient: self.apiClient,
                        payment: payment,
                        fallbackBillingDetails: ap.fallbackBillingDetails,
                        clientAttributionMetadata: ap.clientAttributionMetadata
                    ) { result in
                        continuation.resume(with: result.map { $0.id })
                    }
                }

                // 2. Confirm — set .pending first, cannot cancel after this
                self.applePaySession?.paymentState = .pending
                let response = try await self.apiClient.confirmCheckoutSession(
                    sessionId: ap.sessionSnapshot.id,
                    paymentMethod: paymentMethodId,
                    expectedAmount: ap.sessionSnapshot.expectedAmount(),
                    expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
                    returnURL: ap.returnURL,
                    shipping: self.makeApplePayShippingDetailsParams(from: payment),
                    clientAttributionMetadata: ap.clientAttributionMetadata
                )

                // 3. Handle next actions
                let paymentSheetResult = try await self.handleApplePayConfirmResponse(
                    response,
                    authenticationContext: ap.authenticationContext,
                    returnURL: ap.returnURL
                )
                self.applePaySession?.paymentState = .success
                self.applePaySession?.result = .init(
                    paymentSheetResult: paymentSheetResult,
                    checkoutSessionResponse: response
                )

                if self.applePaySession?.didCancelOrTimeoutWhilePending == true {
                    self.finishAndDismissApplePay()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                }
            } catch {
                self.applePaySession?.paymentState = .error
                self.applePaySession?.result = .init(paymentSheetResult: .failed(error: error))
                let pkError = STPAPIClient.pkPaymentError(forStripeError: error)
                if self.applePaySession?.didCancelOrTimeoutWhilePending == true {
                    self.finishAndDismissApplePay()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError].compactMap { $0 }))
                }
            }
        }
    }

    func applePayControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        guard let ap = applePaySession else { return }
        switch ap.paymentState {
        case .notStarted:
            controller.dismiss {
                DispatchQueue.main.async {
                    self.resumeApplePayContinuation(with: .init(paymentSheetResult: .canceled))
                }
            }
        case .pending:
            // A confirm call is in flight — defer dismissal until it completes.
            applePaySession?.didCancelOrTimeoutWhilePending = true
        case .success, .error:
            controller.dismiss {
                DispatchQueue.main.async {
                    self.resumeApplePayContinuation(with: self.applePaySession?.result ?? .init(paymentSheetResult: .canceled))
                }
            }
        }
    }

    func applePayDidSelectPaymentMethod(
        _ paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard let ap = applePaySession, ap.sessionSnapshot.shouldSendTaxRegion(for: "billing") else {
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: applePaySummaryItems()))
            return
        }
        guard let postalAddress = paymentMethod.billingAddress?.postalAddresses.first?.value,
              let address = STPApplePayContext.makeCheckoutAddress(from: postalAddress) else {
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: applePaySummaryItems()))
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.updateBillingTaxRegionIfNecessary(
                    address: address,
                    canUpdateWhileSheetPresented: true
                )
            } catch {
                // Best effort — return current session state on failure.
            }
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: self.applePaySummaryItems()))
        }
    }

    func applePayDidSelectShippingContact(
        _ contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        guard let ap = applePaySession,
              ap.sessionSnapshot.requiresShippingAddress || ap.sessionSnapshot.shouldSendTaxRegion(for: "shipping") else {
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: applePaySummaryItems()))
            return
        }
        guard let postalAddress = contact.postalAddress,
              let address = STPApplePayContext.makeCheckoutAddress(from: postalAddress) else {
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: applePaySummaryItems()))
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                // TODO: Validate address.country against session.allowedShippingCountries.
                try await self.updateShippingTaxRegionIfNecessary(
                    address: address,
                    canUpdateWhileSheetPresented: true
                )
            } catch {
                // Best effort — return current session state on failure.
            }
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: self.applePaySummaryItems()))
        }
    }

    func applePayDidChangeCouponCode(
        _ couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        // TODO: Wire up coupon code handling.
        handler(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: applePaySummaryItems()))
    }

    // MARK: - Private Helpers

    /// Regenerates summary items from the live session so post-update tax amounts are reflected.
    @MainActor func applePaySummaryItems() -> [PKPaymentSummaryItem] {
        let label = applePaySession?.merchantLabel ?? (configuration.merchantDisplayName ?? "")
        return STPApplePayContext.makePaymentSummaryItems(for: session, label: label, currency: session.currency)
    }

    private func resumeApplePayContinuation(with result: InternalConfirmResult) {
        applePaySession?.continuation?.resume(returning: result)
        applePaySession = nil
    }

    /// Called when Apple Pay timed out or was canceled while a confirm was in flight.
    /// The completion block from `didAuthorizePayment` is not called — instead we dismiss directly.
    private func finishAndDismissApplePay() {
        guard let ap = applePaySession else { return }
        ap.controller.dismiss {
            DispatchQueue.main.async {
                self.resumeApplePayContinuation(with: self.applePaySession?.result ?? .init(paymentSheetResult: .canceled))
            }
        }
    }

    @MainActor
    private func handleApplePayConfirmResponse(
        _ response: PaymentPagesAPIResponse,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?
    ) async throws -> PaymentSheetResult {
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
            throw PaymentSheetError.unknown(
                debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent"
            )
        }
    }

    private func makeApplePayShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
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
