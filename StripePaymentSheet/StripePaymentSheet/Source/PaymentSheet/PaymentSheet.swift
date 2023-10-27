//
//  PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
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

        var intentConfig: PaymentSheet.IntentConfiguration? {
            switch self {
            case .deferredIntent(let intentConfig):
                return intentConfig
            default:
                return nil
            }
        }
    }

    /// This contains all configurable properties of PaymentSheet
    public let configuration: Configuration

    /// The most recent error encountered by the customer, if any.
    public private(set) var mostRecentError: Error?

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

    required init(mode: InitializationMode, configuration: Configuration) {
        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.self)
        self.mode = mode
        self.configuration = configuration
        STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(configuration: configuration,
                                                                   intentConfig: mode.intentConfig)
    }

    /// Presents a sheet for a customer to complete their payment
    /// - Parameter presentingViewController: The view controller to present a payment sheet
    /// - Parameter completion: Called with the result of the payment after the payment sheet is dismissed.
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
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

        // Configure the Payment Sheet VC after loading the PI/SI, Customer, etc.
        PaymentSheetLoader.load(
            mode: mode,
            configuration: configuration
        ) { result in
            switch result {
            case .success(let intent, let savedPaymentMethods, let isLinkEnabled):
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePay != nil

                let presentPaymentSheetVC = { (justVerifiedLinkOTP: Bool) in
                    let paymentSheetVC = PaymentSheetViewController(
                        intent: intent,
                        savedPaymentMethods: savedPaymentMethods,
                        configuration: self.configuration,
                        isApplePayEnabled: isApplePayEnabled,
                        isLinkEnabled: isLinkEnabled,
                        delegate: self
                    )

                    self.configuration.style.configure(paymentSheetVC)

                    let updateBottomSheet: () -> Void = {
                        self.bottomSheetViewController.contentStack = [paymentSheetVC]
                    }

                    if LinkAccountContext.shared.account?.sessionState == .verified {
                        self.presentPayWithLinkController(
                            from: self.bottomSheetViewController,
                            intent: intent,
                            shouldOfferApplePay: justVerifiedLinkOTP,
                            shouldFinishOnClose: true,
                            completion: {
                                // Update the bottom sheet after presenting the Link controller
                                // to avoid briefly flashing the PaymentSheet in the middle of
                                // the View Controller transition.
                                updateBottomSheet()
                            }
                        )
                    } else {
                        updateBottomSheet()
                    }
                }
                presentPaymentSheetVC(false)
            case .failure(let error):
                completion(.failed(error: error))
            }
        }

        presentingViewController.presentAsBottomSheet(bottomSheetViewController, appearance: configuration.appearance)
    }

    /// Deletes all persisted authentication state associated with a customer.
    ///
    /// You must call this method when the user logs out from your app.
    /// This will ensure that any persisted authentication state in PaymentSheet,
    /// such as authentication cookies, is also cleared during logout.
    ///
    /// - Warning: Deprecated. Use `PaymentSheet.resetCustomer()` instead.
    @available(*, deprecated, renamed: "resetCustomer()")
    public static func reset() {
        resetCustomer()
    }

    /// Deletes all persisted authentication state associated with a customer.
    ///
    /// You must call this method when the user logs out from your app.
    /// This will ensure that any persisted authentication state in PaymentSheet,
    /// such as authentication cookies, is also cleared during logout.
    public static func resetCustomer() {
        LinkAccountService.defaultCookieStore.clear()
    }

    // MARK: - Internal Properties

    /// The initialization mode this instance was initialized with
    let mode: InitializationMode

    /// A user-supplied completion block. Nil until `present` is called.
    var completion: ((PaymentSheetResult) -> Void)?

    /// The STPPaymentHandler instance
        lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()) }()

    /// The parent view controller to present
        lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = configuration.apiClient.isTestmode
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            loadingViewHeight: 244
        )

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

}

extension PaymentSheet: PaymentSheetViewControllerDelegate {

    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        let presentingViewController = paymentSheetViewController.presentingViewController
        let confirm: (@escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) -> Void = { completion in
            PaymentSheet.confirm(
                configuration: self.configuration,
                authenticationContext: self.bottomSheetViewController,
                intent: paymentSheetViewController.intent,
                paymentOption: paymentOption,
                paymentHandler: self.paymentHandler,
                isFlowController: false
            ) { result, deferredIntentConfirmationType in
                if case let .failed(error) = result {
                    self.mostRecentError = error
                }
                completion(result, deferredIntentConfirmationType)
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

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: PaymentSheetViewController, result: PaymentSheetResult) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(result)
        }
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: PaymentSheetViewController) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(.canceled)
        }
    }

    func paymentSheetViewControllerDidSelectPayWithLink(
        _ paymentSheetViewController: PaymentSheetViewController
    ) {
        presentPayWithLinkController(
            from: paymentSheetViewController,
            intent: paymentSheetViewController.intent
        )
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

extension PaymentSheet: PayWithLinkWebControllerDelegate {

    func payWithLinkWebControllerDidComplete(
        _ PayWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        with paymentOption: PaymentOption
    ) {
        let psvc = self.findPaymentSheetViewController()
        psvc?.pay(with: paymentOption)
    }

    func payWithLinkWebControllerDidCancel(_ payWithLinkWebController: PayWithLinkWebController) {
    }

    private func findPaymentSheetViewController() -> PaymentSheetViewController? {
        for vc in bottomSheetViewController.contentStack {
            if let paymentSheetVC = vc as? PaymentSheetViewController {
                return paymentSheetVC
            }
        }

        return nil
    }
}

// MARK: - Link

private extension PaymentSheet {

    func presentPayWithLinkController(
        from presentingController: UIViewController,
        intent: Intent,
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        let payWithLinkVC = PayWithLinkWebController(
            intent: intent,
            configuration: configuration,
            shouldOfferApplePay: shouldOfferApplePay,
            shouldFinishOnClose: shouldFinishOnClose
        )

        payWithLinkVC.payWithLinkDelegate = self
        payWithLinkVC.present(over: presentingController)
    }

}
