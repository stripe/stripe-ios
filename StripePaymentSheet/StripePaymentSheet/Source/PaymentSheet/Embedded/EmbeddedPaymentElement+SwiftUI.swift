//
//  EmbeddedPaymentElement+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/29/25.
//

import Combine
@_spi(STP) import StripeCore
import SwiftUI

/// A view model that manages an `EmbeddedPaymentElement`.
@MainActor
@_spi(EmbeddedPaymentElementPrivateBeta) public final class EmbeddedPaymentElementViewModel: ObservableObject {
    enum ViewModelError: Error, CustomDebugStringConvertible {
        /// The `EmbeddedPaymentElementViewModel` has not been loaded. Call `load()` before attempting this operation.
        case notLoaded

        /// `load()` has already been called. `load()` may only be called once.
        case alreadyLoaded

        var debugDescription: String {
            switch self {
            case .notLoaded:
                return "EmbeddedPaymentElementViewModel has not been loaded. Call `load()` before attempting this operation."
            case .alreadyLoaded:
                return "load() has already been called. `load()` may only be called once."
            }
        }
    }

    // MARK: - Public properties

    /// Indicates whether the `EmbeddedPaymentElementViewModel` has been successfully loaded.
    @Published public private(set) var isLoaded: Bool = false

    /// Contains information about the customer's selected payment option.
    /// Use this to display the payment option in your own UI
    @Published public private(set) var paymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData?

    // MARK: - Internal properties

    private(set) var embeddedPaymentElement: EmbeddedPaymentElement?

    @Published var height: CGFloat = 0.0

    // MARK: - Private properties

    private var loadTask: Task<Void, Error>?

    // MARK: - Public APIs

    /// Creates an empty view model. Call `load` to initialize the `EmbeddedPaymentElementViewModel`
    public init() {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: Self.self)
    }

    /// Asynchronously loads the EmbeddedPaymentElementViewModel. This function should only be called once to initially load the EmbeddedPaymentElementViewModel.
    /// Loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the confirmation.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Note: This method may only be called once. Subsequent calls will throw an error.
    /// - Throws: An error if loading failed.
    public func load(
        intentConfiguration: EmbeddedPaymentElement.IntentConfiguration,
        configuration: EmbeddedPaymentElement.Configuration
    ) async throws {
        // If we already have a load task (whether it’s in progress or finished), throw an error
        guard loadTask == nil else {
            throw ViewModelError.alreadyLoaded
        }

        // Store the load task
        loadTask = Task { [weak self] in
            let embeddedPaymentElement = try await EmbeddedPaymentElement.create(
                intentConfiguration: intentConfiguration,
                configuration: configuration
            )
            guard let self else { return }
            self.embeddedPaymentElement = embeddedPaymentElement
            self.embeddedPaymentElement?.delegate = self
            self.paymentOption = embeddedPaymentElement.paymentOption
            calculateAndPublishHeight(embeddedPaymentElement: embeddedPaymentElement) // compute initial height
            self.isLoaded = true
        }

        do {
            try await loadTask?.value
        } catch {
            // Reset loadTask to allow for load retries after errors
            loadTask = nil
            throw error
        }
    }

    /// Call this method when the IntentConfiguration values you used to initialize `EmbeddedPaymentElementViewModel` (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, collect the right fields, etc.
    /// - Parameter intentConfiguration: An updated IntentConfiguration.
    /// - Returns: The result of the update. Any calls made to `update` before this call that are still in progress will return a `.canceled` result.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    public func update(
        intentConfiguration: EmbeddedPaymentElement.IntentConfiguration
    ) async -> EmbeddedPaymentElement.UpdateResult {
        // Wait for the load task to complete if it exists
        if let loadTask = self.loadTask {
            do {
                try await loadTask.value
            } catch {
                return .failed(error: ViewModelError.notLoaded)
            }
        }

        // Check if update was called before load, if so throw an error
        guard let embeddedPaymentElement else {
            return .failed(error: ViewModelError.notLoaded)
        }

        return await embeddedPaymentElement.update(intentConfiguration: intentConfiguration)
    }

    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method requires that the last call to `update` succeeded. If the last `update` call failed, this call will fail. If this method is called while a call to `update` is in progress, it waits until the `update` call completes.
    public func confirm() async -> EmbeddedPaymentElementResult {
        guard let embeddedPaymentElement else {
            return .failed(error: ViewModelError.notLoaded)
        }

        // Hack: If Embedded has not been presented yet, we may not have a VC. If that's the case, populate it with the default VC for the window.
        if embeddedPaymentElement.presentingViewController == nil {
            embeddedPaymentElement.presentingViewController = UIWindow.visibleViewController
        }

        let result = await embeddedPaymentElement.confirm()
        return result
    }

    /// Sets the currently selected payment option to `nil`.
    public func clearPaymentOption() {
        embeddedPaymentElement?.clearPaymentOption()
    }

#if DEBUG
    public func testHeightChange() {
        embeddedPaymentElement?.testHeightChange()
    }
#endif

    private func calculateAndPublishHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        let newHeight = embeddedPaymentElement.view.systemLayoutSizeFitting(CGSize(width: embeddedPaymentElement.view.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height

        withAnimation(.easeInOut(duration: 0.2)) {
            self.height = newHeight
        }
    }
}

// MARK: EmbeddedPaymentElementDelegate

extension EmbeddedPaymentElementViewModel: EmbeddedPaymentElementDelegate {
    public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        calculateAndPublishHeight(embeddedPaymentElement: embeddedPaymentElement)
    }

    public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        self.paymentOption = embeddedPaymentElement.paymentOption
    }
}

// MARK: STPAnalyticsProtocol

@_spi(STP) extension EmbeddedPaymentElementViewModel: STPAnalyticsProtocol {
    nonisolated public static let stp_analyticsIdentifier = "EmbeddedPaymentElementViewModel"
}

/// A SwiftUI view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
@_spi(EmbeddedPaymentElementPrivateBeta) public struct EmbeddedPaymentElementView: View {
    @ObservedObject private var viewModel: EmbeddedPaymentElementViewModel

    /// Initializes a new instance of `EmbeddedPaymentElementView`.
    ///
    /// - Parameter viewModel: The view model for this payment element view.
    public init(viewModel: EmbeddedPaymentElementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        EmbeddedViewRepresentable(viewModel: viewModel)
            .frame(height: viewModel.height)
    }
}
