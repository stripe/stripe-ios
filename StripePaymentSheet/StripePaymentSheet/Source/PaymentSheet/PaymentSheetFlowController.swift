//
//  PaymentSheetFlowController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

typealias PaymentOption = PaymentSheet.PaymentOption

extension PaymentSheet {
    /// Represents the ways a customer can pay in PaymentSheet
    enum PaymentOption {
        case applePay
        case saved(paymentMethod: STPPaymentMethod)
        case new(confirmParams: IntentConfirmParams)
        case link(option: LinkConfirmOption)
    }

    /// A class that presents the individual steps of a payment flow
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public class FlowController {
        // MARK: - Public properties
        /// Contains details about a payment method that can be displayed to the customer
        public struct PaymentOptionDisplayData {
            /// An image representing a payment method; e.g. the Apple Pay logo or a VISA logo
            public let image: UIImage
            /// A user facing string representing the payment method; e.g. "Apple Pay" or "····4242" for a card
            public let label: String

            init(paymentOption: PaymentOption) {
                image = paymentOption.makeIcon(updateImageHandler: nil)
                switch paymentOption {
                case .applePay:
                    label = String.Localized.apple_pay
                case .saved(let paymentMethod):
                    label = paymentMethod.paymentSheetLabel
                case .new(let confirmParams):
                    label = confirmParams.paymentSheetLabel
                case .link(let option):
                    label = option.paymentSheetLabel
                }
            }
        }

        /// This contains all configurable properties of PaymentSheet
        public let configuration: Configuration

        /// Contains information about the customer's desired payment option.
        /// You can use this to e.g. display the payment option in your UI.
        public var paymentOption: PaymentOptionDisplayData? {
            if let selectedPaymentOption = _paymentOption {
                return PaymentOptionDisplayData(paymentOption: selectedPaymentOption)
            }
            return nil
        }

        // MARK: - Private properties

        private var intent: Intent {
            return viewController.intent
        }
        lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()) }()
        private var viewController: PaymentSheetFlowControllerViewController
        private var presentPaymentOptionsCompletion: (() -> Void)?

        /// The desired, valid (ie passed client-side checks) payment option from the underlying payment options VC.
        private var _paymentOption: PaymentOption? {
            guard viewController.error == nil else {
                return nil
            }

            return viewController.selectedPaymentOption
        }

        // MARK: - Initializer (Internal)

        required init(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool,
            configuration: Configuration
        ) {
            AnalyticsHelper.shared.generateSessionID()
            STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.FlowController.self)
            STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(isCustom: true, configuration: configuration)
            self.configuration = configuration
            self.viewController = Self.makeViewController(intent: intent, savedPaymentMethods: savedPaymentMethods, isLinkEnabled: isLinkEnabled, configuration: configuration)
            self.viewController.delegate = self
        }

        // MARK: - Public methods

        /// An asynchronous failable initializer for PaymentSheet.FlowController
        /// This asynchronously loads the Customer's payment methods, their default payment method, and the PaymentIntent.
        /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
        /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
        /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
        /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
        /// - Parameter completion: This is called with either a valid PaymentSheet.FlowController instance or an error if loading failed.
        public static func create(
            paymentIntentClientSecret: String,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            create(mode: .paymentIntentClientSecret(paymentIntentClientSecret),
                   configuration: configuration,
                   completion: completion
            )
        }

        /// An asynchronous failable initializer for PaymentSheet.FlowController
        /// This asynchronously loads the Customer's payment methods, their default payment method, and the SetuptIntent.
        /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
        /// - Parameter setupIntentClientSecret: The [client secret](https://stripe.com/docs/api/setup_intents/object#setup_intent_object-client_secret) of a Stripe SetupIntent object
        /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
        /// - Parameter completion: This is called with either a valid PaymentSheet.FlowController instance or an error if loading failed.
        public static func create(
            setupIntentClientSecret: String,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            create(mode: .setupIntentClientSecret(setupIntentClientSecret),
                   configuration: configuration,
                   completion: completion
            )
        }

        /// 🚧 Under construction
        /// An asynchronous failable initializer for PaymentSheet.FlowController
        /// This asynchronously loads the Customer's payment methods, their default payment method.
        /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
        /// - Parameter intentConfig: The `IntentConfiguration` object
        /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
        /// - Parameter completion: This is called with either a valid PaymentSheet.FlowController instance or an error if loading failed.
        @_spi(STP) public static func create(
            intentConfig: IntentConfiguration,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            create(mode: .deferredIntent(intentConfig),
                   configuration: configuration,
                   completion: completion
            )
        }

        /// An asynchronous failable initializer for PaymentSheet.FlowController
        /// This asynchronously loads the Customer's payment methods, their default payment method, and the Intent.
        /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
        /// - Parameter mode: The mode used to initialize PaymentSheet
        /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
        /// - Parameter completion: This is called with either a valid PaymentSheet.FlowController instance or an error if loading failed.
        static func create(
            mode: InitializationMode,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            PaymentSheet.load(
                mode: mode,
                configuration: configuration
            ) { result in
                switch result {
                case .success(let intent, let paymentMethods, let isLinkEnabled):
                    let flowController = FlowController(
                        intent: intent,
                        savedPaymentMethods: paymentMethods,
                        isLinkEnabled: isLinkEnabled,
                        configuration: configuration)

                    // Synchronously pre-load image into cache.
                    // Accessing flowController.paymentOption has the side-effect of ensuring its `image` property is loaded (e.g. from the internet instead of disk) before we call the completion handler.
                    _ = flowController.paymentOption
                    completion(.success(flowController))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        /// Presents a sheet where the customer chooses how to pay, either by selecting an existing payment method or adding a new one
        /// Call this when your "Select a payment method" button is tapped
        /// - Parameter presentingViewController: The view controller that presents the sheet.
        /// - Parameter completion: This is called after the sheet is dismissed. Use the `paymentOption` property to get the customer's desired payment option.
        public func presentPaymentOptions(
            from presentingViewController: UIViewController,
            completion: (() -> Void)? = nil
        ) {
            // TODO(Update): If update is in-flight or the last update failed, assert and call the completion
            guard presentingViewController.presentedViewController == nil else {
                assertionFailure("presentingViewController is already presenting a view controller")
                completion?()
                return
            }

            if let completion = completion {
                presentPaymentOptionsCompletion = completion
            }

            let showPaymentOptions: () -> Void = { [weak self] in
                guard let self = self else { return }

                // Set the PaymentSheetViewController as the content of our bottom sheet
                let bottomSheetVC = Self.makeBottomSheetViewController(
                    self.viewController,
                    configuration: self.configuration,
                    didCancelNative3DS2: { [weak self] in
                        self?.paymentHandler.cancel3DS2ChallengeFlow()
                    }
                )

                presentingViewController.presentAsBottomSheet(bottomSheetVC, appearance: self.configuration.appearance)
            }

            if let linkAccount = LinkAccountContext.shared.account,
               linkAccount.sessionState == .requiresVerification,
               !linkAccount.hasStartedSMSVerification {
                let verificationController = LinkVerificationController(linkAccount: linkAccount)
                verificationController.present(from: presentingViewController) { [weak self] result in
                    switch result {
                    case .completed:
                        self?.viewController.selectLink()
                        completion?()
                    case .canceled, .failed:
                        showPaymentOptions()
                    }
                }
            } else {
                showPaymentOptions()
            }
        }

        /// Completes the payment or setup.
        /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
        /// - Parameter completion: Called with the result of the payment after any presented view controllers are dismissed
        public func confirm(
            from presentingViewController: UIViewController,
            completion: @escaping (PaymentSheetResult) -> Void
        ) {
            // TODO(Update): If update is in-flight or the last update failed, assert and return .completion(.failed)
            guard let paymentOption = _paymentOption else {
                assertionFailure("`confirmPayment` should only be called when `paymentOption` is not nil")
                let error = PaymentSheetError.unknown(debugDescription: "confirmPayment was called with a nil paymentOption")
                completion(.failed(error: error))
                return
            }

            let authenticationContext = AuthenticationContext(presentingViewController: presentingViewController, appearance: configuration.appearance)

            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: authenticationContext,
                intent: intent,
                paymentOption: paymentOption,
                paymentHandler: paymentHandler
            ) { [intent, configuration] result in
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                    isCustom: true,
                    paymentMethod: paymentOption.analyticsValue,
                    result: result,
                    linkEnabled: intent.supportsLink,
                    activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
                    currency: intent.currency
                )

                if case .completed = result, case .link = paymentOption {
                    // Remember Link as default payment method for users who just created an account.
                    DefaultPaymentMethodStore.setDefaultPaymentMethod(.link, forCustomer: configuration.customer?.id)
                }

                completion(result)
            }
        }

        /// 🚧 Under construction
        /// Call this method when the IntentConfiguration values you used to initialize PaymentSheet.FlowController (amount, currency, etc.) change.
        /// This ensures the appropriate payment methods are displayed, etc.
        /// - Parameter intentConfiguration: An updated IntentConfiguration
        /// - Parameter completion: Called when the update completes with an optional error. Your implementation should get the customer's updated payment option by using the `paymentOption` property and update your UI. If an error occurred, retry. TODO(Update): Tell the merchant they need to disable the buy button.
        /// Don’t call this method while PaymentSheet is being presented.
        func update(intentConfiguration: IntentConfiguration, completion: @escaping (Error?) -> Void) {
            // 1. Load the intent, payment methods, and link data from the Stripe API
            PaymentSheet.load(
                mode: .deferredIntent(intentConfiguration),
                configuration: configuration
            ) { [weak self] loadResult in
                guard let self = self else {
                    assertionFailure("The PaymentSheet.FlowController instance was destroyed during a call to `update(intentConfiguration:completion:)`")
                    return
                }
                switch loadResult {
                case .success(let intent, let paymentMethods, let isLinkEnabled):
                    // 2. Re-initialize PaymentSheetFlowControllerViewController to update the UI to match the newly loaded data e.g. payment method types may have changed.
                    // TODO(Update:) Preserve the customer's previous inputs.
                    self.viewController = Self.makeViewController(intent: intent, savedPaymentMethods: paymentMethods, isLinkEnabled: isLinkEnabled, configuration: self.configuration)

                    // Synchronously pre-load image into cache
                    // Accessing paymentOption has the side-effect of ensuring its `image` property is loaded (e.g. from the internet instead of disk) before we call the completion handler.
                    _ = self.paymentOption

                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        }

        // MARK: Internal helper methods
        static func makeBottomSheetViewController(
            _ contentViewController: BottomSheetContentViewController,
            configuration: Configuration,
            didCancelNative3DS2: (() -> Void)? = nil
        ) -> BottomSheetViewController {
            let sheet = BottomSheetViewController(
                contentViewController: contentViewController,
                appearance: configuration.appearance,
                isTestMode: configuration.apiClient.isTestmode,
                didCancelNative3DS2: didCancelNative3DS2 ?? { } // TODO(MOBILESDK-864): Refactor this out.
            )

            // Workaround to silence a warning in the Catalyst target
            #if targetEnvironment(macCatalyst)
            configuration.style.configure(sheet)
            #else
            if #available(iOS 13.0, *) {
                configuration.style.configure(sheet)
            }
            #endif
            return sheet
        }

        static func makeViewController(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool,
            configuration: Configuration
        ) -> PaymentSheetFlowControllerViewController {
            let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && configuration.applePay != nil
            let vc = PaymentSheetFlowControllerViewController(
                intent: intent,
                savedPaymentMethods: savedPaymentMethods,
                configuration: configuration,
                isApplePayEnabled: isApplePayEnabled,
                isLinkEnabled: isLinkEnabled
            )
            // Workaround to silence a warning in the Catalyst target
#if targetEnvironment(macCatalyst)
            configuration.style.configure(vc)
#else
            if #available(iOS 13.0, *) {
                configuration.style.configure(vc)
            }
#endif
            return vc
        }
    }

}

// MARK: - PaymentSheetFlowControllerViewControllerDelegate
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet.FlowController: PaymentSheetFlowControllerViewControllerDelegate {
    func PaymentSheetFlowControllerViewControllerShouldClose(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController
    ) {
        PaymentSheetFlowControllerViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
        }
    }

    func PaymentSheetFlowControllerViewControllerDidUpdateSelection(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController
    ) {
        // no-op
    }
}

// MARK: - STPAnalyticsProtocol
/// :nodoc:
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(STP) extension PaymentSheet.FlowController: STPAnalyticsProtocol {
    @_spi(STP) public static let stp_analyticsIdentifier: String = "PaymentSheet.FlowController"
}

// MARK: - PaymentSheetAuthenticationContext
/// A simple STPAuthenticationContext that wraps a UIViewController
/// For internal SDK use only
@objc(STP_Internal_AuthenticationContext)
class AuthenticationContext: NSObject, PaymentSheetAuthenticationContext {
    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        presentingViewController.present(authenticationViewController, animated: true, completion: nil)
    }

    func presentPollingVCForAction(_ action: STPPaymentHandlerActionParams) {
        let pollingVC = PollingViewController(currentAction: action,
                                                      appearance: self.appearance)
        presentingViewController.present(pollingVC, animated: true, completion: nil)
    }

    func dismiss(_ authenticationViewController: UIViewController) {
        authenticationViewController.dismiss(animated: true, completion: nil)
    }

    let presentingViewController: UIViewController
    let appearance: PaymentSheet.Appearance

    init(presentingViewController: UIViewController, appearance: PaymentSheet.Appearance) {
        self.presentingViewController = presentingViewController
        self.appearance = appearance
        super.init()
    }
    func authenticationPresentingViewController() -> UIViewController {
        return presentingViewController
    }
}
