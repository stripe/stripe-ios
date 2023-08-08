//
//  LinkPaymentController.swift
//  StripePaymentSheet
//
//  Created by Bill Meltsner on 12/9/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// `LinkPaymentController` encapsulates the Link payment flow, allowing you to let your customers pay with their Link account.
/// This feature is currently invite-only. To accept payments, [use the Mobile Payment Element.](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet)
@_spi(LinkOnly) public class LinkPaymentController: NSObject {
    private let mode: PaymentSheet.InitializationMode
    private let configuration: PaymentSheet.Configuration

    private var payWithLinkContinuation: CheckedContinuation<Void, Swift.Error>?
    private var paymentMethodId: String?
    private var instantDebitsOnlyAuthenticationSessionManager: InstantDebitsOnlyAuthenticationSessionManager? {
        willSet {
            instantDebitsOnlyAuthenticationSessionManager?.cancel()
        }
    }

    private lazy var loadingViewController: LoadingViewController = {
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: PaymentSheet.Appearance.default,
            isTestMode: configuration.apiClient.isTestmode,
            loadingViewHeight: 244
        )
        return loadingViewController
    }()

    @_spi(LinkOnly) public struct PaymentOptionDisplayData {
        /// An image representing a payment method; e.g. the Link logo
        public let image: UIImage
        /// A user facing string representing the payment method; e.g. "Link" or "····4242" for a card
        public let label: String
    }

    /// Contains information about the customer's desired payment option.
    /// You can use this to e.g. display the payment option in your UI.
    @_spi(LinkOnly) public var paymentOption: PaymentOptionDisplayData? {
        if paymentMethodId == nil { return nil }

        return PaymentOptionDisplayData(image: Image.pm_type_link.makeImage(), label: STPPaymentMethodType.link.displayName)
    }

    /// The parent view controller to present
    private lazy var bottomSheetViewController: BottomSheetViewController = {
        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: PaymentSheet.Appearance.default,
            isTestMode: configuration.apiClient.isTestmode,
            didCancelNative3DS2: {}
        )
        return vc
    }()

    /// Initializes a new `LinkPaymentController` instance.
    /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter returnURL: A URL that redirects back to your app for flows that complete authentication in another app (such as a bank app).
    /// - Parameter billingDetails: Any information about the customer you've already collected.
    @_spi(LinkOnly) public convenience init(paymentIntentClientSecret: String, returnURL: String? = nil, billingDetails: PaymentSheet.BillingDetails? = nil) {
        self.init(intentSecret: .paymentIntentClientSecret(paymentIntentClientSecret), returnURL: returnURL, billingDetails: billingDetails)
    }

    /// Initializes a new `LinkPaymentController` instance.
    /// - Parameter setupIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe SetupIntent object
    /// - Parameter returnURL: A URL that redirects back to your app for flows that complete authentication in another app (such as a bank app).
    /// - Parameter billingDetails: Any information about the customer you've already collected.
    @_spi(LinkOnly) public convenience init(setupIntentClientSecret: String, returnURL: String? = nil, billingDetails: PaymentSheet.BillingDetails? = nil) {
        self.init(intentSecret: .setupIntentClientSecret(setupIntentClientSecret), returnURL: returnURL, billingDetails: billingDetails)
    }

    /// Initializes a new `LinkPaymentController` instance.
    /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter returnURL: A URL that redirects back to your app for flows that complete authentication in another app (such as a bank app).
    /// - Parameter billingDetails: Any information about the customer you've already collected.
    @_spi(LinkOnly) public convenience init(intentConfiguration: PaymentSheet.IntentConfiguration, returnURL: String? = nil, billingDetails: PaymentSheet.BillingDetails? = nil) {
        self.init(intentSecret: .deferredIntent(intentConfiguration), returnURL: returnURL, billingDetails: billingDetails)
    }

    private init(intentSecret: PaymentSheet.InitializationMode, returnURL: String?, billingDetails: PaymentSheet.BillingDetails?) {
        self.mode = intentSecret
        var configuration = PaymentSheet.Configuration()
        configuration.linkPaymentMethodsOnly = true
        configuration.returnURL = returnURL
        if let billingDetails = billingDetails {
            configuration.defaultBillingDetails = billingDetails
        }
        self.configuration = configuration
    }

    /// Presents the Link payment flow, allowing your customer to pay with Link.
    /// The flow lets your customer log into or create a Link account, select a valid source of funds, and approve the usage of those funds to complete the purchase. The actual purchase will not occur until you call `confirm(from:completion:)`.
    /// - Note: Once `confirm(from:completion:)` completes successfully (i.e. when `result` is `.success`), calling this method is an error, as payment/setup intents should not be reused. Until then, you may call this method as many times as is necessary.
    /// - Parameter presentingViewController: The view controller to present the payment flow from.
    /// - Parameter completion: Called when the payment flow is dismissed. If the flow was completed successfully, the result will be `.success`, and you can call `confirm(from:completion:)` when you're ready to complete the payment. If it was not, the result will be `.failure` with an `Error` describing what happened; this will be `LinkPaymentController.Error.canceled` if the customer canceled the flow.
    @_spi(LinkOnly) public func present(from presentingViewController: UIViewController, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        Task {
            do {
                try await present(from: presentingViewController)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Presents the Link payment flow, allowing your customer to pay with Link.
    /// The flow lets your customer log into or create a Link account, select a valid source of funds, and approve the usage of those funds to complete the purchase. The actual purchase will not occur until you call `confirm(from:)`.
    /// If this method returns successfully, you can call `confirm(from:)` when you're ready to complete the payment.
    /// - Note: Once `confirm(from:)` returns successfully, calling this method is an error, as payment/setup intents should not be reused. Until then, you may call this method as many times as is necessary.
    /// - Parameter presentingViewController: The view controller to present the payment flow from.
    /// - Throws: Either `LinkPaymentController.Error.canceled`, meaning the customer canceled the flow, or an error describing what went wrong.
    @MainActor
    @_spi(LinkOnly) public func present(from presentingViewController: UIViewController) async throws {
        presentingViewController.presentAsBottomSheet(bottomSheetViewController, appearance: PaymentSheet.Appearance.default)
        defer {
            bottomSheetViewController.dismiss(animated: true)
        }
        let manifest: Manifest = try await withCheckedThrowingContinuation { [self] continuation in
            let apiClient = self.configuration.apiClient
            let parameters: [String: Any] = [
                "attach_required": false,
                "product": "instant_debits",
            ]
            switch mode {
            case .paymentIntentClientSecret(let clientSecret):
                guard let paymentIntentId = STPPaymentIntent.id(fromClientSecret: clientSecret) else {
                    continuation.resume(throwing: PaymentSheetError.invalidClientSecret)
                    return
                }
                apiClient.createLinkAccountSession(paymentIntentID: paymentIntentId,
                                                   clientSecret: clientSecret,
                                                   paymentMethodType: .link,
                                                   customerName: configuration.defaultBillingDetails.name,
                                                   customerEmailAddress: configuration.defaultBillingDetails.email,
                                                   additionalParameteres: parameters) { [weak self] linkAccountSession, error in
                    self?.generateManifest(continuation: continuation, error: error, linkAccountSession: linkAccountSession)
                }
            case .setupIntentClientSecret(let clientSecret):
                guard let setupIntentId = STPSetupIntent.id(fromClientSecret: clientSecret) else {
                    continuation.resume(throwing: PaymentSheetError.invalidClientSecret)
                    return
                }
                apiClient.createLinkAccountSession(setupIntentID: setupIntentId,
                                                   clientSecret: clientSecret,
                                                   paymentMethodType: .link,
                                                   customerName: configuration.defaultBillingDetails.name,
                                                   customerEmailAddress: configuration.defaultBillingDetails.email,
                                                   additionalParameteres: parameters) { [weak self] linkAccountSession, error in
                    self?.generateManifest(continuation: continuation, error: error, linkAccountSession: linkAccountSession)
                }
            case .deferredIntent(let intentConfiguration):
                let amount: Int?
                let currency: String?
                switch intentConfiguration.mode {
                case let .payment(amount: _amount, currency: _currency, _, _):
                    amount = _amount
                    currency = _currency
                case let .setup(currency: _currency, _):
                    amount = nil
                    currency = _currency
                }
                apiClient
                    .createLinkAccountSessionForDeferredIntent(
                        sessionId: "ios_instant_debits_only_\(UUID().uuidString)",
                        amount: amount,
                        currency: currency,
                        onBehalfOf: intentConfiguration.onBehalfOf,
                        additionalParameters: ["product": "instant_debits"]
                    ) { [weak self] linkAccountSession, error in
                        self?.generateManifest(continuation: continuation, error: error, linkAccountSession: linkAccountSession)
                    }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            payWithLinkContinuation = continuation
            instantDebitsOnlyAuthenticationSessionManager = InstantDebitsOnlyAuthenticationSessionManager(window: presentingViewController.view.window)
            instantDebitsOnlyAuthenticationSessionManager?
                .start(manifest: manifest)
                .observe { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let successResult):
                        switch successResult {
                        case .success(let details):
                            self.paymentMethodId = details.paymentMethodID
                            self.payWithLinkContinuation?.resume(returning: ())
                        case.canceled:
                            self.paymentMethodId = nil
                            self.payWithLinkContinuation?.resume(throwing: Error.canceled)
                        }
                    case .failure(let error):
                        self.paymentMethodId = nil
                        self.payWithLinkContinuation?.resume(throwing: error)
                    }
                    self.payWithLinkContinuation = nil
                }
        }
    }

    private func generateManifest(continuation: CheckedContinuation<Manifest, Swift.Error>,
                                  error: Swift.Error?,
                                  linkAccountSession: LinkAccountSession?) {
        if let error = error {
            continuation.resume(throwing: error)
            return
        }

        guard let linkAccountSession = linkAccountSession else {
            continuation.resume(throwing: PaymentSheetError.failedToCreateLinkSession)
            return
        }

        configuration.apiClient.generatedLinkAccountSessionManifest(with: linkAccountSession.clientSecret) { result in
            switch result {
            case .success(let manifest):
                continuation.resume(returning: manifest)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }

    /// Completes the Link payment or setup.
    /// - Note: Once `completion` is called with a `.completed` result, this `LinkPaymentController` instance should no longer be used, as payment/setup intents should not be reused. Other results indicate cancellation or failure, and do not invalidate the instance.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
    /// - Parameter completion: Called with the result of the payment after any presented view controllers are dismissed
    @_spi(LinkOnly) public func confirm(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        Task {
            do {
                try await confirm(from: presentingViewController)
                DispatchQueue.main.async {
                    completion(.completed)
                }
            } catch Error.canceled {
                DispatchQueue.main.async {
                    completion(.canceled)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failed(error: error))
                }
            }
        }
    }

    /// Completes the Link payment or setup.
    /// - Note: Once this method returns successfully, this `LinkPaymentController` instance should no longer be used, as payment/setup intents should not be reused. Thrown errors indicate cancellation or failure, and do not invalidate the instance.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
    /// - Throws: Either `LinkPaymentController.Error.canceled`, meaning the customer canceled the flow, or an error describing what went wrong.
    @MainActor
    @_spi(LinkOnly) public func confirm(from presentingViewController: UIViewController) async throws {
        guard let paymentMethodId = paymentMethodId else {
            assertionFailure("`confirm` should not be called without the customer authorizing Link. Make sure to call `present` first if your customer hasn't previously selected Link as a payment method.")
            throw PaymentSheetError.linkNotAuthorized
        }
        let authenticationContext = AuthenticationContext(presentingViewController: presentingViewController, appearance: .default)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            switch mode {
            case .paymentIntentClientSecret(let clientSecret):
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret, paymentMethodType: .link)
                paymentIntentParams.paymentMethodId = paymentMethodId
                paymentIntentParams.mandateData = STPMandateDataParams.makeWithInferredValues()
                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams, with: authenticationContext
                ) { (status, _, error) in
                    switch status {
                    case .canceled:
                        continuation.resume(throwing: Error.canceled)
                    case .failed:
                        continuation.resume(throwing: error ?? Error.canceled)
                    case .succeeded:
                        continuation.resume()
                    @unknown default:
                        fatalError()
                    }
                }
            case .setupIntentClientSecret(let clientSecret):
                let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret, paymentMethodType: .link)
                setupIntentParams.paymentMethodID = paymentMethodId
                setupIntentParams.mandateData = STPMandateDataParams.makeWithInferredValues()
                STPPaymentHandler.shared().confirmSetupIntent(
                    setupIntentParams, with: authenticationContext
                ) { (status, _, error) in
                    switch status {
                    case .canceled:
                        continuation.resume(throwing: Error.canceled)
                    case .failed:
                        continuation.resume(throwing: error ?? Error.canceled)
                    case .succeeded:
                        continuation.resume()
                    @unknown default:
                        fatalError()
                    }
                }
            case .deferredIntent(let intentConfiguration):
                let paymentMethod = STPPaymentMethod(stripeId: paymentMethodId)
                PaymentSheet
                    .handleDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod),
                        configuration: configuration,
                        intentConfig: intentConfiguration,
                        authenticationContext: authenticationContext,
                        paymentHandler: STPPaymentHandler.shared(),
                        isFlowController: true,
                        mandateData: STPMandateDataParams.makeWithInferredValues()) { result, _ in
                    switch result {
                    case .canceled:
                        continuation.resume(throwing: Error.canceled)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    case .completed:
                        continuation.resume()

                    }
                }
            }
        }
    }

    /// Deletes all Link authentication state associated with a customer.
    ///
    /// You must call this method when the user logs out from your app.
    /// This will ensure that any persisted authentication state, such as authentication cookies, is also cleared during logout.
    @_spi(LinkOnly) public static func resetCustomer() {
        PaymentSheet.resetCustomer()
    }

    /// Errors related to the Link payment flow
    ///
    /// Most errors do not originate from LinkPaymentController itself; instead, they come from the Stripe API or other SDK components
    @frozen @_spi(LinkOnly) public enum Error: Swift.Error {
        /// The customer canceled the flow they were in.
        case canceled
        /// Link is unavailable at this time.
        case unavailable
    }
}

@_spi(LinkOnly)
extension LinkPaymentController: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        instantDebitsOnlyAuthenticationSessionManager = nil
        paymentMethodId = nil
        payWithLinkContinuation?.resume(throwing: Error.canceled)
        payWithLinkContinuation = nil
    }
}
