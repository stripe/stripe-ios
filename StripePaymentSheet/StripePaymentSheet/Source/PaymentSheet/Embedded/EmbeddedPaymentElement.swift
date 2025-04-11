//
//  EmbeddedPaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
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
        /// If you set `configuration.embeddedViewDisplaysMandateText = false`, this text must be displayed in a `UITextView` (so that URLs in the text are handled) to the customer near your “Buy” button to comply with regulations.
        public let mandateText: NSAttributedString?

    }

    /// Contains information about the customer's selected payment option.
    /// Use this to display the payment option in your own UI
    public var paymentOption: PaymentOptionDisplayData? {
        guard let _paymentOption else {
            return nil
        }
        return .init(paymentOption: _paymentOption, mandateText: embeddedPaymentMethodsView.mandateText, currency: intent.currency)
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
        try validateRowSelectionConfiguration(configuration: configuration)

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
        embeddedPaymentElement.clearPaymentOptionIfNeeded()
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
        let newUpdateContext = EmbeddedUpdateContext(status: .inProgress)
        self.latestUpdateContext = newUpdateContext

        let startTime = Date()
        analyticsHelper.logEmbeddedUpdateStarted()
        // Do not process any update calls if we have already successfully confirmed an intent
        guard !hasConfirmedIntent else {
            let result: EmbeddedPaymentElement.UpdateResult = .failed(error: PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent)
            analyticsHelper.logEmbeddedUpdateFinished(result: result, duration: Date().timeIntervalSince(startTime))
            return result
        }

        // If we currently have a sheet presented fail the update
        guard !(presentingViewController?.presentedViewController is StripePaymentSheet.BottomSheetViewController) else {
            let result: EmbeddedPaymentElement.UpdateResult = .failed(error: PaymentSheetError.embeddedPaymentElementUpdateWithFormPresented)
            analyticsHelper.logEmbeddedUpdateFinished(result: result, duration: Date().timeIntervalSince(startTime))
            return result
        }

        embeddedPaymentMethodsView.isUserInteractionEnabled = false
        // Cancel the old task and let it finish so that merchants receive update results in order
        latestUpdateTask?.cancel()
        _ = await latestUpdateTask?.value
        // Start the new update task
        let currentUpdateTask: Task<UpdateResult, Never> = Task { @MainActor [weak self, configuration, analyticsHelper] in
            // ⚠️ Don't modify `self` until after all `awaits` to avoid being canceled halfway through and leaving self in a partially updated state.
            // 1. Reload v1/elements/session.
            let loadResult: PaymentSheetLoader.LoadResult
            do {
                // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-3079): Make `load` respect task cancellation to reduce network consumption
                loadResult = try await PaymentSheetLoader.load(
                    mode: .deferredIntent(intentConfiguration),
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    integrationShape: .embedded
                )
            } catch {
                return UpdateResult.failed(error: error)
            }
            guard let self, !Task.isCancelled else {
                return UpdateResult.canceled
            }

            // 2. At this point, we're still the latest update and update is successful - update self properties and inform our delegate.
            let previousPaymentOption = self._paymentOption
            self.loadResult = loadResult
            self.savedPaymentMethods = loadResult.savedPaymentMethods
            self.formCache = .init() // Clear the cache because the form may have changed e.g. different mandate or different fields.
            let isPreviousPaymentOptionStillDisplayed: Bool = {
                switch previousPaymentOption {
                case .none:
                    return true
                case .applePay:
                    return PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
                case .link:
                    return PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
                case .saved(paymentMethod: let paymentMethod, confirmParams: _):
                    return loadResult.savedPaymentMethods.contains(paymentMethod)
                case .new(confirmParams: let confirmParams):
                    return loadResult.paymentMethodTypes.contains(confirmParams.paymentMethodType)
                case .external(paymentMethod: let paymentMethod, billingDetails: _):
                    return loadResult.paymentMethodTypes.contains(.external(paymentMethod))
                }
            }()
            let previousSelectedRowType = self.embeddedPaymentMethodsView.selectedRowButton?.type
            let previousSelectedRowChangeButtonState = self.embeddedPaymentMethodsView.selectedRowChangeButtonState
            // Make the new form VC for the previously selected row type if it's still in the list
            let selectedFormViewController = Self.makeFormViewControllerIfNecessary(
                selection: isPreviousPaymentOptionStillDisplayed ? previousSelectedRowType : nil,
                previousPaymentOption: previousPaymentOption,
                configuration: self.configuration,
                intent: loadResult.intent,
                elementsSession: loadResult.elementsSession,
                savedPaymentMethods: loadResult.savedPaymentMethods,
                analyticsHelper: self.analyticsHelper,
                formCache: self.formCache,
                delegate: self
            )
            self.selectedFormViewController = selectedFormViewController
            // Make the new list view, selecting the previous row if it's still in the list and it doesn't have a form or it's form is valid
            let shouldSelectPreviousRow: Bool = {
                guard isPreviousPaymentOptionStillDisplayed else { return false }
                if let selectedFormViewController {
                    return selectedFormViewController.selectedPaymentOption != nil
                } else {
                    return true
                }
            }()
            self.embeddedPaymentMethodsView = Self.makeView(
                configuration: configuration,
                loadResult: loadResult,
                analyticsHelper: analyticsHelper,
                previousSelection: shouldSelectPreviousRow ? previousSelectedRowType : nil,
                previousSelectedRowChangeButtonState: shouldSelectPreviousRow ? previousSelectedRowChangeButtonState : nil,
                delegate: self
            )
            self.containerView.updateEmbeddedPaymentMethodsView(embeddedPaymentMethodsView)
            informDelegateIfPaymentOptionUpdated()
            return .succeeded
        }
        self.latestUpdateTask = currentUpdateTask
        let updateResult = await currentUpdateTask.value
        if latestUpdateContext?.id == newUpdateContext.id {
            switch updateResult {
            case .succeeded:
                self.latestUpdateContext?.status = .succeeded
            case .failed(let error):
                self.latestUpdateContext?.status = .failed(error: error)
            case .canceled:
                self.latestUpdateContext?.status = .canceled
            }
        }
        if case .succeeded = updateResult {
            clearPaymentOptionIfNeeded()
        }
        embeddedPaymentMethodsView.isUserInteractionEnabled = true
        analyticsHelper.logEmbeddedUpdateFinished(result: updateResult, duration: Date().timeIntervalSince(startTime))
        return updateResult
    }

    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method presents authentication screens on the instance's  `presentingViewController` property.
    /// - Note: This method requires that the last call to `update` succeeded. If the last `update` call failed, this call will fail. If this method is called while a call to `update` is in progress, it waits until the `update` call completes.
    public func confirm() async -> EmbeddedPaymentElementResult {
        analyticsHelper.log(event: .mcConfirmEmbedded)
        guard let presentingViewController else {
            let errorMessage = "Presenting view controller is nil. Please set EmbeddedPaymentElement.presentingViewController."
            assertionFailure(errorMessage)
            return .failed(error: PaymentSheetError.integrationError(nonPIIDebugDescription: errorMessage))
        }
        guard let paymentOption = _paymentOption else {
            assertionFailure("`confirm` should only be called when `paymentOption` is not nil")
            return .failed(error: PaymentSheetError.confirmingWithInvalidPaymentOption)
        }
        let authContext = STPAuthenticationContextWrapper(presentingViewController: presentingViewController, appearance: configuration.appearance)
        let confirmResult = await _confirm(paymentOption: paymentOption, authContext: authContext).result
        if confirmResult.isCanceledOrFailed {
            clearPaymentOptionIfNeeded()
        }
        return confirmResult
    }

    /// Sets the currently selected payment option to `nil`.
    public func clearPaymentOption() {
        // If a payment has been successfully completed, we don't allow clearing the payment option.
        guard !hasConfirmedIntent else { return }

        // Early exit for a nil payment option, don't notify delegate since no change in payment option can occur
        guard paymentOption != nil else { return }

        // Clear out the form controller to clear any payment option
        selectedFormViewController = nil

        // Reset the selection on the `embeddedPaymentMethodsView`
        embeddedPaymentMethodsView.resetSelection()

#if DEBUG
        // Clear the testable payment option (only populated during unit testing)
        _test_paymentOption = nil
#endif

        // Notify the delegate that the payment option has changed
        informDelegateIfPaymentOptionUpdated()
    }

    #if DEBUG
    public func testHeightChange() {
        assert(configuration.embeddedViewDisplaysMandateText, "Before using this testing feature, ensure that embeddedViewDisplaysMandateText is set to true")
        self.embeddedPaymentMethodsView.testHeightChange()
    }
    #endif
    // MARK: - Internal

    internal private(set) lazy var containerView: EmbeddedPaymentElementContainerView = {
        return EmbeddedPaymentElementContainerView(
            embeddedPaymentMethodsView: embeddedPaymentMethodsView
        )
    }()
    internal private(set) lazy var embeddedPaymentMethodsView: EmbeddedPaymentMethodsView = {
       return Self.makeView(
        configuration: configuration,
        loadResult: loadResult,
        analyticsHelper: analyticsHelper,
        delegate: self
       )
    }()
    internal var loadResult: PaymentSheetLoader.LoadResult
    internal var elementsSession: STPElementsSession { loadResult.elementsSession }
    internal var intent: Intent { loadResult.intent }
    internal var savedPaymentMethods: [STPPaymentMethod]
    internal var defaultPaymentMethod: STPPaymentMethod?
    internal private(set) var latestUpdateTask: Task<UpdateResult, Never>?
    internal private(set) var analyticsHelper: PaymentSheetAnalyticsHelper
    internal private(set) var formCache: PaymentMethodFormCache = .init()
    /// The form view controller for the currently selected payment method.
    internal var selectedFormViewController: EmbeddedFormViewController?
    /// Indicates if a payment has been successfully completed.
    internal var hasConfirmedIntent = false
    /// Tracks info about the currently in-flight or most recent update attempt.
    internal var latestUpdateContext: EmbeddedUpdateContext?
#if DEBUG
    internal var _test_paymentOption: PaymentOption? // for testing only
#endif

    /// The value of `paymentOption` when we last called `embeddedPaymentElementDidUpdatePaymentOption`
    internal var lastUpdatedPaymentOption: PaymentOptionDisplayData?
    internal var _paymentOption: PaymentOption? {
    #if DEBUG
        if let testPaymentOption = _test_paymentOption {
            return testPaymentOption
        }
    #endif
        // If we have a form use it's payment option
        if let selectedFormViewController {
            return selectedFormViewController.selectedPaymentOption
        }

        switch embeddedPaymentMethodsView.selectedRowButton?.type {
        case .applePay:
            return .applePay
        case .link:
            return .link(option: .wallet)
        case let .new(paymentMethodType: paymentMethodType):
            let params = IntentConfirmParams(type: paymentMethodType)
            params.setDefaultBillingDetailsIfNecessary(for: configuration)
            switch paymentMethodType {
            case .stripe:
                return .new(confirmParams: params)
            case .external(let type):
                return .external(paymentMethod: type, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
            case .instantDebits, .linkCardBrand:
                guard let paymentMethod = params.instantDebitsLinkedBank?.paymentMethod.decode() else {
                    return nil
                }
                return .saved(paymentMethod: paymentMethod, confirmParams: params)
            }
        case .saved(paymentMethod: let paymentMethod):
            return .saved(paymentMethod: paymentMethod, confirmParams: nil)
        case .none:
            return nil
        }
    }
    internal private(set) lazy var savedPaymentMethodManager: SavedPaymentMethodManager = {
        SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession)
    }()

    internal private(set) lazy var paymentHandler: STPPaymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)

    internal init(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.configuration = configuration
        self.loadResult = loadResult
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.defaultPaymentMethod = loadResult.elementsSession.customer?.getDefaultPaymentMethod()
        self.analyticsHelper = analyticsHelper

        analyticsHelper.logInitialized()
        self.containerView.needsUpdateSuperviewHeight = { [weak self] in
            guard let self else { return }
            self.delegate?.embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: self)
        }
        self.lastUpdatedPaymentOption = paymentOption
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
    /// - Note: This method requires that the last call to `update` succeeded. If the last `update` call failed, this call will fail. If this method is called while a call to `update` is in progress, it waits until the `update` call completes.
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
    public typealias LinkConfiguration = PaymentSheet.LinkConfiguration
    public typealias CustomerConfiguration = PaymentSheet.CustomerConfiguration
    public typealias BillingDetails = PaymentSheet.BillingDetails
    public typealias Address = PaymentSheet.Address
    public typealias BillingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration
    public typealias ExternalPaymentMethodConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration
    public typealias CustomPaymentMethodConfiguration = PaymentSheet.CustomPaymentMethodConfiguration
}

// MARK: - EmbeddedPaymentElement.PaymentOptionDisplayData

extension EmbeddedPaymentElement.PaymentOptionDisplayData {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // Unfortunately, we need to manually define this because the implementation of Equatable on UIImage does not work
        return lhs.image.pngData() == rhs.image.pngData() && rhs.label == lhs.label && lhs.billingDetails == rhs.billingDetails && lhs.paymentMethodType == rhs.paymentMethodType && lhs.mandateText == rhs.mandateText
    }
}
