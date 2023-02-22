//
//  LinkPaymentController.swift
//  StripePaymentSheet
//
//  Created by Bill Meltsner on 12/9/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// `LinkPaymentController` encapsulates the Link payment flow, allowing you to let your customers pay with their Link account.
/// This feature is currently invite-only. To accept payments, [use the Mobile Payment Element.](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(LinkOnly) public class LinkPaymentController {

    private let mode: PaymentSheet.InitializationMode
    private let configuration: PaymentSheet.Configuration

    private var intent: Intent?
    private var payWithLinkContinuation: CheckedContinuation<Void, Swift.Error>?
    private var paymentOption: PaymentOption?

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
                completion(.success(()))
            } catch {
                completion(.failure(error))
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
        let linkController: PayWithLinkViewController = try await withCheckedThrowingContinuation { [self] continuation in
            PaymentSheet.load(mode: mode, configuration: configuration) { result in
                switch result {
                case .success(let intent, _, let isLinkEnabled):
                    guard isLinkEnabled else {
                        continuation.resume(throwing: LinkPaymentController.Error.unavailable)
                        return
                    }
                    self.intent = intent
                    let linkController = PayWithLinkViewController(
                        intent: intent,
                        configuration: self.configuration,
                        shouldOfferApplePay: false,
                        shouldFinishOnClose: true,
                        callToAction: .customWithLock(title: String.Localized.continue)
                    )
                    continuation.resume(returning: linkController)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        linkController.payWithLinkDelegate = self
        linkController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad
            ? .formSheet
            : .overFullScreen

        defer { linkController.dismiss(animated: true) }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            payWithLinkContinuation = continuation
            presentingViewController.present(linkController, animated: true)
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
                completion(.completed)
            } catch Error.canceled {
                completion(.canceled)
            } catch {
                completion(.failed(error: error))
            }
        }
    }

    /// Completes the Link payment or setup.
    /// - Note: Once this method returns successfully, this `LinkPaymentController` instance should no longer be used, as payment/setup intents should not be reused. Thrown errors indicate cancellation or failure, and do not invalidate the instance.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
    /// - Throws: Either `LinkPaymentController.Error.canceled`, meaning the customer canceled the flow, or an error describing what went wrong.
    @MainActor
    @_spi(LinkOnly) public func confirm(from presentingViewController: UIViewController) async throws {
        if (intent == nil || paymentOption == nil) && LinkAccountService().hasSessionCookie {
            // If the customer has a Link cookie, `present` may not need to have been called - try to load here
            paymentOption = try await withCheckedThrowingContinuation { [self] continuation in
                PaymentSheet.load(mode: mode, configuration: configuration) { result in
                    switch result {
                    case .success(let intent, _, let isLinkEnabled):
                        guard isLinkEnabled else {
                            continuation.resume(throwing: Error.unavailable)
                            return
                        }
                        self.intent = intent
                        // TODO(bmelts): can we reliably determine the customer's previously used funding source (if any)?
                        continuation.resume(returning: .link(option: .wallet))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        guard let intent = intent, let paymentOption = paymentOption else {
            assertionFailure("`confirm` should not be called without the customer authorizing Link. Make sure to call `present` first if your customer hasn't previously selected Link as a payment method.")
            throw PaymentSheetError.unknown(debugDescription: "confirm called without authorizing Link")
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: AuthenticationContext(presentingViewController: presentingViewController, appearance: .default),
                intent: intent,
                paymentOption: paymentOption,
                paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient)
            ) { result in
                switch result {
                case .completed:
                    continuation.resume()
                case .canceled:
                    continuation.resume(throwing: Error.canceled)
                case .failed(let error):
                    continuation.resume(throwing: error)
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

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension LinkPaymentController: PayWithLinkViewControllerDelegate {
    func payWithLinkViewControllerDidConfirm(_ payWithLinkViewController: PayWithLinkViewController, intent: Intent, with paymentOption: PaymentOption, completion: @escaping (PaymentSheetResult) -> Void) {
        self.intent = intent
        self.paymentOption = paymentOption
        completion(.completed)
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkContinuation?.resume(throwing: Error.canceled)
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult) {
        switch result {
        case .canceled:
            payWithLinkContinuation?.resume(throwing: Error.canceled)
        case .failed(let error):
            payWithLinkContinuation?.resume(throwing: error)
        case .completed:
            payWithLinkContinuation?.resume()
        }
    }
}
