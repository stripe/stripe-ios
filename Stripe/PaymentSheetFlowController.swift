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
        
        enum LinkConfirmOption {
            /// Signup for Link then pay
            case forNewAccount(phoneNumber: PhoneNumber,
                               paymentMethodParams: STPPaymentMethodParams)
            
            /// Confirm intent with paymentDetails
            case withPaymentDetails(paymentDetails: ConsumerPaymentDetails)

            /// Confirm with Payment Method Params
            case withPaymentMethodParams(paymentMethodParams: STPPaymentMethodParams)
        }
        
        case applePay
        case saved(paymentMethod: STPPaymentMethod)
        case new(confirmParams: IntentConfirmParams)
        case link(account: PaymentSheetLinkAccount, option: LinkConfirmOption)
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
                    label = confirmParams.paymentMethodParams.paymentSheetLabel
                case .link(_, let confirmOption):
                    switch confirmOption {
                    case .forNewAccount(_, paymentMethodParams: let paymentMethodParams):
                        label = paymentMethodParams.paymentSheetLabel
                    case .withPaymentDetails(let paymentDetails):
                        label = paymentDetails.paymentSheetLabel
                    case .withPaymentMethodParams(let paymentMethodParams):
                        label = paymentMethodParams.paymentSheetLabel
                    }
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
        private var linkAccount: PaymentSheetLinkAccount? {
            didSet {
                paymentOptionsViewController.linkAccount = linkAccount
            }
        }
        private lazy var paymentOptionsViewController: ChoosePaymentOptionViewController = {
            let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && configuration.applePay != nil
            let vc = ChoosePaymentOptionViewController(
                intent: intent,
                savedPaymentMethods: savedPaymentMethods,
                configuration: configuration,
                isApplePayEnabled: isApplePayEnabled,
                linkAccount: linkAccount,
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
        private var walletSelectedPaymentOption: PaymentOption?
        /// The desired, valid (ie passed client-side checks) payment option from the underlying payment options VC.
        private var _paymentOption: PaymentOption? {
            guard paymentOptionsViewController.error == nil else {
                return nil
            }
            if let walletSelectedPaymentOption = walletSelectedPaymentOption {
                return walletSelectedPaymentOption
            } else if let paymentOption = paymentOptionsViewController.selectedPaymentOption {
                return paymentOption
            }
            return nil
        }

        // MARK: - Initializer (Internal)

        required init(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            linkAccount: PaymentSheetLinkAccount?,
            configuration: Configuration
        ) {
            STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.FlowController.self)
            STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(isCustom: true, configuration: configuration)
            self.intent = intent
            self.savedPaymentMethods = savedPaymentMethods
            self.linkAccount = linkAccount
            self.configuration = configuration

            // Set the current elements theme
            ElementsUITheme.current = configuration.appearance.asElementsTheme
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
                case .success((let intent, let paymentMethods, let linkAccount)):
                    let manualFlow = FlowController(
                        intent: intent,
                        savedPaymentMethods: paymentMethods,
                        linkAccount: linkAccount,
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

            let presentPaymentOptionsVC = { [self] (linkAccount: PaymentSheetLinkAccount?, justVerifiedLinkOTP: Bool) in
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let bottomSheetVC = BottomSheetViewController(
                    contentViewController: paymentOptionsViewController,
                    appearance: configuration.appearance,
                    isTestMode: configuration.apiClient.isTestmode,
                    didCancelNative3DS2: { [weak self] in
                        self?.paymentHandler.cancel3DS2ChallengeFlow()
                    })
                // Workaround to silence a warning in the Catalyst target
                #if targetEnvironment(macCatalyst)
                self.configuration.style.configure(bottomSheetVC)
                #else
                if #available(iOS 13.0, *) {
                    self.configuration.style.configure(bottomSheetVC)
                }
                #endif


                if linkAccount?.sessionState == .verified {
                    // hiding this isn't a great solution, it still shows an empty
                    // modal for a moment but that feels a bit less jarring than one
                    // with content.
                    // We can't do the same as complete flow because the bottom sheet
                    // isn't what's presenting, i.e. it has to be presented first
                    // (in complete we have already presented the bottom sheet during
                    // load).
                    bottomSheetVC.view.isHidden = true
                    
                    presentingViewController.presentPanModal(bottomSheetVC, appearance: configuration.appearance) { [self] in
                        self.presentPayWithLinkController(
                            from: paymentOptionsViewController,
                            linkAccount: linkAccount,
                            intent: intent,
                            shouldOfferApplePay: justVerifiedLinkOTP,
                            completion: {
                                // Update the bottom sheet after presenting the Link controller
                                // to avoid briefly flashing the PaymentSheet in the middle of
                                // the View Controller transition.
                                bottomSheetVC.view.isHidden = false
                            }
                        )
                    }
                } else {
                    presentingViewController.presentPanModal(bottomSheetVC, appearance: configuration.appearance)
                }
            }
            

            if let linkAccount = linkAccount,
               case .requiresVerification = linkAccount.sessionState {
                
                linkAccount.startVerification { result in
                    switch result {
                    case .success(let collectOTP):
                        if collectOTP {
                            guard linkAccount.redactedPhoneNumber != nil else {
                                assertionFailure()
                                presentPaymentOptionsVC(nil, false)
                                return
                            }

                            let twoFactorViewController = Link2FAViewController(linkAccount: linkAccount) { (status) in
                                presentingViewController.dismiss(animated: true, completion: nil)
                                presentPaymentOptionsVC(linkAccount, status == .completed)
                            }

                            presentingViewController.present(twoFactorViewController, animated: true)
                        } else {
                            presentPaymentOptionsVC(linkAccount, false)
                        }
                    case .failure(_):
                        STPAnalyticsClient.sharedClient.logLink2FAStartFailure()
                        presentPaymentOptionsVC(nil, false)
                    }
                }
            } else {
                presentPaymentOptionsVC(linkAccount, false)
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

            let authenticationContext = AuthenticationContext(presentingViewController: presentingViewController)

            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: authenticationContext,
                intent: intent,
                paymentOption: paymentOption,
                paymentHandler: paymentHandler
            ) { result in
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                    isCustom: true,
                    paymentMethod: paymentOption.analyticsValue,
                    result: result,
                    linkEnabled: self.intent.supportsLink,
                    activeLinkSession: self.linkAccount?.sessionState == .verified
                )
                completion(result)
            }
        }
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet.FlowController: ChoosePaymentOptionViewControllerDelegate {
    func choosePaymentOptionViewControllerDidSelectApplePay(_ choosePaymentOptionViewController: ChoosePaymentOptionViewController) {
        walletSelectedPaymentOption = .applePay
        choosePaymentOptionViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
        }
    }
    
    func choosePaymentOptionViewControllerDidSelectPayWithLink(_ choosePaymentOptionViewController: ChoosePaymentOptionViewController, linkAccount: PaymentSheetLinkAccount?) {
        self.presentPayWithLinkController(from: choosePaymentOptionViewController,
                                          linkAccount: linkAccount,
                                          intent: intent,
                                          paymentMethodParams: nil,
                                          completion: nil)
    }
    
    func choosePaymentOptionViewControllerShouldClose(
        _ choosePaymentOptionViewController: ChoosePaymentOptionViewController
    ) {
        choosePaymentOptionViewController.dismiss(animated: true) {
            self.presentPaymentOptionsCompletion?()
        }
    }
    
    func presentPayWithLinkController(
        from presentingController: UIViewController,
        linkAccount: PaymentSheetLinkAccount?,
        intent: Intent,
        shouldOfferApplePay: Bool = false,
        paymentMethodParams: STPPaymentMethodParams? = nil,
        completion: (() -> Void)? = nil
    ) {
        let payWithLinkVC = PayWithLinkViewController(
            linkAccount: linkAccount,
            intent: intent,
            configuration: configuration,
            selectionOnly: true,
            shouldOfferApplePay: shouldOfferApplePay
        )
        payWithLinkVC.payWithLinkDelegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            payWithLinkVC.modalPresentationStyle = .formSheet
        } else {
            payWithLinkVC.modalPresentationStyle = .overFullScreen
        }

        presentingController.present(payWithLinkVC, animated: true, completion: completion)
    }
    
    func choosePaymentOptionViewControllerDidUpdateSelection(_ choosePaymentOptionViewController: ChoosePaymentOptionViewController) {
        walletSelectedPaymentOption = nil
    }
}

/// :nodoc:
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(STP) extension PaymentSheet.FlowController: STPAnalyticsProtocol {
    @_spi(STP) public static let stp_analyticsIdentifier: String = "PaymentSheet.FlowController"
}

/// A simple STPAuthenticationContext that wraps a UIViewController
/// For internal SDK use only
@objc(STP_Internal_AuthenticationContext)
class AuthenticationContext: NSObject, PaymentSheetAuthenticationContext {
    func present(_ threeDS2ChallengeViewController: UIViewController, completion: @escaping () -> Void) {
        presentingViewController.present(threeDS2ChallengeViewController, animated: true, completion: nil)
    }
    
    func dismiss(_ threeDS2ChallengeViewController: UIViewController) {
        threeDS2ChallengeViewController.dismiss(animated: true, completion: nil)
    }
    
    let presentingViewController: UIViewController

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }
    func authenticationPresentingViewController() -> UIViewController {
        return presentingViewController
    }
}

/// :nodoc:
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet.FlowController: PayWithLinkViewControllerDelegate {
    func payWithLinkViewControllerDidShouldConfirm(_ payWithLinkViewController: PayWithLinkViewController,
                                                   intent: Intent,
                                                   with paymentOption: PaymentOption,
                                                   completion: @escaping (PaymentSheetResult) -> Void) {
        assertionFailure("Confirming from Link Modal not supported in Custom Flow")
    }
    
    func payWithLinkViewControllerDidUpdateLinkAccount(_ payWithLinkViewController: PayWithLinkViewController, linkAccount: PaymentSheetLinkAccount?) {
        self.linkAccount = linkAccount
    }
    
    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkViewController.dismiss(animated: true, completion: nil)
    }
    
    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult) {
        // no-op
    }
    
    func payWithLinkViewControllerDidSelectPaymentOption(_ payWithLinkViewController: PayWithLinkViewController, paymentOption: PaymentOption) {
        walletSelectedPaymentOption = paymentOption
        payWithLinkViewController.dismiss(animated: true) {
            self.paymentOptionsViewController.dismiss(animated: true) {
                self.presentPaymentOptionsCompletion?()
            }
        }
    }
    
    
}
