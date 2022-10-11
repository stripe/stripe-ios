//
//  PaymentSheetFlowController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

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
                image = paymentOption.makeIcon()
                switch paymentOption {
                case .applePay:
                    label = STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
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

        private var intent: Intent
        private let savedPaymentMethods: [STPPaymentMethod]
        lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient) }()

        private let isLinkEnabled: Bool

        private lazy var paymentOptionsViewController: ChoosePaymentOptionViewController = {
            let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && configuration.applePay != nil
            let vc = ChoosePaymentOptionViewController(
                intent: intent,
                savedPaymentMethods: savedPaymentMethods,
                configuration: configuration,
                isApplePayEnabled: isApplePayEnabled,
                isLinkEnabled: isLinkEnabled,
                delegate: self
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
        }()
        private var presentPaymentOptionsCompletion: (() -> ())? = nil

        /// The desired, valid (ie passed client-side checks) payment option from the underlying payment options VC.
        private var _paymentOption: PaymentOption? {
            guard paymentOptionsViewController.error == nil else {
                return nil
            }

            return paymentOptionsViewController.selectedPaymentOption
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
            self.intent = intent
            self.savedPaymentMethods = savedPaymentMethods
            self.isLinkEnabled = isLinkEnabled
            self.configuration = configuration
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
            create(clientSecret: .paymentIntent(clientSecret: paymentIntentClientSecret),
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
            create(clientSecret: .setupIntent(clientSecret: setupIntentClientSecret),
                   configuration: configuration,
                   completion: completion
            )
        }

        static func create(
            clientSecret: IntentClientSecret,
            configuration: PaymentSheet.Configuration,
            completion: @escaping (Result<PaymentSheet.FlowController, Error>) -> Void
        ) {
            PaymentSheet.load(
                clientSecret: clientSecret,
                configuration: configuration
            ) { result in
                switch result {
                case .success(let intent, let paymentMethods, let isLinkEnabled):
                    // Verify that there are payment method types available for the intent and configuration.
                    let paymentMethodTypes = PaymentMethodType.filteredPaymentMethodTypes(
                        from: intent,
                        configuration: configuration)
                    guard !paymentMethodTypes.isEmpty else {
                        completion(.failure(PaymentSheetError.noPaymentMethodTypesAvailable))
                        return
                    }

                    let manualFlow = FlowController(
                        intent: intent,
                        savedPaymentMethods: paymentMethods,
                        isLinkEnabled: isLinkEnabled,
                        configuration: configuration)
                    completion(.success(manualFlow))
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
            completion: (() -> ())? = nil
        ) {
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
                    self.paymentOptionsViewController,
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
                        self?.paymentOptionsViewController.selectLink()
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
            completion: @escaping (PaymentSheetResult) -> ()
        ) {
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
                    activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified
                )

                if case .completed = result, case .link = paymentOption {
                    // Remember Link as default payment method for users who just created an account.
                    DefaultPaymentMethodStore.setDefaultPaymentMethod(.link, forCustomer: configuration.customer?.id)
                }

                completion(result)
            }
        }
        
        // MARK: Internal helper methods
        static func makeBottomSheetViewController(
            _ contentViewController: BottomSheetContentViewController,
            configuration: Configuration,
            didCancelNative3DS2: (() -> ())? = nil
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
    }
}

// MARK: - ChoosePaymentOptionViewControllerDelegate
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet.FlowController: ChoosePaymentOptionViewControllerDelegate {
    func choosePaymentOptionViewControllerShouldClose(
        _ choosePaymentOptionViewController: ChoosePaymentOptionViewController
    ) {
        choosePaymentOptionViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
        }
    }

    func choosePaymentOptionViewControllerDidUpdateSelection(
        _ choosePaymentOptionViewController: ChoosePaymentOptionViewController
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
    func present(_ viewController: BottomSheetContentViewController) {
        presentingViewController.present(viewController, animated: true, completion: nil)

    }
    
    func dismiss(_ viewController: BottomSheetContentViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func present(_ threeDS2ChallengeViewController: UIViewController, completion: @escaping () -> Void) {
        presentingViewController.present(threeDS2ChallengeViewController, animated: true, completion: nil)
    }
    
    func dismiss(_ threeDS2ChallengeViewController: UIViewController) {
        threeDS2ChallengeViewController.dismiss(animated: true, completion: nil)
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
