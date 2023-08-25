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
        case externalPayPal(confirmParams: IntentConfirmParams) // TODO(yuki): Rewrite this when we support more EPMs

        var paymentMethodTypeAnalyticsValue: String? {
            switch self {
            case .applePay:
                return "apple_pay"
            case .saved(paymentMethod: let paymentMethod):
                return paymentMethod.type.identifier
            case .new(confirmParams: let confirmParams):
                return confirmParams.paymentMethodType.identifier
            case .link:
                return PaymentSheet.PaymentMethodType.link.identifier
            case .externalPayPal:
                return "external_paypal"
            }
        }
    }

    /// A class that presents the individual steps of a payment flow
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
                case .externalPayPal:
                    label = STPLocalizedString("PayPal", "Payment Method type brand name")
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
        var viewController: PaymentSheetFlowControllerViewController
        private var presentPaymentOptionsCompletion: (() -> Void)?

        /// The desired, valid (ie passed client-side checks) payment option from the underlying payment options VC.
        private var _paymentOption: PaymentOption? {
            guard viewController.error == nil else {
                return nil
            }

            return viewController.selectedPaymentOption
        }

        // Stores the state of the most recent call to the update API
        private var latestUpdateContext: UpdateContext?

        struct UpdateContext {
            /// The ID of the update API call
            let id: UUID

            /// The status of the last update API call
            var status: Status = .inProgress

            init(id: UUID, status: Status = .inProgress) {
                self.id = id
                self.status = status
            }

            enum Status {
                case completed
                case inProgress
                case failed
            }
        }

        private var isPresented = false

        // MARK: - Initializer (Internal)

        required init(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool,
            configuration: Configuration
        ) {
            AnalyticsHelper.shared.generateSessionID()
            STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.FlowController.self)
            STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(isCustom: true,
                                                                       configuration: configuration,
                                                                       intentConfig: intent.intentConfig)
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

        /// An asynchronous failable initializer for PaymentSheet.FlowController
        /// This asynchronously loads the Customer's payment methods, their default payment method.
        /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
        /// - Parameter intentConfiguration: Information about the payment or setup used to render the UI
        /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
        /// - Parameter completion: This is called with either a valid PaymentSheet.FlowController instance or an error if loading failed.
        public static func create(
            intentConfiguration: IntentConfiguration,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            create(mode: .deferredIntent(intentConfiguration),
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
            PaymentSheetLoader.load(
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
            switch latestUpdateContext?.status {
            case .inProgress, .failed:
                assertionFailure("Cannot call presentPaymentOptions when the last update call has not yet finished or failed.")
                completion?()
                return
            default:
                break
            }

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
                self.isPresented = true
            }

            showPaymentOptions()
        }

        /// Completes the payment or setup.
        /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
        /// - Parameter completion: Called with the result of the payment after any presented view controllers are dismissed
        public func confirm(
            from presentingViewController: UIViewController,
            completion: @escaping (PaymentSheetResult) -> Void
        ) {
            assert(Thread.isMainThread, "PaymentSheet.FlowController.confirm must be called from the main thread.")

            switch latestUpdateContext?.status {
            case .inProgress:
                assertionFailure("`confirmPayment` should only be called when the last update has completed.")
                let error = PaymentSheetError.flowControllerConfirmFailed(message: "confirmPayment was called with an update API call in progress.")
                completion(.failed(error: error))
                return
            case .failed:
                assertionFailure("`confirmPayment` should only be called when the last update has completed without error.")
                let error = PaymentSheetError.flowControllerConfirmFailed(message: "confirmPayment was called when the last update API call failed.")
                completion(.failed(error: error))
                return
            default:
                break
            }

            guard let paymentOption = _paymentOption else {
                assertionFailure("`confirmPayment` should only be called when `paymentOption` is not nil")
                let error = PaymentSheetError.flowControllerConfirmFailed(message: "confirmPayment was called with a nil paymentOption")
                completion(.failed(error: error))
                return
            }

            let authenticationContext = AuthenticationContext(presentingViewController: presentingViewController, appearance: configuration.appearance)

            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: authenticationContext,
                intent: intent,
                paymentOption: paymentOption,
                paymentHandler: paymentHandler,
                isFlowController: true
            ) { [intent, configuration] result, deferredIntentConfirmationType in
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                    isCustom: true,
                    paymentMethod: paymentOption.analyticsValue,
                    result: result,
                    linkEnabled: intent.supportsLink,
                    activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
                    linkSessionType: intent.linkPopupWebviewOption,
                    currency: intent.currency,
                    intentConfig: intent.intentConfig,
                    deferredIntentConfirmationType: deferredIntentConfirmationType,
                    paymentMethodTypeAnalyticsValue: paymentOption.paymentMethodTypeAnalyticsValue,
                    error: result.error
                )

                if case .completed = result, case .link = paymentOption {
                    // Remember Link as default payment method for users who just created an account.
                    CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: configuration.customer?.id)
                }

                completion(result)
            }
        }

        /// Call this method when the IntentConfiguration values you used to initialize PaymentSheet.FlowController (amount, currency, etc.) change.
        /// This ensures the appropriate payment methods are displayed, etc.
        /// - Parameter intentConfiguration: An updated IntentConfiguration
        /// - Parameter completion: Called when the update completes with an optional error. Your implementation should get the customer's updated payment option by using the `paymentOption` property and update your UI. If an error occurred, retry.
        /// - Note: Don't call `confirm` or `present` until the update succeeds. Don’t call this method while PaymentSheet is being presented. 
        public func update(intentConfiguration: IntentConfiguration, completion: @escaping (Error?) -> Void) {
            assert(Thread.isMainThread, "PaymentSheet.FlowController.update must be called from the main thread.")
            assert(!isPresented, "PaymentSheet.FlowController.update must be when PaymentSheet is not presented.")

            let updateID = UUID()
            latestUpdateContext = UpdateContext(id: updateID)

            // 1. Load the intent, payment methods, and link data from the Stripe API
            PaymentSheetLoader.load(
                mode: .deferredIntent(intentConfiguration),
                configuration: configuration
            ) { [weak self] loadResult in
                assert(Thread.isMainThread, "PaymentSheet.FlowController.update load callback must be called from the main thread.")
                guard let self = self else {
                    assertionFailure("The PaymentSheet.FlowController instance was destroyed during a call to `update(intentConfiguration:completion:)`")
                    return
                }

                // If this update is not the latest, ignore the result and don't invoke completion block and exit early
                guard updateID == self.latestUpdateContext?.id else {
                    return
                }

                switch loadResult {
                case .success(let intent, let paymentMethods, let isLinkEnabled):
                    // 2. Re-initialize PaymentSheetFlowControllerViewController to update the UI to match the newly loaded data e.g. payment method types may have changed.
                    self.viewController = Self.makeViewController(
                        intent: intent,
                        savedPaymentMethods: paymentMethods,
                        previousPaymentOption: self._paymentOption,
                        isLinkEnabled: isLinkEnabled,
                        configuration: self.configuration
                    )
                    self.viewController.delegate = self

                    // Synchronously pre-load image into cache
                    // Accessing paymentOption has the side-effect of ensuring its `image` property is loaded (e.g. from the internet instead of disk) before we call the completion handler.
                    _ = self.paymentOption

                    self.latestUpdateContext?.status = .completed
                    completion(nil)
                case .failure(let error):
                    self.latestUpdateContext?.status = .failed
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

            configuration.style.configure(sheet)
            return sheet
        }

        static func makeViewController(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            previousPaymentOption: PaymentOption? = nil,
            isLinkEnabled: Bool,
            configuration: Configuration
        ) -> PaymentSheetFlowControllerViewController {
            let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && configuration.applePay != nil
            let vc = PaymentSheetFlowControllerViewController(
                intent: intent,
                savedPaymentMethods: savedPaymentMethods,
                configuration: configuration,
                previousPaymentOption: previousPaymentOption,
                isApplePayEnabled: isApplePayEnabled,
                isLinkEnabled: isLinkEnabled
            )
            configuration.style.configure(vc)
            return vc
        }
    }

}

// MARK: - PaymentSheetFlowControllerViewControllerDelegate
extension PaymentSheet.FlowController: PaymentSheetFlowControllerViewControllerDelegate {
    func paymentSheetFlowControllerViewControllerShouldClose(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController
    ) {
        PaymentSheetFlowControllerViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
            self.isPresented = false
        }
    }

    func paymentSheetFlowControllerViewControllerDidUpdateSelection(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController
    ) {
        // no-op
    }
}

// MARK: - STPAnalyticsProtocol
/// :nodoc:
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

    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType) {
        let pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
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
