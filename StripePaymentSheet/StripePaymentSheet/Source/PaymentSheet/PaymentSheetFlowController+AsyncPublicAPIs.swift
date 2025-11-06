//
//  PaymentSheetFlowController+AsyncPublicAPIs.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/1/25.
//

import UIKit

extension PaymentSheet.FlowController {
    /// An asynchronous failable initializer for PaymentSheet.FlowController
    /// This asynchronously loads the Customer's payment methods, their default payment method, and the PaymentIntent.
    /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
    /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    /// - Returns: A PaymentSheet.FlowController instance.
    /// - Throws: An error if loading failed.
    public static func create(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration
    ) async throws -> PaymentSheet.FlowController {
        return try await withCheckedThrowingContinuation { continuation in
            create(mode: .paymentIntentClientSecret(paymentIntentClientSecret), configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// An asynchronous failable initializer for PaymentSheet.FlowController
    /// This asynchronously loads the Customer's payment methods, their default payment method, and the SetuptIntent.
    /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
    /// - Parameter setupIntentClientSecret: The [client secret](https://stripe.com/docs/api/setup_intents/object#setup_intent_object-client_secret) of a Stripe SetupIntent object
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    /// - Returns: A PaymentSheet.FlowController instance.
    /// - Throws: An error if loading failed.
    public static func create(
        setupIntentClientSecret: String,
        configuration: PaymentSheet.Configuration
    ) async throws -> PaymentSheet.FlowController {
        return try await withCheckedThrowingContinuation { continuation in
            create(setupIntentClientSecret: setupIntentClientSecret, configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// An asynchronous failable initializer for PaymentSheet.FlowController
    /// This asynchronously loads the Customer's payment methods, their default payment method.
    /// You can use the returned PaymentSheet.FlowController instance to e.g. update your UI with the Customer's default payment method
    /// - Parameter intentConfiguration: Information about the payment or setup used to render the UI
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, Customer details, etc.
    /// - Returns: A valid PaymentSheet.FlowController instance.
    /// - Throws: An error if loading failed.
    public static func create(
        intentConfiguration: PaymentSheet.IntentConfiguration,
        configuration: PaymentSheet.Configuration
    ) async throws -> PaymentSheet.FlowController {
        return try await withCheckedThrowingContinuation { continuation in
            create(intentConfiguration: intentConfiguration, configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Presents a sheet where the customer chooses how to pay, either by selecting an existing payment method or adding a new one
    /// Call this when your "Select a payment method" button is tapped
    /// This method returns after the sheet is dismissed. Use the `paymentOption` property to get the customer's desired payment option.
    /// - Parameter presentingViewController: The view controller that presents the sheet.
    public func presentPaymentOptions(
        from presentingViewController: UIViewController
    ) async {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                presentPaymentOptions(from: presentingViewController) {
                    continuation.resume()
                }
            }
        }
    }

    /// Completes the payment or setup.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
    /// - Returns: The result of the payment after any presented view controllers are dismissed
    public func confirm(
        from presentingViewController: UIViewController
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                confirm(from: presentingViewController) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// Call this method when the IntentConfiguration values you used to initialize PaymentSheet.FlowController (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, etc.
    /// When this method returns, your implementation should get the customer's updated payment option by using the `paymentOption` property and update your UI.
    /// - Parameter intentConfiguration: An updated IntentConfiguration
    /// - Throws: An error if the update fails. You should retry the update; the FlowController instance is not usable until the update succeeds.
    /// - Note: Don't call `confirm` or `present` until the update succeeds. Don't call this method while PaymentSheet is being presented.
    public func update(intentConfiguration: PaymentSheet.IntentConfiguration) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                update(intentConfiguration: intentConfiguration) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
