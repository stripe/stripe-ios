//
//  PaymentSheetFlowController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
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
        case saved(paymentMethod: STPPaymentMethod, confirmParams: IntentConfirmParams?)
        case new(confirmParams: IntentConfirmParams)
        case link(option: LinkConfirmOption)
        case external(paymentMethod: ExternalPaymentOption, billingDetails: STPPaymentMethodBillingDetails)

        var paymentMethodTypeAnalyticsValue: String {
            switch self {
            case .applePay:
                return "apple_pay"
            case .saved(paymentMethod: let paymentMethod, _):
                return paymentMethod.type.identifier
            case .new(confirmParams: let confirmParams):
                return confirmParams.paymentMethodType.identifier
            case .link(let confirmationOption):
                return confirmationOption.paymentMethodType
            case .external(let paymentMethod, _):
                return paymentMethod.type
            }
        }

        var savedPaymentMethod: STPPaymentMethod? {
            switch self {
            case .applePay, .link, .new, .external:
                return nil
            case .saved(let paymentMethod, _):
                return paymentMethod
            }
        }

        var paymentMethodType: PaymentMethodType? {
            switch self {
            case let .saved(paymentMethod: paymentMethod, _):
                return .stripe(paymentMethod.type)
            case let .new(confirmParams: intentConfirmParams):
                return intentConfirmParams.paymentMethodType
            case .applePay, .link:
                return nil
            case let .external(paymentMethod: paymentMethod, _):
                return .external(paymentMethod)
            }
        }

        // Both "Link" and "Instant Debits" use the same payment method type
        // of "link." To differentiate between the two in metrics, we sometimes
        // need a "link_context."
        var linkContextAnalyticsValue: String? {
            if case .link = self {
               return "wallet"
            } else if
                case .new(let confirmParams) = self,
                let linkedBank = confirmParams.instantDebitsLinkedBank
            {
                if linkedBank.linkMode == .linkCardBrand {
                    return "link_card_brand"
                } else {
                    return "instant_debits"
                }
            } else {
                return nil
            }
        }

        // The confirmation type used by Link
        var linkUIAnalyticsValue: String? {
            if case .link(let option) = self {
                switch option {
                case .withPaymentDetails(let account, _, _):
                    if account.hasCompletedSMSVerification {
                        // This was a returning user who logged in
                        return "native-returning"
                    } else if account.sessionState == .verified {
                        return "native-signup"
                    } else {
                        // Should never reach this
                        stpAssertionFailure()
                        return "native-unknown"
                    }
                case .withPaymentMethod:
                    return "web-popup"
                case .wallet:
                    // From the "Link" button in FlowController, a separate Link popup
                    return "native-popup"
                case .signUp:
                    return "inline-signup"
                }
            } else {
                return nil
            }
        }

        var isExternal: Bool {
            if case .external = self {
                return true
            }
            return false
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

            /// The billing details associated with the customer's desired payment method
            public let billingDetails: PaymentSheet.BillingDetails?

            /// A string representation of the customer's desired payment method
            /// - If this is a Stripe payment method, see https://stripe.com/docs/api/payment_methods/object#payment_method_object-type for possible values.
            /// - If this is an external payment method, see https://stripe.com/docs/payments/external-payment-methods?platform=ios#available-external-payment-methods for possible values.
            /// - If this is Apple Pay, the value is "apple_pay"
            public let paymentMethodType: String

            init(paymentOption: PaymentOption, currency: String?) {
                image = paymentOption.makeIcon(currency: currency, updateImageHandler: nil)
                switch paymentOption {
                case .applePay:
                    label = String.Localized.apple_pay
                    paymentMethodType = "apple_pay"
                    billingDetails = nil
                case .saved(let paymentMethod, let confirmParams):
                    label = paymentMethod.paymentOptionLabel(confirmParams: confirmParams)
                    paymentMethodType = paymentMethod.type.identifier
                    billingDetails = paymentMethod.billingDetails?.toPaymentSheetBillingDetails()
                case .new(let confirmParams):
                    label = confirmParams.paymentSheetLabel
                    paymentMethodType = confirmParams.paymentMethodType.identifier
                    billingDetails = confirmParams.paymentMethodParams.billingDetails?.toPaymentSheetBillingDetails()
                case .link(let option):
                    label = option.paymentSheetLabel
                    paymentMethodType = option.paymentMethodType
                    billingDetails = option.billingDetails?.toPaymentSheetBillingDetails()
                case .external(let paymentMethod, let stpBillingDetails):
                    label = paymentMethod.displayText
                    paymentMethodType = paymentMethod.type
                    billingDetails = stpBillingDetails.toPaymentSheetBillingDetails()
                }
            }
        }

        /// This contains all configurable properties of PaymentSheet
        public let configuration: Configuration

        /// Contains information about the customer's desired payment option.
        /// You can use this to e.g. display the payment option in your UI.
        public var paymentOption: PaymentOptionDisplayData? {
            if let selectedPaymentOption = _paymentOption {
                return PaymentOptionDisplayData(paymentOption: selectedPaymentOption, currency: intent.currency)
            }
            return nil
        }

        // MARK: - Private properties
        var intent: Intent { viewController.intent }
        var elementsSession: STPElementsSession { viewController.elementsSession }
        lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient) }()
        var viewController: FlowControllerViewControllerProtocol
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

            enum Status {
                case completed
                case inProgress
                case failed
            }
        }

        private var isPresented = false
        private(set) var didPresentAndContinue: Bool = false
        let analyticsHelper: PaymentSheetAnalyticsHelper

        // MARK: - Initializer (Internal)

        required init(
            configuration: Configuration,
            loadResult: PaymentSheetLoader.LoadResult,
            analyticsHelper: PaymentSheetAnalyticsHelper
        ) {
            self.configuration = configuration
            self.analyticsHelper = analyticsHelper
            self.analyticsHelper.logInitialized()
            self.viewController = Self.makeViewController(configuration: configuration, loadResult: loadResult, analyticsHelper: analyticsHelper)
            self.viewController.flowControllerDelegate = self
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
            STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.FlowController.self)
            let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: configuration)
            AnalyticsHelper.shared.generateSessionID()
            PaymentSheetLoader.load(
                mode: mode,
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                integrationShape: .flowController
            ) { result in
                switch result {
                case .success(let loadResult):
                    let flowController = FlowController(
                        configuration: configuration,
                        loadResult: loadResult,
                        analyticsHelper: analyticsHelper
                    )

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

            // Overwrite completion closure to retain self until called
            let wrappedCompletion: () -> Void = {
                completion?()
                self.presentPaymentOptionsCompletion = nil
            }
            presentPaymentOptionsCompletion = wrappedCompletion

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
                assertionFailure("`confirm` should only be called when the last update has completed.")
                let error = PaymentSheetError.flowControllerConfirmFailed(message: "confirmPayment was called with an update API call in progress.")
                completion(.failed(error: error))
                return
            case .failed:
                assertionFailure("`confirm` should only be called when the last update has completed without error.")
                let error = PaymentSheetError.flowControllerConfirmFailed(message: "confirmPayment was called when the last update API call failed.")
                completion(.failed(error: error))
                return
            default:
                break
            }

            guard let paymentOption = _paymentOption else {
                assertionFailure("`confirm` should only be called when `paymentOption` is not nil")
                completion(.failed(error: PaymentSheetError.confirmingWithInvalidPaymentOption))
                return
            }

            let authenticationContext = AuthenticationContext(presentingViewController: presentingViewController, appearance: configuration.appearance)

            guard didPresentAndContinue || viewController.selectedPaymentMethodType != .stripe(.SEPADebit) else {
                // We're legally required to show the customer the SEPA mandate before every payment/setup
                // In the edge case where the customer never opened the sheet, and thus never saw the mandate, we present the mandate directly
                presentSEPAMandate()
                return
            }
            confirm()

            func presentSEPAMandate() {
                let sepaMandateVC = SepaMandateViewController(configuration: configuration) { didAcceptMandate in
                    presentingViewController.dismiss(animated: true) {
                        if didAcceptMandate {
                            confirm()
                        } else {
                            completion(.canceled)
                        }
                    }
                }
                let bottomSheet = Self.makeBottomSheetViewController(sepaMandateVC, configuration: configuration)
                presentingViewController.presentAsBottomSheet(bottomSheet, appearance: configuration.appearance)
            }

            func confirm() {
                PaymentSheet.confirm(
                    configuration: configuration,
                    authenticationContext: authenticationContext,
                    intent: intent,
                    elementsSession: elementsSession,
                    paymentOption: paymentOption,
                    paymentHandler: paymentHandler,
                    integrationShape: .flowController,
                    analyticsHelper: analyticsHelper
                ) { [analyticsHelper, configuration] result, deferredIntentConfirmationType in
                    analyticsHelper.logPayment(
                        paymentOption: paymentOption,
                        result: result,
                        deferredIntentConfirmationType: deferredIntentConfirmationType
                    )
                    if case .completed = result, case .link = paymentOption {
                        // Remember Link as default payment method for users who just created an account.
                        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: configuration.customer?.id)
                    }

                    completion(result)
                }
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
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                integrationShape: .flowController
            ) { [weak self] result in
                assert(Thread.isMainThread, "PaymentSheet.FlowController.update load callback must be called from the main thread.")
                guard let self = self else {
                    assertionFailure("The PaymentSheet.FlowController instance was destroyed during a call to `update(intentConfiguration:completion:)`")
                    return
                }

                // If this update is not the latest, ignore the result and don't invoke completion block and exit early
                guard updateID == self.latestUpdateContext?.id else {
                    return
                }

                switch result {
                case .success(let loadResult):
                    // 2. Re-initialize PaymentSheetFlowControllerViewController to update the UI to match the newly loaded data e.g. payment method types may have changed.

                    self.viewController = Self.makeViewController(
                        configuration: self.configuration,
                        loadResult: loadResult,
                        analyticsHelper: analyticsHelper,
                        previousPaymentOption: self._paymentOption
                    )
                    self.viewController.flowControllerDelegate = self

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
            configuration: PaymentElementConfiguration,
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
            configuration: Configuration,
            loadResult: PaymentSheetLoader.LoadResult,
            analyticsHelper: PaymentSheetAnalyticsHelper,
            previousPaymentOption: PaymentOption? = nil
        ) -> FlowControllerViewControllerProtocol {
            switch configuration.paymentMethodLayout {
            case .horizontal:
                return PaymentSheetFlowControllerViewController(
                    configuration: configuration,
                    loadResult: loadResult,
                    analyticsHelper: analyticsHelper,
                    previousPaymentOption: previousPaymentOption
                )
            case .vertical, .automatic:
                return PaymentSheetVerticalViewController(
                    configuration: configuration,
                    loadResult: loadResult,
                    isFlowController: true,
                    analyticsHelper: analyticsHelper,
                    previousPaymentOption: previousPaymentOption
                )
            }
        }
    }
}

// MARK: - FlowControllerViewControllerDelegate

protocol FlowControllerViewControllerDelegate: AnyObject {
    func flowControllerViewControllerShouldClose(
        _ PaymentSheetFlowControllerViewController: FlowControllerViewControllerProtocol, didCancel: Bool)
}

extension PaymentSheet.FlowController: FlowControllerViewControllerDelegate {
    func flowControllerViewControllerShouldClose(
        _ flowControllerViewController: FlowControllerViewControllerProtocol,
        didCancel: Bool
    ) {
        if !didCancel {
            self.didPresentAndContinue = true
        }
        flowControllerViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
            self.isPresented = false
        }
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

    func presentPollingVCForAction(action: STPPaymentHandlerPaymentIntentActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        let pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
                                              appearance: self.appearance, safariViewController: safariViewController)
        presentingViewController.present(pollingVC, animated: true, completion: nil)
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        authenticationViewController.dismiss(animated: true, completion: completion)
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

// MARK: - FlowControllerViewControllerProtocol

/// All the things FlowController needs from its UIViewController.
internal protocol FlowControllerViewControllerProtocol: BottomSheetContentViewController {
    var error: Error? { get }
    var intent: Intent { get }
    var elementsSession: STPElementsSession { get }
    var selectedPaymentOption: PaymentOption? { get }
    /// The type of the Stripe payment method that's currently selected in the UI for new and saved PMs. Returns nil Apple Pay and .stripe(.link) for Link.
    /// Note that, unlike selectedPaymentOption, this is non-nil even if the PM form is invalid.
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? { get }
    var flowControllerDelegate: FlowControllerViewControllerDelegate? { get set }
}
