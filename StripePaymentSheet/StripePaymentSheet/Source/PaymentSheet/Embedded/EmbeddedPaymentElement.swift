//
//  EmbeddedPaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// An object that manages a view that displays payment methods and completes a checkout.
@_spi(EmbeddedPaymentElementPrivateBeta)
public class EmbeddedPaymentElement {

    /// A view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
    public let view: UIView

    /// A view controller to present on.
    public var presentingViewController: UIViewController?

    /// See `EmbeddedPaymentElementDelegate`.
    public weak var delegate: EmbeddedPaymentElementDelegate?

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
        /// If you set `configuration.hidesMandateText = true`, this text must be displayed to the customer near your “Buy” button to comply with regulations.
        public let mandateText: NSAttributedString
    }

    /// The customer's currently selected payment option.
    public var paymentOption: PaymentOptionDisplayData? { return nil /* computed */ }

    /// An asynchronous failable initializer
    /// This loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the checkout.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Returns: A valid EmbeddedPaymentElement instance
    /// - Throws: An error if loading failed.
    public static func create(
        intentConfiguration: IntentConfiguration,
        configuration: Configuration
    ) async throws -> EmbeddedPaymentElement {
        // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-2525)
        let dummyView = await EmbeddedPaymentMethodsView(
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true
        )
        return .init(view: dummyView)
    }

    /// The result of an `update` call
    public enum UpdateResult {
        /// The update succeded
        case succeeded
        /// The update was canceled. This is only returned when a subsequent `update` call cancels previous ones.
        case canceled
        /// The update call failed e.g. due to network failure or because of an invalid IntentConfiguration. Your integration should retry with exponential backoff.
        case failed(error: Error)
    }

    /// Call this method when the IntentConfiguration values you used to initialize `EmbeddedPaymentElement` (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, collect the right fields, etc.
    /// - Parameter intentConfiguration: An updated IntentConfiguration.
    /// - Returns: The result of the update. Any calls made to `update` before this call that are still in progress will return a `.canceled` result.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    public func update(
        intentConfiguration: IntentConfiguration
    ) async -> UpdateResult {
        // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-2524)
        return .canceled
    }

    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method presents authentication screens on the instance's  `presentingViewController` property.
    public func confirm() async -> EmbeddedPaymentElementResult {
        // TODO
        return .canceled
    }

    // MARK: - Internal

    private init(view: UIView, delegate: EmbeddedPaymentElementDelegate? = nil) {
        self.view = view
        self.delegate = delegate
    }
}

// MARK: - Completion-block based APIs
extension EmbeddedPaymentElement {
    /// Creates an instance of `EmbeddedPaymentElement`
    /// This loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the checkout.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Parameter completion: A completion block containing a valid EmbeddedPaymentElement instance or an error. Called on the main thread.
    /// - Returns: A valid EmbeddedPaymentElement instance
    /// - Throws: An error if loading failed.
    public static func create(
        intentConfiguration: IntentConfiguration,
        configuration: Configuration,
        completion: @escaping (Result<EmbeddedPaymentElement, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await create(
                    intentConfiguration: intentConfiguration,
                    configuration: configuration
                )
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Call this method when the IntentConfiguration values you used to initialize `EmbeddedPaymentElement` (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, collect the right fields, etc.
    /// - Parameter intentConfiguration: An updated IntentConfiguration.
    /// - Parameter completion: A completion block containing the result of the update. Called on the main thread.
    /// - Returns: The result of the update. Any calls made to `update` before this call that are still in progress will return a `.canceled` result.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    public func update(
        intentConfiguration: IntentConfiguration,
        completion: @escaping (UpdateResult) -> Void
    ) {
        Task {
            let result = await update(intentConfiguration: intentConfiguration)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Completes the payment or setup.
    /// - Parameter completion: Called with the result of the payment after any presented view controllers are dismissed. Called on the mai thread.
    /// - Note: This method presents authentication screens on the instance's  `presentingViewController` property.
    public func confirm(completion: @escaping (EmbeddedPaymentElementResult) -> Void) {
        Task {
            let result = await confirm()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// MARK: - Typealiases

@_spi(STP) public typealias EmbeddedPaymentElementResult = PaymentSheetResult
extension EmbeddedPaymentElement {
    public typealias IntentConfiguration = PaymentSheet.IntentConfiguration
    public typealias UserInterfaceStyle = PaymentSheet.UserInterfaceStyle
    public typealias SavePaymentMethodOptInBehavior = PaymentSheet.SavePaymentMethodOptInBehavior
    public typealias ApplePayConfiguration = PaymentSheet.ApplePayConfiguration
    public typealias CustomerConfiguration = PaymentSheet.CustomerConfiguration
    public typealias BillingDetails = PaymentSheet.BillingDetails
    public typealias Address = PaymentSheet.Address
    public typealias BillingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration
    public typealias ExternalPaymentMethodConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration
}
