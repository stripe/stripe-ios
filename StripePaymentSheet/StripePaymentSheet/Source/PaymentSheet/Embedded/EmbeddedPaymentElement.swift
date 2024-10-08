//
//  EmbeddedPaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// An object that manages a view that displays payment methods and completes a checkout.
@_spi(EmbeddedPaymentElementPrivateBeta)
public class EmbeddedPaymentElement {

    /// A view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
    public let view: UIView

    /// A view controller to present on.
    public var presentingViewController: UIViewController?

    /// This contains the `configuration` you passed in to `create`.
    public let configuration: Configuration

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
        public let mandateText: NSAttributedString?
    }

    /// The customer's currently selected payment option.
    public var paymentOption: PaymentOptionDisplayData? {
        return (view as? EmbeddedPaymentMethodsView)?.displayData
    }
    
    private let loadResult: PaymentSheetLoader.LoadResult
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private var embeddedFormViewController: EmbeddedFormViewController?
    private var bottomSheetController: BottomSheetViewController?
    
    /// An asynchronous failable initializer
    /// This loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the checkout.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Returns: A valid EmbeddedPaymentElement instance
    /// - Throws: An error if loading failed.
    ///
    /// 
    public static func create(
        intentConfiguration: IntentConfiguration,
        configuration: Configuration
    ) async throws -> EmbeddedPaymentElement {
        // TODO(porter) Should we create a new analytics helper specific to embedded? Figured this out when we do analytics.
        let analyticsHelper = PaymentSheetAnalyticsHelper(isCustom: true, configuration: PaymentSheet.Configuration())
        AnalyticsHelper.shared.generateSessionID()

        let loadResult = try await PaymentSheetLoader.load(mode: .deferredIntent(intentConfiguration),
                                                           configuration: configuration,
                                                           analyticsHelper: analyticsHelper,
                                                           integrationShape: .embedded)

        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: .deferredIntent(intentConfig: intentConfiguration),
                                                                                           elementsSession: loadResult.elementsSession,
                                                                                           configuration: configuration,
                                                                                           logAvailability: true)
        let shouldShowApplePay = PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let shouldShowLink = PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let savedPaymentMethodAccessoryType = await RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: loadResult.savedPaymentMethods.count,
            isFirstCardCoBranded: loadResult.savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )

        let initialSelection: EmbeddedPaymentMethodsView.Selection? = {
            // Default to the customer's default or the first saved payment method, if any
            let customerDefault = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customer?.id)
            switch customerDefault {
            case .applePay:
                return .applePay
            case .link:
                return .link
            case .stripeId, nil:
                return loadResult.savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
            }
        }()

        let embeddedPaymentMethodsView = await EmbeddedPaymentMethodsView(
            initialSelection: initialSelection,
            paymentMethodTypes: paymentMethodTypes,
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            appearance: configuration.appearance,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            mandateProvider: FormMandateProvider(configuration: configuration,
                                             elementsSession: loadResult.elementsSession,
                                             intent: .deferredIntent(intentConfig: intentConfiguration))
        )

        let embeddedPaymentElement: EmbeddedPaymentElement = .init(view: embeddedPaymentMethodsView, configuration: configuration, loadResult: loadResult, analyticsHelper: analyticsHelper)
        await MainActor.run {
            embeddedPaymentMethodsView.delegate = embeddedPaymentElement
        }

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
    /// - Returns: The result of the update. Any calls made to `update` before this call that are still in progress will return a `.canceled` result.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    public func update(
        intentConfiguration: IntentConfiguration
    ) async -> UpdateResult {
        // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-2524)
        return .succeeded
    }
    
    private lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient) }()

    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method presents authentication screens on the instance's  `presentingViewController` property.
    @MainActor public func confirm() async -> EmbeddedPaymentElementResult {
        guard let authContext: STPAuthenticationContext = bottomSheetController ?? presentingViewController else { return .canceled }
        
        let result = await PaymentSheet.confirm(configuration: self.configuration, authenticationContext: authContext, intent: loadResult.intent, elementsSession: loadResult.elementsSession, paymentOption: _paymentOption, paymentHandler: self.paymentHandler, isFlowController: false)
        return result.0
        
        
        
        
        
//        switch result.0 {
//        case .completed:
//            self.bottomSheetController?.transitionSpinnerToComplete(animated: true) {
////                self.embeddedFormViewController?.dismiss(animated: true)
//                print("Transitions")
//            }
//            break
//        case .canceled:
//            break
//        case .failed(error: let error):
//            print(error)
//            break
//        }
        
//        let confirm: (@escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) -> Void = { completion in
//            PaymentSheet.confirm(
//                configuration: self.configuration,
//                authenticationContext: self.bottomSheetViewController,
//                intent: loadResult.intent,
//                elementsSession: loadResult.elementsSession,
//                paymentOption: paymentOption,
//                paymentHandler: self.paymentHandler,
//                isFlowController: false
//            ) { result, deferredIntentConfirmationType in
//                if case let .failed(error) = result {
//                    self.mostRecentError = error
//                }
//
//                if case .link = paymentOption {
//                    // End special Link blur animation before calling completion
//                    switch result {
//                    case .canceled, .failed:
//                        self.bottomSheetViewController.removeBlurEffect(animated: true) {
//                            completion(result, deferredIntentConfirmationType)
//                        }
//                    case .completed:
//                        self.bottomSheetViewController.transitionSpinnerToComplete(animated: true) {
//                            completion(result, deferredIntentConfirmationType)
//                        }
//                    }
//                } else {
//                    completion(result, deferredIntentConfirmationType)
//                }
//            }
//        }
//
//        if case .applePay = paymentOption {
//            // Don't present the Apple Pay sheet on top of the Payment Sheet
//            embeddedFormViewController.dismiss(animated: true) {
//                confirm { result, deferredIntentConfirmationType in
//                    if case .completed = result {
//                    } else {
//                        // We dismissed the Payment Sheet to show the Apple Pay sheet
//                        // Bring it back if it didn't succeed
//                        presentingViewController?.presentAsBottomSheet(self.bottomSheetViewController,
//                                                                  appearance: self.configuration.appearance)
//                    }
//                    completion(result, deferredIntentConfirmationType)
//                }
//            }
//        } else {
//            confirm(completion)
//        }
//        
//        return .canceled
    }

    // MARK: - Internal

    private init(view: UIView, configuration: Configuration, loadResult: PaymentSheetLoader.LoadResult, analyticsHelper: PaymentSheetAnalyticsHelper, delegate: EmbeddedPaymentElementDelegate? = nil) {
        self.view = view
        self.delegate = delegate
        self.configuration = configuration
        self.loadResult = loadResult
        self.analyticsHelper = analyticsHelper
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
    
    var _paymentOption: PaymentOption {
        if let selectedPaymentOption = embeddedFormViewController?.selectedPaymentOption {
            return selectedPaymentOption
        }
        
        guard let embeddedView = view as? EmbeddedPaymentMethodsView else {
            return .applePay // todo
        }
        
        switch embeddedView.selection {
        case nil:
            return .applePay//todo
        case .applePay:
            return .applePay
        case .link:
            return .link(option: .wallet)
        case .new(paymentMethodType: let paymentMethodType):
            let params = IntentConfirmParams(type: paymentMethodType)
            params.setDefaultBillingDetailsIfNecessary(for: configuration)
            switch paymentMethodType {
            case .stripe:
                return .new(confirmParams: params)
            case .external(let type):
                return .external(paymentMethod: type, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
            case .instantDebits, .linkCardBrand:
                return .new(confirmParams: params)
            }
        case .saved(paymentMethod: let paymentMethod):
            return .saved(paymentMethod: paymentMethod, confirmParams: nil)
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

extension EmbeddedPaymentElement: EmbeddedPaymentMethodsViewDelegate {
    func heightDidChange() {
        delegate?.embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: self)
    }
    
    func selectionDidUpdate() {
        delegate?.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: self)
        
        guard let embeddedView = view as? EmbeddedPaymentMethodsView, let selection = embeddedView.selection else { return }
        let paymentMethodType: PaymentSheet.PaymentMethodType? = {
            switch selection {
            case .new(paymentMethodType: let paymentMethodType):
                return paymentMethodType
            case .saved:
                return nil
            case .applePay:
                return nil
            case .link:
                return nil
            }
        }()
        guard let paymentMethodType else { return }
        
        guard let presentingViewController else {
            stpAssert(true, "Provide a presenting view controller, TODO better message")
            return
        }
        embeddedFormViewController = EmbeddedFormViewController(configuration: configuration,
                                            loadResult: loadResult,
                                            isFlowController: false,
                                            paymentMethodType: paymentMethodType,
                                            analyticsHelper: analyticsHelper)
        guard let embeddedFormViewController else { return }
        embeddedFormViewController.paymentSheetDelegate = self
        embeddedFormViewController.flowControllerDelegate = self
        
        guard embeddedFormViewController.collectsUserInput else { return }
        bottomSheetController = BottomSheetViewController(contentViewController: embeddedFormViewController, appearance: configuration.appearance, isTestMode: true, didCancelNative3DS2: {})
        
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        presentingViewController.presentAsBottomSheet(bottomSheetController!, appearance: configuration.appearance)
    }
}

extension EmbeddedPaymentElement: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: PaymentSheetViewControllerProtocol, with paymentOption: PaymentOption, completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
        confirm { result in
            completion(result, .client)
        }
    }
    
    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: PaymentSheetViewControllerProtocol, result: PaymentSheetResult) {
        switch result {
        case .completed:
            paymentSheetViewController.dismiss(animated: true) {
                switch self.configuration.formSheetAction {
                case .confirm(let completion):
                    completion(result)
                case .continue:
                    break
                }
            }
        case .canceled:
            break
        case .failed:
            break
        }
    }
    
    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: PaymentSheetViewControllerProtocol) {
        paymentSheetViewController.dismiss(animated: true) {
            // TODO?
        }
    }
    
    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: PaymentSheetViewControllerProtocol) {
        // no-op
    }
    
    
}

extension EmbeddedPaymentElement: FlowControllerViewControllerDelegate {
    func flowControllerViewControllerShouldClose(_ PaymentSheetFlowControllerViewController: FlowControllerViewControllerProtocol, didCancel: Bool) {
        PaymentSheetFlowControllerViewController.dismiss(animated: true) {
            // TODO?
        }
    }
}

extension UIViewController: STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
    
}
