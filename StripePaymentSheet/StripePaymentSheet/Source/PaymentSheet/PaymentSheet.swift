//
//  PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit

/// The result of an attempt to confirm a PaymentIntent or SetupIntent
@frozen public enum PaymentSheetResult {
    /// The customer completed the payment or setup
    /// - Note: The payment may still be processing at this point; don't assume money has successfully moved.
    ///
    /// Your app should transition to a generic receipt view (e.g. a screen that displays "Your order is confirmed!"), and
    /// fulfill the order (e.g. ship the product to the customer) after receiving a successful payment event from Stripe -
    /// see https://stripe.com/docs/payments/handling-payment-events
    case completed

    /// The customer canceled the payment or setup attempt
    case canceled

    /// An error occurred.
    /// - Note: `PaymentSheet` returns this only when an unrecoverable error is encountered (e.g. if PaymentSheet fails to load). In other cases, the error is shown directly to the user in the sheet (e.g. if payment failed).
    ///   `PaymentSheet.FlowController` returns this whenever an error is encountered.
    /// - Parameter error: The error encountered by the customer. You can display its `localizedDescription` to the customer.
    case failed(error: Error)

    internal var error: Error? {
        switch self {
        case .failed(error: let error):
            return error
        default:
            return nil
        }
    }
}

/// A drop-in class that presents a sheet for a customer to complete their payment
public class PaymentSheet {
    enum InitializationMode {
        case paymentIntentClientSecret(String)
        case setupIntentClientSecret(String)
        case deferredIntent(PaymentSheet.IntentConfiguration)
        case checkoutSession(STPCheckoutSession)

        var intentConfig: PaymentSheet.IntentConfiguration? {
            switch self {
            case .deferredIntent(let intentConfig):
                return intentConfig
            case .paymentIntentClientSecret, .setupIntentClientSecret, .checkoutSession:
                return nil
            }
        }

        var isDeferred: Bool {
            if case .deferredIntent = self {
                return true
            }
            return false
        }
    }

    /// This contains all configurable properties of PaymentSheet
    public let configuration: Configuration

    /// The most recent error encountered by the customer, if any.
    public internal(set) var mostRecentError: Error?

    /// Initializes a PaymentSheet
    /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    public convenience init(paymentIntentClientSecret: String, configuration: Configuration) {
        self.init(
            mode: .paymentIntentClientSecret(paymentIntentClientSecret),
            configuration: configuration
        )
    }

    /// Initializes a PaymentSheet
    /// - Parameter setupIntentClientSecret: The [client secret](https://stripe.com/docs/api/setup_intents/object#setup_intent_object-client_secret) of a Stripe SetupIntent object
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    public convenience init(setupIntentClientSecret: String, configuration: Configuration) {
        self.init(
            mode: .setupIntentClientSecret(setupIntentClientSecret),
            configuration: configuration
        )
    }

    /// Initializes PaymentSheet with an `IntentConfiguration`
    /// - Parameter intentConfiguration: Information about the payment or setup used to render the PaymentSheet UI
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    public convenience init(intentConfiguration: IntentConfiguration, configuration: Configuration) {
        self.init(
            mode: .deferredIntent(intentConfiguration),
            configuration: configuration
        )
    }

    /// Initializes PaymentSheet with a Checkout object
    /// - Parameter checkout: A fully loaded Checkout instance whose ``Checkout.session`` is non-nil.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    @MainActor @_spi(CheckoutSessionsPreview) public convenience init(checkout: Checkout, configuration: Configuration) {
        guard let stpSession = checkout.session as? STPCheckoutSession else {
            fatalError("Expected STPCheckoutSession, got \(type(of: checkout.session))")
        }
        var config = configuration
        stpSession.applyAddressOverrides(to: &config)
        self.init(
            mode: .checkoutSession(stpSession),
            configuration: config
        )
        self.checkout = checkout
        checkout.integrationDelegate = self
    }

    required init(mode: InitializationMode, configuration: Configuration) {
        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.self)
        self.mode = mode
        self.configuration = configuration
        self.analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration)
        analyticsHelper.logInitialized()
    }

    /// Presents a sheet for a customer to complete their payment
    /// - Parameter presentingViewController: The view controller to present a payment sheet
    /// - Parameter completion: Called with the result of the payment after the payment sheet is dismissed.
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        Task { @MainActor in
            // Overwrite completion closure to retain self until called
            let completion: (PaymentSheetResult) -> Void = { status in
                // Dismiss if necessary
                if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                    // Calling `dismiss()` on the presenting view controller causes
                    // the bottom sheet and any presented view controller by
                    // bottom sheet (i.e. Link) to be dismissed all at the same time.
                    presentingViewController.dismiss(animated: true) {
                        completion(status)
                    }
                } else {
                    completion(status)
                }
                self.completion = nil
            }
            self.completion = completion

            // Guard against basic user error
            guard presentingViewController.presentedViewController == nil else {
                assertionFailure(PaymentSheetError.alreadyPresented.debugDescription)
                let error = PaymentSheetError.alreadyPresented
                completion(.failed(error: error))
                return
            }
            if let checkout, checkout.isPerformingSessionUpdate {
                let message = "A Checkout operation is already in progress. Wait for it to complete before calling PaymentSheet.present(from:completion:)."
                assertionFailure(message)
                completion(.failed(error: PaymentSheetError.integrationError(nonPIIDebugDescription: message)))
                return
            }

            // Configure the Payment Sheet VC after loading the PI/SI, Customer, etc.
            PaymentSheetLoader.load(
                mode: mode,
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                integrationShape: .paymentSheet
            ) { result in
                switch result {
                case .success(let loadResult):
                    self.confirmationChallenge = ConfirmationChallenge(enableAttestation: self.configuration.enableAttestationOnConfirmation, elementsSession: loadResult.elementsSession, stripeAttest: self.configuration.apiClient.stripeAttest)
                    let presentPaymentSheet: () -> Void = {
                        let paymentSheetVC = self.makePaymentSheetVC(
                            loadResult: loadResult
                        )
                        self.bottomSheetViewController.setViewControllers([paymentSheetVC])
                    }
                    if let linkAccount = LinkAccountContext.shared.account, loadResult.elementsSession.shouldShowLink2FABeforePaymentSheet(for: linkAccount) {
                        let verificationController = LinkVerificationController(
                            mode: .inlineLogin,
                            linkAccount: linkAccount,
                            configuration: self.configuration
                        )

                        verificationController.present(from: self.bottomSheetViewController) { result in
                            switch result {
                            case .completed:
                                self.presentPayWithNativeLinkController(from: self.bottomSheetViewController, intent: loadResult.intent, elementsSession: loadResult.elementsSession, shouldOfferApplePay: self.configuration.isApplePayEnabled, shouldFinishOnClose: false, onClose: {
                                    presentPaymentSheet()
                                })
                            case .canceled, .switchAccount:
                                presentPaymentSheet()
                            case .failed:
                                // Error is logged within LinkVerificationViewController
                                presentPaymentSheet()
                            }
                        }
                    } else {
                        presentPaymentSheet()
                    }
                case .failure(let error):
                    completion(.failed(error: error))
                }
            }
            self.bottomSheetViewController.setViewControllers([self.loadingViewController])
            presentingViewController.presentAsBottomSheet(bottomSheetViewController, appearance: configuration.appearance)
        }
    }

    /// Presents a sheet for a customer to complete their payment
    /// - Parameter presentingViewController: The view controller to present a payment sheet
    /// - Returns: The result of the payment after the payment sheet is dismissed.
    public func present(
        from presentingViewController: UIViewController
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                present(from: presentingViewController) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// Deletes all persisted authentication state associated with a customer.
    ///
    /// You must call this method when the user logs out from your app.
    /// This will ensure that any persisted authentication state in PaymentSheet,
    /// such as authentication cookies, is also cleared during logout.
    public static func resetCustomer() {
        UserDefaults.standard.clearLinkDefaults()
    }

    // MARK: - Internal Properties

    /// The initialization mode this instance was initialized with
    let mode: InitializationMode

    /// The Checkout that backs checkout-session mode integrations, if any.
    private weak var checkout: Checkout?

    /// A user-supplied completion block. Nil until `present` is called.
    var completion: ((PaymentSheetResult) -> Void)?

    /// Loading View Controller
    lazy var loadingViewController = LoadingViewController(
        delegate: self,
        appearance: configuration.appearance,
        isTestMode: configuration.apiClient.isTestmode
    )

    /// The STPPaymentHandler instance
    lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient) }()

    /// The parent view controller to present
    lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = configuration.apiClient.isTestmode

        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            didCancelNative3DS2: { [weak self] in
                self?.paymentHandler.cancel3DS2ChallengeFlow()
            }
        )

        configuration.style.configure(vc)
        return vc
    }()

    let analyticsHelper: PaymentSheetAnalyticsHelper

    var confirmationChallenge: ConfirmationChallenge?

    // MARK: - Factory & Reload
    @MainActor
    func makePaymentSheetVC(
        loadResult: PaymentSheetLoader.LoadResult,
        previousPaymentOption: PaymentOption? = nil,
        shouldLogExperimentExposure: Bool = true
    ) -> PaymentSheetViewControllerProtocol {
        var configuration = self.configuration
        let layout = configuration.resolveLayout(
            loadResult: loadResult,
            configuration: self.configuration,
            analyticsHelper: self.analyticsHelper,
            shouldLogExperimentExposure: shouldLogExperimentExposure
        )
        switch layout {
        case .horizontal:
            let vc = PaymentSheetViewController(
                configuration: configuration,
                loadResult: loadResult,
                analyticsHelper: analyticsHelper,
                delegate: self,
                previousPaymentOption: previousPaymentOption
            )
            return vc
        case .vertical:
            let vc = PaymentSheetVerticalViewController(
                configuration: configuration,
                loadResult: loadResult,
                isFlowController: false,
                analyticsHelper: analyticsHelper,
                previousPaymentOption: previousPaymentOption
            )
            vc.paymentSheetDelegate = self
            return vc
        }
    }

    @MainActor
    private func performReload(mode: InitializationMode) {
        guard let currentVC = bottomSheetViewController.contentStack.first
                as? PaymentSheetViewControllerProtocol else { return }

        currentVC.setReloading(true)

        Task {
            do {
                let loadResult = try await PaymentSheetLoader.load(
                    mode: mode,
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    integrationShape: .paymentSheet,
                    isUpdate: true
                )
                self.confirmationChallenge = ConfirmationChallenge(
                    enableAttestation: configuration.enableAttestationOnConfirmation,
                    elementsSession: loadResult.elementsSession,
                    stripeAttest: configuration.apiClient.stripeAttest
                )
                let newVC = makePaymentSheetVC(
                    loadResult: loadResult,
                    previousPaymentOption: currentVC.selectedPaymentOption,
                    shouldLogExperimentExposure: false
                )
                bottomSheetViewController.setViewControllers([newVC])
            } catch {
                currentVC.setReloading(false)
                currentVC.setReloadError(error)
            }
        }
    }
}

extension PaymentSheet: PaymentSheetViewControllerDelegate {

    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        let presentingViewController = paymentSheetViewController.presentingViewController
        let confirm: (@escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) -> Void = { completion in
            PaymentSheet.confirm(
                configuration: self.configuration,
                authenticationContext: self.bottomSheetViewController,
                intent: paymentSheetViewController.intent,
                elementsSession: paymentSheetViewController.elementsSession,
                paymentOption: paymentOption,
                paymentHandler: self.paymentHandler,
                integrationShape: .complete,
                confirmationChallenge: self.confirmationChallenge,
                analyticsHelper: self.analyticsHelper
            ) { result, deferredIntentConfirmationType in
                if case let .failed(error) = result {
                    self.mostRecentError = error
                }

                if case .link = paymentOption {
                    // End special Link blur animation before calling completion
                    switch result {
                    case .canceled, .failed:
                        self.bottomSheetViewController.removeBlurEffect(animated: true) {
                            completion(result, deferredIntentConfirmationType)
                        }
                    case .completed:
                        self.bottomSheetViewController.transitionSpinnerToComplete(animated: true) {
                            completion(result, deferredIntentConfirmationType)
                        }
                    }
                } else {
                    completion(result, deferredIntentConfirmationType)
                }
            }
        }

        if case .applePay = paymentOption {
            // Don't present the Apple Pay sheet on top of the Payment Sheet
            paymentSheetViewController.dismiss(animated: true) {
                confirm { result, deferredIntentConfirmationType in
                    if case .completed = result {
                    } else {
                        // We dismissed the Payment Sheet to show the Apple Pay sheet
                        // Bring it back if it didn't succeed
                        presentingViewController?.presentAsBottomSheet(self.bottomSheetViewController,
                                                                       appearance: self.configuration.appearance)
                    }
                    completion(result, deferredIntentConfirmationType)
                }
            }
        } else {
            confirm(completion)
        }
    }

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: PaymentSheetViewControllerProtocol, result: PaymentSheetResult) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(result)
        }
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: PaymentSheetViewControllerProtocol) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(.canceled)
        }
    }

    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: PaymentSheetViewControllerProtocol) {
        let useNativeLink = deviceCanUseNativeLink(elementsSession: paymentSheetViewController.elementsSession, configuration: configuration)
        if useNativeLink {
            presentPayWithNativeLinkController(from: paymentSheetViewController, intent: paymentSheetViewController.intent, elementsSession: paymentSheetViewController.elementsSession, shouldOfferApplePay: false, shouldFinishOnClose: false)
        } else {
            self.presentPayWithLinkController(
                from: paymentSheetViewController,
                intent: paymentSheetViewController.intent,
                elementsSession: paymentSheetViewController.elementsSession
            )
        }
    }
}

// MARK: - CheckoutIntegrationDelegate

extension PaymentSheet: CheckoutIntegrationDelegate {
    var isSheetPresented: Bool {
        bottomSheetViewController.presentingViewController != nil
    }
}

extension PaymentSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?(.canceled)
        }
    }
}

/// :nodoc:
@_spi(STP) extension PaymentSheet: STPAnalyticsProtocol {
    @_spi(STP) public static let stp_analyticsIdentifier: String = "PaymentSheet"
}

// MARK: - PaymentSheetViewControllerProtocol

internal protocol PaymentSheetViewControllerProtocol: UIViewController, BottomSheetContentViewController {
    var intent: Intent { get }
    var elementsSession: STPElementsSession { get }
    var selectedPaymentOption: PaymentSheet.PaymentOption? { get }

    func pay(with paymentOption: PaymentOption)
    func clearTextFields()
    func setReloading(_ isReloading: Bool)
    func setReloadError(_ error: Error)
}

protocol PaymentSheetViewControllerDelegate: AnyObject {
    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    )
    func paymentSheetViewControllerDidFinish(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        result: PaymentSheetResult
    )
    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: PaymentSheetViewControllerProtocol)
    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: PaymentSheetViewControllerProtocol)
}
