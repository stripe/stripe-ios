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

/// Manages an active Apple Pay session.
/// Owns the `PKPaymentAuthorizationController` and acts as its delegate directly.
@MainActor
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {

    enum PaymentState {
        case notStarted
        case pending
        case error
        case success
    }

    private weak var checkout: CheckoutConfirmDataSource?
    private let session: Checkout.Session
    private let merchantLabel: String
    private let apiClient: STPAPIClient
    private let paymentHandler: STPPaymentHandler
    private let returnURL: String?
    var authorizationController: PKPaymentAuthorizationController
    private let authenticationContext: STPAuthenticationContext
    private let presentationWindow: UIWindow?

    // Internal state
    private var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?
    var result: Checkout.InternalConfirmResult?
    var paymentState: PaymentState = .notStarted
    /// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didAuthorize) resumes our continuation
    var didCancelOrTimeoutWhilePending = false
    /// Whether or not we fully completed the flow - if didFinish is `true`, that means `_end()` was called and this class is unusable.
    private var didFinish = false

    init(
        checkout: CheckoutConfirmDataSource,
        authorizationController: PKPaymentAuthorizationController,
        authenticationContext: STPAuthenticationContext
    ) {
        self.checkout = checkout
        self.session = checkout.session
        self.merchantLabel = checkout.merchantDisplayName
        self.apiClient = checkout.apiClient
        self.paymentHandler = checkout.paymentHandler
        self.returnURL = checkout.returnURL
        self.authorizationController = authorizationController
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
                    // TODO: Add a willCompleteWithResult hook so callers can attach PKPaymentOrderDetails.
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
                let currentSession = self.checkout?.session ?? self.session
                let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                    intent: .checkout(currentSession),
                    elementsSession: currentSession.elementsSession
                )
                var details = StripeAPI.BillingDetails()
                details.email = currentSession.email
                let fallbackBillingDetails: StripeAPI.BillingDetails? = details
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

                handleSuccess(paymentSheetResult, response)
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
        checkout: CheckoutConfirmDataSource,
        authenticationContext: STPAuthenticationContext
    ) throws -> CheckoutApplePayContext {
        guard let applePayConfig = checkout.applePayConfiguration else {
            throw CheckoutError.applePayNotConfigured
        }

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

        let merchantLabel = checkout.merchantDisplayName
        paymentRequest.paymentSummaryItems = CheckoutApplePayContext.makeSummaryItems(for: checkoutSession, label: merchantLabel)
        let billingDetailsCollectionConfiguration = checkout.expressCheckoutElementBillingDetailsCollectionConfiguration
        paymentRequest.requiredBillingContactFields = CheckoutApplePayContext.makeRequiredBillingContactFields(
            from: billingDetailsCollectionConfiguration
        )
        paymentRequest.requiredShippingContactFields = CheckoutApplePayContext.makeRequiredShippingContactFieldsForBilling(
            from: billingDetailsCollectionConfiguration
        )
        // TODO: Union in shipping address fields when shipping address collection is implemented.

        // PKPaymentAuthorizationController.init is non-nullable even for invalid requests.
        // Use PKPaymentAuthorizationViewController.init as a proxy — it IS nullable and
        // returns nil when the request can't be presented (e.g. bad merchant ID, unsupported network).
        guard PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil else {
            throw CheckoutError.applePayUnavailable
        }
        let authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        return CheckoutApplePayContext(
            checkout: checkout,
            authorizationController: authorizationController,
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

    // MARK: - Helpers

    private func summaryItems() -> [PKPaymentSummaryItem] {
        let session = checkout?.session ?? self.session
        return Self.makeSummaryItems(for: session, label: merchantLabel)
    }

    /// - Note: There's no `.never` case for `address`, since suppressing billing address collection isn't supported with a Checkout Session.
    static func makeRequiredBillingContactFields(
        from configuration: ExpressCheckoutElement.Configuration.BillingDetailsCollectionConfiguration
    ) -> Set<PKContactField> {
        var requiredFields = Set<PKContactField>()
        requiredFields.insert(.postalAddress)
        if configuration.name == .always {
            requiredFields.insert(.name)
        }
        return requiredFields
    }

    /// Apple Pay collects phone and email through the shipping contact, even when they're used as billing details.
    static func makeRequiredShippingContactFieldsForBilling(
        from configuration: ExpressCheckoutElement.Configuration.BillingDetailsCollectionConfiguration
    ) -> Set<PKContactField> {
        var requiredFields = Set<PKContactField>()
        if configuration.email == .always {
            requiredFields.insert(.emailAddress)
        }
        if configuration.phone == .always {
            requiredFields.insert(.phoneNumber)
        }
        return requiredFields
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
