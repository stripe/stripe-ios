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

// TODO: Remove this before releasing version beta-2 + 2
@available(*, deprecated, message: "Use PaymentSheetResult instead", renamed: "PaymentSheetResult")
/// :nodoc:
public typealias PaymentResult = PaymentSheetResult

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
            apiClient: configuration.apiClient,
            clientSecret: intentClientSecret,
            ephemeralKey: configuration.customer?.ephemeralKeySecret,
            customerID: configuration.customer?.id
        ) { result in
            switch result {
            case .success((let intent, let paymentMethods)):
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePay != nil
                let paymentSheetVC = PaymentSheetViewController(
                    intent: intent,
                    savedPaymentMethods: paymentMethods,
                    configuration: self.configuration,
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
                self.bottomSheetViewController.contentStack = [paymentSheetVC]
            case .failure(let error):
                completion(.failed(error: error))
            }
        }

        presentingViewController.presentPanModal(bottomSheetViewController)
    }

    // MARK: - Internal Properties
    /// A customer can add these PaymentMethod types in PaymentSheet
    static let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .iDEAL]
    /// A customer can save, setup, and reuse these PaymentMethod types in PaymentSheet
    static let supportedPaymentMethodsForReuse: [STPPaymentMethodType] = [.card]

    let intentClientSecret: IntentClientSecret
    var completion: ((PaymentSheetResult) -> ())?
    lazy var bottomSheetViewController: BottomSheetViewController = {
        let vc = BottomSheetViewController(
            contentViewController: LoadingViewController(delegate: self)
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
                paymentOption: paymentOption)
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
                        presentingViewController?.presentPanModal(self.bottomSheetViewController)
                    }
                    completion(result)
                }
            }
        } else {
            confirm() { result in
                completion(result)
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
}

extension PaymentSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?(.canceled)
        }
    }
}

extension PaymentSheet: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier: String = "PaymentSheet"
}
