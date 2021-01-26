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

/// The result of an attempt to confirm a PaymentIntent
/// You may use this to notify the customer of the status of their payment attempt in your app
@frozen public enum PaymentResult {
    /// The payment attempt successfully completed.
    ///
    /// Some types of payment methods take time to transfer money. You should inspect the PaymentIntent status:
    ///  - If it's `.succeeded`, money successfully moved; you may e.g. show a receipt view to the customer.
    ///  - If it's `.processing`, the PaymentMethod is asynchronous and money has not yet moved. You may e.g. inform the customer their order is pending.
    ///
    /// To notify your backend of the payment and e.g. fulfill the order, see https://stripe.com/docs/payments/handling-payment-events
    /// - Parameter paymentIntent: The underlying PaymentIntent.
    case completed(paymentIntent: STPPaymentIntent)

    /// The customer canceled the payment.
    /// - Parameter paymentIntent: The underlying PaymentIntent, if one exists.
    case canceled(paymentIntent: STPPaymentIntent?)

    /// The payment attempt failed.
    /// - Parameter error: The error encountered by the customer. You can display its `localizedDescription` to the customer.
    /// - Parameter paymentIntent: The underlying PaymentIntent, if one exists.
    case failed(error: Error, paymentIntent: STPPaymentIntent?)
}

/// A drop-in class that presents a sheet for a customer to complete their payment
public class PaymentSheet {
    /// The client secret of the Stripe PaymentIntent object
    /// See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret
    /// Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    public let paymentIntentClientSecret: String

    /// This contains all configurable properties of PaymentSheet
    public let configuration: Configuration

    /// The most recent error encountered by the customer, if any.
    public private(set) var mostRecentError: Error?

    /// Initializes a PaymentSheet
    /// - Parameter paymentIntentClientSecret: The client secret of the Stripe PaymentIntent object
    ///     See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret
    ///     Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    public required init(paymentIntentClientSecret: String, configuration: Configuration) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.self)
        self.paymentIntentClientSecret = paymentIntentClientSecret
        self.configuration = configuration
        STPAnalyticsClient.sharedClient.logPaymentSheetInitialized(configuration: configuration)
    }

    /// Presents a sheet for a customer to complete their payment
    /// - Parameter presentingViewController: The view controller to present a payment sheet
    /// - Parameter completion: Called with the result of the payment after the payment sheet is dismissed
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public func present(from presentingViewController: UIViewController, completion: @escaping (PaymentResult) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (PaymentResult) -> () = { status in
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
            let error = PaymentSheetError.unknown(debugDescription: "presentingViewController is already presenting a view controller")
            completion(.failed(error: error, paymentIntent: nil))
            return
        }

        // Configure the Payment Sheet VC after loading the PI, Customer, etc.
        PaymentSheet.load(apiClient: configuration.apiClient,
                          clientSecret: paymentIntentClientSecret,
                          ephemeralKey: configuration.customer?.ephemeralKeySecret,
                          customerID: configuration.customer?.id) { result in
            switch result {
            case .success((let paymentIntent, let paymentMethods)):
                guard paymentIntent.status == .requiresPaymentMethod else {
                    let message = paymentIntent.status == .succeeded ? "PaymentSheet received a PaymentIntent that is already completed!" : "PaymentSheet received a PaymentIntent in an unexpected state: \(paymentIntent.status)"
                    assertionFailure(message)
                    let error = PaymentSheetError.unknown(debugDescription: message)
                    self.completion?(.failed(error: error, paymentIntent: nil))
                    return
                }
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePay != nil
                let paymentSheetVC = PaymentSheetViewController(paymentIntent: paymentIntent,
                                                                savedPaymentMethods: paymentMethods,
                                                                configuration: self.configuration,
                                                                isApplePayEnabled: isApplePayEnabled,
                                                                delegate: self)
                if #available(iOS 13.0, *) {
                    self.configuration.style.configure(paymentSheetVC)
                }
                self.bottomSheetViewController.contentStack = [paymentSheetVC]
            case .failure(let error):
                self.completion?(.failed(error: error, paymentIntent: nil))
            }
        }

        presentingViewController.presentPanModal(bottomSheetViewController)
    }

    // MARK: - Internal Properties

    var completion: ((PaymentResult) -> ())?

    lazy var bottomSheetViewController: BottomSheetViewController = {
        let vc = BottomSheetViewController(contentViewController: LoadingViewController(delegate: self))
        if #available(iOS 13.0, *) {
            configuration.style.configure(vc)
        }
        return vc
    }()

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: PaymentSheetViewController,
                                                 with paymentOption: PaymentOption,
                                                 completion: @escaping (PaymentResult) -> ()) {
        let presentingViewController = paymentSheetViewController.presentingViewController
        let confirm: (@escaping (PaymentResult) -> ()) -> () = { completion in
            PaymentSheet.confirm(configuration: self.configuration,
                                 applePayPresenter: presentingViewController,
                                 authenticationContext: self.bottomSheetViewController,
                                 paymentIntent: paymentSheetViewController.paymentIntent,
                                 paymentOption: paymentOption,
                                 completion: { result in
                                    if case let .failed(error, _) = result {
                                        self.mostRecentError = error
                                    }
                                    completion(result)
                                 })
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

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: PaymentSheetViewController, result: PaymentResult) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(result)
        }
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: PaymentSheetViewController) {
        paymentSheetViewController.dismiss(animated: true) {
            self.completion?(.canceled(paymentIntent: paymentSheetViewController.paymentIntent))
        }
    }
}

extension PaymentSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?(.canceled(paymentIntent: nil))
        }
    }
}

extension PaymentSheet: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier: String = "PaymentSheet"
}
