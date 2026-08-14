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

/// Responsible for handling the Apple Pay flow end to end: displaying line items,
/// collecting billing and shipping, updating tax region, and confirming the Checkout Session.
/// Owns the `PKPaymentAuthorizationController` and acts as its delegate directly.
@MainActor
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {

    enum PaymentState {
        case notStarted
        case pending
        case error
        case success
    }

    private weak var sessionUpdater: ExpressCheckoutSessionUpdater?
    private let session: Checkout.Session
    private let merchantLabel: String
    private let apiClient: STPAPIClient
    private let returnURL: String?
    let authorizationController: PKPaymentAuthorizationController

    // Internal state
    private var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?
    var result: Checkout.InternalConfirmResult?
    var paymentState: PaymentState = .notStarted
    /// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didAuthorize) resumes our continuation
    var didCancelOrTimeoutWhilePending = false
    /// Whether or not we fully completed the flow - if didFinish is `true`, that means `_end()` was called and this class is unusable.
    private var didFinish = false

    init(
        checkoutSession: Checkout.Session,
        confirmationContext: Checkout.ApplePayConfirmationContext,
        sessionUpdater: ExpressCheckoutSessionUpdater,
        authorizationController: PKPaymentAuthorizationController
    ) {
        self.session = checkoutSession
        self.sessionUpdater = sessionUpdater
        self.merchantLabel = confirmationContext.merchantDisplayName
        self.apiClient = confirmationContext.apiClient
        self.returnURL = confirmationContext.returnURL
        self.authorizationController = authorizationController
        super.init()
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Some observations (on iOS 12 simulator):
        // - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't seen this.
        // - If you call the completion block w/ a status of .failure and an error, the user is prompted to try again.

        Task {
            // Helpers to handle annoying logic around "Do I call completion block or dismiss + call delegate?"
            // Helper 1: Handle failure
            let handleFailure = { (error: Error) in
                self.paymentState = .error
                self.result = .init(paymentSheetResult: .failed(error: error))
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    let pkError = STPAPIClient.pkPaymentError(forStripeError: error)
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError].compactMap { $0 }))
                }
            }
            // Helper 2: Handle success
            let handleSuccess = { (paymentSheetResult: PaymentSheetResult, response: PaymentPagesAPIResponse) in
                self.paymentState = .success
                self.result = .init(paymentSheetResult: paymentSheetResult, checkoutSessionResponse: response)
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    switch paymentSheetResult {
                    case .completed:
                        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                    case .canceled, .failed:
                        completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    }
                }
            }

            do {
                // 1. Create PaymentMethod
                let checkoutSession = self.session
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
                let paymentMethod = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StripeAPI.PaymentMethod, Error>) in
                    StripeAPI.PaymentMethod.create(
                        apiClient: self.apiClient,
                        payment: payment,
                        fallbackBillingDetails: fallbackBillingDetails,
                        clientAttributionMetadata: clientAttributionMetadata
                    ) { result in
                        continuation.resume(with: result)
                    }
                }
                guard !self.didFinish else {
                    return // The user canceled mid-payment - just abort
                }
                self.paymentState = .pending  // After this point, we can't cancel
                let savePaymentMethod: Bool? = checkoutSession.noPaymentRequired ? nil
                    : checkoutSession.merchantWillSavePaymentMethod(STPPaymentMethodType.card) ? true : nil

                // 2. Confirm
                let response = try await self.apiClient.confirmCheckoutSession(
                    sessionId: checkoutSession.id,
                    paymentMethod: paymentMethod.id,
                    expectedAmount: checkoutSession.expectedAmount(),
                    expectedPaymentMethodType: paymentMethod.type?.rawValue ?? STPPaymentMethodType.card.identifier,
                    savePaymentMethod: savePaymentMethod,
                    returnURL: self.returnURL,
                    shipping: self.makeShippingDetailsParams(from: payment),
                    clientAttributionMetadata: clientAttributionMetadata
                )

                // We can't present a next action here (the Apple Pay sheet is still up), so fail fast
                // instead of routing through `handleNextAction`
                if let responseStatus = self.responseStatus(response) {
                    handleFailure(CheckoutError.applePayRequiresNextAction(status: responseStatus))
                    return
                }

                // 3. Commit the confirmed session back to Checkout so its state stays current.
                // The payment already succeeded at this point, so a failure here shouldn't be
                // reported to the customer as a failed payment - just log it.
                do {
                    try await self.sessionUpdater?.commitSession(response)
                } catch {
                    let errorAnalytic = ErrorAnalytic(
                        event: .unexpectedPaymentSheetConfirmationError,
                        error: error
                    )
                    STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                }

                // TODO: post-next-action work

                handleSuccess(.completed, response)

            } catch {
                handleFailure(error)
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // Note: If you don't dismiss the VC, the UI disappears, the VC blocks interaction, and this method gets called again.
        // Note: This method is called if the user cancels (taps outside the sheet) or Apple Pay times out (empirically ~30 seconds)
        switch paymentState {
        case .notStarted:
            Task {
                await controller.dismiss()
                self.resume(with: .init(paymentSheetResult: .canceled))
                self._end()
            }
        case .pending:
            // We can't cancel a pending payment. If we dismiss the VC now, the customer might interact with the app and miss seeing the result of the payment - risking a double charge, chargeback, etc.
            // Instead, we'll dismiss and notify our delegate when the payment finishes.
            didCancelOrTimeoutWhilePending = true
        case .error:
            Task {
                await controller.dismiss()
                self.resume(with: self.result ?? .init(paymentSheetResult: .failed(error: CheckoutError.unknown(debugDescription: "Apple Pay finished in error state without a result."))))
                self._end()
            }
        case .success:
            Task {
                await controller.dismiss()
                self.resume(with: self.result ?? .init(paymentSheetResult: .canceled))
                self._end()
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        // TODO: Update billing tax region when the user switches cards.
        handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: summaryItems()))
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        // TODO: Collect shipping address, update shipping/billing tax region, validate against allowedShippingCountries.
        handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: summaryItems()))
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        // TODO: Handle multiple shipping rates from the session.
        handler(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: summaryItems()))
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        // TODO: Wire up coupon code handling.
        handler(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: summaryItems()))
    }

    // MARK: - Factory

    static func create(
        checkoutSession: Checkout.Session,
        confirmationContext: Checkout.ApplePayConfirmationContext,
        sessionUpdater: ExpressCheckoutSessionUpdater
    ) throws -> CheckoutApplePayContext {
        guard let applePayConfig = confirmationContext.applePayConfiguration else {
            throw CheckoutError.applePayNotConfigured
        }

        guard PKPaymentAuthorizationController.canMakePayments() else {
            throw CheckoutError.applePayUnavailable
        }

        // TODO: Product Usage

        let countryCode = checkoutSession.elementsSession.merchantCountryCode ?? "US"
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfig.merchantId,
            country: countryCode,
            currency: checkoutSession.currency ?? "USD"
        )

        assert(!paymentRequest.merchantIdentifier.isEmpty, "You must set `merchantId` on `Checkout.ApplePayConfiguration`.")

        let merchantLabel = confirmationContext.merchantDisplayName
        paymentRequest.paymentSummaryItems = CheckoutApplePayContext.makeSummaryItems(for: checkoutSession, label: merchantLabel)

        // TODO: Set requiredShippingContactFields when shipping address collection is implemented.

        // PKPaymentAuthorizationController.init is non-nullable even for invalid requests.
        // Use PKPaymentAuthorizationViewController.init as a proxy — it IS nullable and
        // returns nil when the request can't be presented (e.g. bad merchant ID, unsupported network).
        guard PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil else {
            throw CheckoutError.applePayUnavailable
        }
        let authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        return CheckoutApplePayContext(
            checkoutSession: checkoutSession,
            confirmationContext: confirmationContext,
            sessionUpdater: sessionUpdater,
            authorizationController: authorizationController
        )
    }

    // MARK: - Present

    func presentApplePay() async -> Checkout.InternalConfirmResult {
        authorizationController.delegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            authorizationController.present { [weak self] presented in
                guard let self, !presented else { return }
                Task { @MainActor [weak self] in
                    self?.resume(with: .init(paymentSheetResult: .failed(error: CheckoutError.applePayUnavailable)))
                }
            }
        }
    }

    // MARK: - Helpers

    private func summaryItems() -> [PKPaymentSummaryItem] {
        return Self.makeSummaryItems(for: session, label: merchantLabel)
    }

    // TODO: Build summary items from session line items, tax, shipping, and discounts.
    static func makeSummaryItems(for session: Checkout.Session, label: String) -> [PKPaymentSummaryItem] {
        if let amount = session.expectedAmount() {
            return [PKPaymentSummaryItem(label: label, amount: NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: session.currency), type: .final)]
        }
        return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
    }

    private func _end() {
        authorizationController.delegate = nil
        didFinish = true
    }

    private func resume(with result: Checkout.InternalConfirmResult) {
        guard let c = continuation else { return }
        continuation = nil
        c.resume(returning: result)
    }

    private func finishAndDismiss() {
        Task { @MainActor in
            await self.authorizationController.dismiss()
            self.resume(with: self.result ?? .init(paymentSheetResult: .canceled))
            self._end()
        }
    }

    private func responseStatus(_ response: PaymentPagesAPIResponse) -> String? {
        if let paymentIntent = response.paymentIntent,
           paymentIntent.status != .succeeded, paymentIntent.status != .requiresCapture {
            return String(describing: paymentIntent.status)
        }
        if let setupIntent = response.setupIntent, setupIntent.status != .succeeded {
            return String(describing: setupIntent.status)
        }
        return nil
    }

    private func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let shippingContact = payment.shippingContact,
              let nameComponents = shippingContact.name else {
            return nil
        }

        let name = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
        let shippingAddress = STPAddress(pkContact: shippingContact)

        // country is required by the API; skip shipping if it's absent (e.g. simulator fixtures).
        guard let line1 = shippingAddress.line1,
              let country = shippingAddress.country else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = shippingAddress.line2
        addressParams.city = shippingAddress.city
        addressParams.state = shippingAddress.state
        addressParams.postalCode = shippingAddress.postalCode
        addressParams.country = country

        let shippingDetailsParams = STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
        shippingDetailsParams.phone = shippingAddress.phone

        return shippingDetailsParams
    }
}
