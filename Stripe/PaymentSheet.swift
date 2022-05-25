//
//  PaymentSheet.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import PassKit
@_spi(STP) import StripeCore

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
    
    /// The attempt failed.
    /// - Parameter error: The error encountered by the customer. You can display its `localizedDescription` to the customer.
    case failed(error: Error)
}

/// A drop-in class that presents a sheet for a customer to complete their payment
public class PaymentSheet {
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
            intentClientSecret: .paymentIntent(clientSecret: paymentIntentClientSecret),
            configuration: configuration
        )
    }
    
    /// Initializes a PaymentSheet
    /// - Parameter setupIntentClientSecret: The [client secret](https://stripe.com/docs/api/setup_intents/object#setup_intent_object-client_secret) of a Stripe SetupIntent object
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    public convenience init(setupIntentClientSecret: String, configuration: Configuration) {
        self.init(
            intentClientSecret: .setupIntent(clientSecret: setupIntentClientSecret),
            configuration: configuration
        )
    }
    
    required init(intentClientSecret: IntentClientSecret, configuration: Configuration) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.self)
        self.intentClientSecret = intentClientSecret
        self.configuration = configuration
        STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(configuration: configuration)
    }
    
    /// Presents a sheet for a customer to complete their payment
    /// - Parameter presentingViewController: The view controller to present a payment sheet
    /// - Parameter completion: Called with the result of the payment after the payment sheet is dismissed
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (PaymentSheetResult) -> ()
    ) {
        // Overwrite completion closure to retain self until called
        let completion: (PaymentSheetResult) -> () = { status in
            // Dismiss if necessary
            if self.bottomSheetViewController.presentingViewController != nil {
                self.bottomSheetViewController.dismiss(animated: true) {
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
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = PaymentSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }
        
        // Configure the Payment Sheet VC after loading the PI/SI, Customer, etc.
        PaymentSheet.load(
            clientSecret: intentClientSecret,
            configuration: configuration
        ) { result in
            switch result {
            case .success((let intent, let paymentMethods, let linkAccount)):
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePay != nil

                let presentPaymentSheetVC = { (linkAccount: PaymentSheetLinkAccount?, justVerifiedLinkOTP: Bool) in
                    let paymentSheetVC = PaymentSheetViewController(
                        intent: intent,
                        savedPaymentMethods: paymentMethods,
                        configuration: self.configuration,
                        linkAccount: linkAccount,
                        isApplePayEnabled: isApplePayEnabled,
                        delegate: self
                    )

                    // Workaround to silence a warning in the Catalyst target
                    #if targetEnvironment(macCatalyst)
                    self.configuration.style.configure(paymentSheetVC)
                    #else
                    if #available(iOS 13.0, *) {
                        self.configuration.style.configure(paymentSheetVC)
                    }
                    #endif

                    let updateBottomSheet: () -> Void = {
                        self.bottomSheetViewController.contentStack = [paymentSheetVC]
                    }

                    if linkAccount?.sessionState == .verified {
                        self.presentPayWithLinkController(
                            from: self.bottomSheetViewController,
                            linkAccount: linkAccount,
                            intent: intent,
                            shouldOfferApplePay: justVerifiedLinkOTP,
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
                
                if let linkAccount = linkAccount,
                   case .requiresVerification = linkAccount.sessionState {
                    
                    linkAccount.startVerification { [self] result in
                        switch result {
                        case .success(let collectOTP):
                            if collectOTP {
                                guard linkAccount.redactedPhoneNumber != nil else {
                                    assertionFailure()
                                    presentPaymentSheetVC(nil, false)
                                    return
                                }

                                let twoFactorViewController = Link2FAViewController(linkAccount: linkAccount) { [self] (status) in
                                    bottomSheetViewController.dismiss(animated: true, completion: nil)
                                    presentPaymentSheetVC(linkAccount, status == .completed)
                                }

                                bottomSheetViewController.present(twoFactorViewController, animated: true)
                            } else {
                                presentPaymentSheetVC(linkAccount, false)
                            }
                        case .failure(_):
                            STPAnalyticsClient.sharedClient.logLink2FAStartFailure()
                            presentPaymentSheetVC(nil, false)
                        }
                    }
                } else {
                    presentPaymentSheetVC(linkAccount, false)
                }
                
                
                
            case .failure(let error):
                completion(.failed(error: error))
            }
        }
        
        presentingViewController.presentPanModal(bottomSheetViewController, appearance: configuration.appearance)
    }
    
    // MARK: - Internal Properties

    /// The client secret this instance was initialized with
    let intentClientSecret: IntentClientSecret
    
    /// A user-supplied completion block. Nil until `present` is called.
    var completion: ((PaymentSheetResult) -> ())?
    
    /// The STPPaymentHandler instance
    lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient) }()
    
    /// The parent view controller to present
    lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = configuration.apiClient.isTestmode
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: configuration.appearance,
            isTestMode: isTestMode
        )
        
        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            didCancelNative3DS2: { [weak self] in
                self?.paymentHandler.cancel3DS2ChallengeFlow()
            }
        )

        if #available(iOS 13.0, *) {
            configuration.style.configure(vc)
        }
        return vc
    }()
    
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet: PaymentSheetViewControllerDelegate {

    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> ()
    ) {
        let presentingViewController = paymentSheetViewController.presentingViewController
        let confirm: (@escaping (PaymentSheetResult) -> ()) -> () = { completion in
            PaymentSheet.confirm(
                configuration: self.configuration,
                authenticationContext: self.bottomSheetViewController,
                intent: paymentSheetViewController.intent,
                paymentOption: paymentOption,
                paymentHandler: self.paymentHandler)
            { result in
                if case let .failed(error) = result {
                    self.mostRecentError = error
                }
                completion(result)
            }
        }
        
        if case .applePay = paymentOption {
            // Don't present the Apple Pay sheet on top of the Payment Sheet
            paymentSheetViewController.dismiss(animated: true) {
                confirm() { result in
                    if case .completed = result {
                    } else {
                        // We dismissed the Payment Sheet to show the Apple Pay sheet
                        // Bring it back if it didn't succeed
                        presentingViewController?.presentPanModal(self.bottomSheetViewController,
                                                                  appearance: self.configuration.appearance)
                    }
                    completion(result)
                }
            }
        } else {
            verifyLinkSessionIfNeeded(with: paymentOption, intent: paymentSheetViewController.intent) { shouldConfirm in
                if shouldConfirm {
                    confirm() { result in
                        completion(result)
                    }
                } else {
                    completion(.canceled)
                }
            }
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
        _ paymentSheetViewController: PaymentSheetViewController,
        linkAccount: PaymentSheetLinkAccount?
    ) {
        presentPayWithLinkController(
            from: paymentSheetViewController,
            linkAccount: linkAccount,
            intent: paymentSheetViewController.intent
        )
    }

    func paymentSheetViewControllerDidUpdate(
        _ paymentSheetViewController: PaymentSheetViewController,
        with paymentOption: PaymentOption?
    ) {
        // No-op
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

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet: PayWithLinkViewControllerDelegate {
    
    func payWithLinkViewControllerDidSelectPaymentOption(_ payWithLinkViewController: PayWithLinkViewController, paymentOption: PaymentOption) {
        // no-op for PaymentSheet complete flow
    }
    
    func payWithLinkViewControllerDidShouldConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        PaymentSheet.confirm(
            configuration: self.configuration,
            authenticationContext: self.bottomSheetViewController,
            intent: intent,
            paymentOption: paymentOption,
            paymentHandler: self.paymentHandler)
        { result in
            if case let .failed(error) = result {
                self.mostRecentError = error
            }

            STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                isCustom: false,
                paymentMethod: paymentOption.analyticsValue,
                result: result,
                linkEnabled: intent.supportsLink,
                activeLinkSession: payWithLinkViewController.linkAccount?.sessionState == .verified
            )

            completion(result)
        }
    }
    
    func payWithLinkViewControllerDidUpdateLinkAccount(_ payWithLinkViewController: PayWithLinkViewController, linkAccount: PaymentSheetLinkAccount?) {
        findPaymentSheetViewController()?.linkAccount = linkAccount
    }
    
    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        dismiss(payWithLinkViewController: payWithLinkViewController, completion: nil)
    }
    
    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult) {
        switch result {
        case .completed, .canceled:
            dismiss(payWithLinkViewController: payWithLinkViewController) {
                self.completion?(result)
            }
        case .failed(let error):
            payWithLinkViewController.dismiss(animated: true, completion: nil)
            self.findPaymentSheetViewController()?.set(error: error)
        }
    }
    
    func dismiss(payWithLinkViewController: PayWithLinkViewController, completion: (() -> Void)?) {
        payWithLinkViewController.dismiss(animated: true) {
            completion?()
        }
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
        linkAccount: PaymentSheetLinkAccount?,
        intent: Intent,
        shouldOfferApplePay: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        let payWithLinkVC = PayWithLinkViewController(
            linkAccount: linkAccount,
            intent: intent,
            configuration: configuration,
            selectionOnly: false,
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

    func verifyLinkSessionIfNeeded(
        with paymentOption: PaymentOption,
        intent: Intent,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard
            case .link(let linkAccount, _) = paymentOption,
            linkAccount.sessionState == .requiresVerification
        else {
            // No verification required
            completion?(true)
            return
        }

        linkAccount.startVerification { result in
            switch result {
            case .success(let collectOTP):
                guard collectOTP else {
                    // No OTP collection required
                    completion?(true)
                    return
                }

                let twoFAViewController = Link2FAViewController(
                    mode: .inlineLogin,
                    linkAccount: linkAccount
                ) { completionStatus in
                    self.bottomSheetViewController.dismiss(animated: true, completion: nil)

                    switch completionStatus {
                    case .completed:
                        completion?(true)
                    case .canceled:
                        completion?(false)
                    }
                }

                self.bottomSheetViewController.present(twoFAViewController, animated: true)
            case .failure(_):
                STPAnalyticsClient.sharedClient.logLink2FAStartFailure()

                // If `startVerification` fails we should still move forward with
                // intent confirmation. The confirmation logic will fallback to
                // confirming without saving to Link.
                completion?(true)
                break
            }
        }
    }

}
