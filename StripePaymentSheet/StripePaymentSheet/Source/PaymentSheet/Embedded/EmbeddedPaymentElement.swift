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
@MainActor
public final class EmbeddedPaymentElement {

    /// A view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
    public var view: UIView {
        return containerView
    }

    /// A view controller to present on.
    public var presentingViewController: UIViewController?

    /// This contains the `configuration` you passed in to `create`.
    public let configuration: Configuration

    /// See `EmbeddedPaymentElementDelegate`.
    public weak var delegate: EmbeddedPaymentElementDelegate?

    /// Contains details about a payment method that can be displayed to the customer
    public struct PaymentOptionDisplayData: Equatable {
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
        /// If you set `configuration.embeddedViewDisplaysMandateText = false`, this text must be displayed to the customer near your “Buy” button to comply with regulations.
        public let mandateText: NSAttributedString?
    }

    /// Contains information about the customer's selected payment option.
    /// Use this to display the payment option in your own UI
    public var paymentOption: PaymentOptionDisplayData? {
        return embeddedPaymentMethodsView.displayData
    }

    /// An asynchronous failable initializer
    /// Loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the confirmation.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Returns: A valid EmbeddedPaymentElement instance
    /// - Throws: An error if loading failed.
    public static func create(
        intentConfiguration: IntentConfiguration,
        configuration: Configuration
    ) async throws -> EmbeddedPaymentElement {
        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedPaymentElement.self)
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .embedded, configuration: configuration)

        let loadResult = try await PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfiguration),
            configuration: configuration,
            analyticsHelper: analyticsHelper,
            integrationShape: .embedded
        )
        let embeddedPaymentElement: EmbeddedPaymentElement = .init(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )
        return embeddedPaymentElement
    }

    /// The result of an `update` call
    @frozen public enum UpdateResult {
        /// The update succeeded
        case succeeded
        /// The update was canceled. This is only returned when a subsequent `update` call cancels previous ones.
        case canceled
        /// The update call failed e.g. due to network failure or because of an invalid IntentConfiguration. Your integration should retry with exponential backoff.
        case failed(error: Error)
    }

    /// Call this method when the IntentConfiguration values you used to initialize `EmbeddedPaymentElement` (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, collect the right fields, etc.
    /// - Parameter intentConfiguration: An updated IntentConfiguration.
    /// - Returns: The result of the update.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    /// - Note: If you call `update` while a previous call to `update` is still in progress, the previous call returns `.canceled`.
    public func update(
        intentConfiguration: IntentConfiguration
    ) async -> UpdateResult {
        // Cancel the old task and let it finish so that merchants receive update results in order
        currentUpdateTask?.cancel()
        _ = await currentUpdateTask?.value
        // Start the new update task
        let currentUpdateTask = Task { [weak self, configuration, paymentOption, analyticsHelper] in
            // 1. Reload v1/elements/session.
            let loadResult: PaymentSheetLoader.LoadResult
            do {
                // TODO(nice to have): Make `load` respect task cancellation to reduce network consumption
                loadResult = try await PaymentSheetLoader.load(
                    mode: .deferredIntent(intentConfiguration),
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    integrationShape: .embedded
                )
            } catch {
                return UpdateResult.failed(error: error)
            }
            guard !Task.isCancelled else {
                return UpdateResult.canceled
            }

            // 2. Re-initialize embedded view to update the UI to match the newly loaded data.
            let embeddedPaymentMethodsView = Self.makeView(
                configuration: configuration,
                loadResult: loadResult,
                analyticsHelper: analyticsHelper,
                delegate: self
                // TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2583 Restore previous payment option
            )

            // 2. Pre-load image into cache
            // Hack: Accessing paymentOption has the side-effect of ensuring its `image` property is loaded (from the internet instead of disk) before we call the completion handler.
            // Call this on a detached Task b/c this synchronously (!) loads the image from network and we don't want to block the main actor
            let fetchPaymentOption = Task.detached(priority: .userInitiated) {
                return await embeddedPaymentMethodsView.displayData
            }
            _ = await fetchPaymentOption.value

            guard let self, !Task.isCancelled else {
                return .canceled
            }
            // At this point, we're the latest update - update self properties and inform our delegate.
            self.loadResult = loadResult
            self.embeddedPaymentMethodsView = embeddedPaymentMethodsView
            self.containerView.updateEmbeddedPaymentMethodsView(embeddedPaymentMethodsView)
            if paymentOption != embeddedPaymentMethodsView.displayData {
                self.delegate?.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: self)
            }
            return .succeeded
        }
        self.currentUpdateTask = currentUpdateTask
        return await currentUpdateTask.value
    }

    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method presents authentication screens on the instance's  `presentingViewController` property.
    public func confirm() async -> EmbeddedPaymentElementResult {
        // TODO
        return .canceled
    }

    // MARK: - Internal

    internal private(set) var containerView: EmbeddedPaymentElementContainerView
    internal private(set) var embeddedPaymentMethodsView: EmbeddedPaymentMethodsView
    internal private(set) var loadResult: PaymentSheetLoader.LoadResult
    internal private(set) var currentUpdateTask: Task<UpdateResult, Never>?
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    private init(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.configuration = configuration
        self.loadResult = loadResult
        self.embeddedPaymentMethodsView = Self.makeView(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )
        self.containerView = EmbeddedPaymentElementContainerView(
            embeddedPaymentMethodsView: embeddedPaymentMethodsView
        )

        self.analyticsHelper = analyticsHelper
        analyticsHelper.logInitialized()
        self.containerView.updateSuperviewHeight = { [weak self] in
            guard let self else { return }
            self.delegate?.embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: self)
        }
        self.embeddedPaymentMethodsView.delegate = self
    }
}

// MARK: - STPAnalyticsProtocol
/// :nodoc:
@_spi(STP) extension EmbeddedPaymentElement: STPAnalyticsProtocol {
    @_spi(STP) public nonisolated static let stp_analyticsIdentifier: String = "EmbeddedPaymentElement"
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

@_spi(EmbeddedPaymentElementPrivateBeta) public typealias EmbeddedPaymentElementResult = PaymentSheetResult
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
