//
//  Checkout+ApplePay.swift
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

/// Manages an active Apple Pay session.
/// Owns the `PKPaymentAuthorizationController` and acts as its delegate directly.
@MainActor
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {

    enum PaymentState {
        case notStarted
        case pending    // confirm is in flight — cannot cancel
        case success
        case error
    }
    private weak var checkout: Checkout?
    private let apiClient: STPAPIClient
    private let paymentHandler: STPPaymentHandler
    private let authorizationController: PKPaymentAuthorizationController
    private var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?
    private var result: Checkout.InternalConfirmResult?
    private var paymentState: PaymentState = .notStarted
    /// Set when Apple Pay times out or the user cancels while a confirm call is in flight.
    /// Dismissal is deferred until the in-flight confirm finishes.
    private var didCancelOrTimeoutWhilePending = false
    private let session: Checkout.Session
    private let returnURL: String?
    private let authenticationContext: STPAuthenticationContext
    /// Captured at init time so `presentationWindow(for:)` can be called nonisolated.
    private let presentationWindow: UIWindow?

    private init(
        checkout: Checkout,
        apiClient: STPAPIClient,
        paymentHandler: STPPaymentHandler,
        authorizationController: PKPaymentAuthorizationController,
        returnURL: String?,
        authenticationContext: STPAuthenticationContext
    ) {
        self.checkout = checkout
        self.session = checkout.session
        self.apiClient = apiClient
        self.paymentHandler = paymentHandler
        self.authorizationController = authorizationController
        self.returnURL = returnURL
        self.authenticationContext = authenticationContext
        self.presentationWindow = authenticationContext.authenticationPresentingViewController().view.window
        super.init()
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task { @MainActor in
            do {
                // 1. Create PaymentMethod (PaymentState still .notStarted here — failure is recoverable)
                let currentSession = self.checkout?.session ?? self.session
                let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                    intent: .checkout(currentSession),
                    elementsSession: currentSession.elementsSession
                )
                var fallbackBillingDetails: StripeAPI.BillingDetails?
                if let email = currentSession.email {
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

                // 2. Confirm — set .pending first, cannot cancel after this.
                // Guard: if continuation is already nil, paymentAuthorizationControllerDidFinish
                // fired (timeout or cancel) while PM creation was in flight. Proceeding would
                // charge the customer while the app already reported .canceled.
                guard self.continuation != nil else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    return
                }
                self.paymentState = .pending
                let savePaymentMethod: Bool? = currentSession.noPaymentRequired ? nil
                    : currentSession.merchantWillSavePaymentMethod(STPPaymentMethodType.card) ? true : nil
                let response = try await self.apiClient.confirmCheckoutSession(
                    sessionId: currentSession.id,
                    paymentMethod: paymentMethod.id,
                    expectedAmount: currentSession.expectedAmount(),
                    expectedPaymentMethodType: paymentMethod.type?.rawValue ?? STPPaymentMethodType.card.identifier,
                    savePaymentMethod: savePaymentMethod,
                    returnURL: self.returnURL,
                    shipping: self.makeShippingDetailsParams(from: payment),
                    clientAttributionMetadata: clientAttributionMetadata
                )

                // 3. Handle next actions
                let paymentSheetResult = try await Checkout.handleCheckoutSessionConfirmResponse(
                    response: response,
                    returnURL: self.returnURL,
                    authenticationContext: self.authenticationContext,
                    paymentHandler: self.paymentHandler
                )

                // 4. Commit the confirmed session back to Checkout so its state stays current.
                try await self.checkout?.commitSession(response)

                self.paymentState = .success
                self.result = .init(
                    paymentSheetResult: paymentSheetResult,
                    checkoutSessionResponse: response
                )

                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    // TODO: Add a willCompleteWithResult hook so callers can attach PKPaymentOrderDetails.
                    switch paymentSheetResult {
                    case .completed:
                        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                    case .canceled, .failed:
                        completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    }
                }
            } catch {
                self.paymentState = .error
                self.result = .init(paymentSheetResult: .failed(error: error))
                let pkError = STPAPIClient.pkPaymentError(forStripeError: error)
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError].compactMap { $0 }))
                }
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        Task { @MainActor in
            switch self.paymentState {
            case .notStarted:
                await controller.dismiss()
                self.resume(with: .init(paymentSheetResult: .canceled))
            case .pending:
                // A confirm call is in flight — defer dismissal until it completes.
                self.didCancelOrTimeoutWhilePending = true
            case .success:
                await controller.dismiss()
                self.resume(with: self.result ?? .init(paymentSheetResult: .canceled))
            case .error:
                await controller.dismiss()
                self.resume(with: self.result ?? .init(paymentSheetResult: .failed(error: CheckoutError.unknown(debugDescription: "Apple Pay finished in error state without a result."))))
            }
        }
    }

    nonisolated func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return presentationWindow
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

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(paymentAuthorizationController(_:didSelectPaymentMethod:handler:)) {
            // TODO: Update billing tax region when the user switches cards.
            return false
        }
        if aSelector == #selector(paymentAuthorizationController(_:didSelectShippingContact:handler:)) {
            // TODO: Collect shipping address and update shipping tax region.
            return false
        }
        if aSelector == #selector(paymentAuthorizationController(_:didChangeCouponCode:handler:)) {
            // TODO: Wire up coupon code handling.
            return false
        }
        if aSelector == #selector(paymentAuthorizationController(_:didSelectShippingMethod:handler:)) {
            // TODO: Handle multiple shipping rates from the session.
            return false
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Factory

    static func create(
        checkout: Checkout,
        authenticationContext: STPAuthenticationContext
    ) throws -> CheckoutApplePayContext {
        guard checkout.configuration.applePayConfiguration != nil else {
            throw CheckoutError.applePayNotConfigured
        }
        let applePayConfig = checkout.configuration.applePayConfiguration!

        guard PKPaymentAuthorizationController.canMakePayments() else {
            throw CheckoutError.applePayUnavailable
        }

        // TODO: Product Usage

        let checkoutSession = checkout.session
        let countryCode = checkoutSession.elementsSession.merchantCountryCode ?? "US"
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfig.merchantId,
            country: countryCode,
            currency: checkoutSession.currency ?? "USD"
        )

        assert(!paymentRequest.merchantIdentifier.isEmpty, "You must set `merchantId` on `Checkout.ApplePayConfiguration`.")

        let merchantLabel = checkout.configuration.merchantDisplayName ?? checkoutSession.businessName ?? ""
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
            checkout: checkout,
            apiClient: checkout.apiClient,
            paymentHandler: checkout.paymentHandler,
            authorizationController: authorizationController,
            returnURL: checkout.configuration.returnURL,
            authenticationContext: authenticationContext
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

    // MARK: - Private Helpers

    private func summaryItems() -> [PKPaymentSummaryItem] {
        let session = checkout?.session ?? self.session
        let label = checkout?.configuration.merchantDisplayName ?? session.businessName ?? ""
        return Self.makeSummaryItems(for: session, label: label)
    }

    // TODO: Build summary items from session line items, tax, shipping, and discounts.
    static func makeSummaryItems(for session: Checkout.Session, label: String) -> [PKPaymentSummaryItem] {
        if let amount = session.expectedAmount() {
            return [PKPaymentSummaryItem(label: label, amount: NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: session.currency), type: .final)]
        }
        return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
    }

    private func resume(with result: Checkout.InternalConfirmResult) {
        guard let c = continuation else { return }
        continuation = nil
        c.resume(returning: result)
    }

    /// Called when Apple Pay timed out or was canceled while a confirm was in flight.
    /// The completion block from `didAuthorizePayment` is not called — instead we dismiss directly.
    private func finishAndDismiss() {
        Task { @MainActor in
            await self.authorizationController.dismiss()
            self.resume(with: self.result ?? .init(paymentSheetResult: .canceled))
        }
    }

    // MARK: - Static Helpers

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
