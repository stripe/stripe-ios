//
//  CustomerSheet.swift
//  StripePaymentSheet
//
//
//  ⚠️🏗 This is feature has not been released yet, and is under construction
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  Doing so exposes internal functionality which may cause unexpected behavior if used directly.
//
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

// For internal use
internal enum InternalCustomerSheetResult {
    case completed(NSObject?)
    case canceled
    case failed(error: Error)
}

public class CustomerSheet {
    private enum IntegrationType {
        case customerAdapter
        case customerSession
    }

    internal enum InternalError: Error {
        case expectedSetupIntent
        case invalidStateOnConfirmation
    }
    private let integrationType: IntegrationType
    let configuration: CustomerSheet.Configuration

    internal typealias CustomerSheetCompletion = (CustomerSheetResult) -> Void

    private var initEvent: STPAnalyticEvent {
        switch self.integrationType {
        case .customerAdapter:
            STPAnalyticEvent.customerSheetInitWithCustomerAdapter
        case .customerSession:
            STPAnalyticEvent.customerSheetInitWithCustomerSession
        }
    }

    /// The STPPaymentHandler instance
    lazy var paymentHandler: STPPaymentHandler = {
        STPPaymentHandler(apiClient: configuration.apiClient)
    }()

    /// The parent view controller to present
    lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = configuration.apiClient.isTestmode
        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            didCancelNative3DS2: { [weak self] in
                self?.paymentHandler.cancel3DS2ChallengeFlow()
            }
        )

        configuration.style.configure(vc)
        return vc
    }()

    lazy var loadingViewController: LoadingViewController = {
        let isTestMode = configuration.apiClient.isTestmode
        return LoadingViewController(
            delegate: self,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            loadingViewHeight: 180
        )
    }()

    /// Use a StripeCustomerAdapter, or build your own.
    public init(configuration: CustomerSheet.Configuration,
                customer: CustomerAdapter) {
        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: CustomerSheet.self)
        self.integrationType = .customerAdapter
        self.configuration = configuration

        self.customerAdapter = customer
        self.customerSessionClientSecretProvider = nil
        self.customerSheetIntentConfiguration = nil
    }

    /// - Parameter configuration: Configuration for CustomerSheet. E.g. your business name,
    ///   appearance api, billing details collection, etc.
    /// - Parameter intentConfiguration: Information about the setup intent used when saving
    ///   a new payment method
    /// - Parameter customerSessionClientSecretProvider: A callback that returns a newly created
    ///   instance of CustomerSessionClientSecret
    @_spi(CustomerSessionBetaAccess)
    public init(configuration: CustomerSheet.Configuration,
                intentConfiguration: CustomerSheet.IntentConfiguration,
                customerSessionClientSecretProvider: @escaping () async throws -> CustomerSessionClientSecret) {
        self.integrationType = .customerSession
        self.configuration = configuration
        self.customerAdapter = nil
        self.customerSessionClientSecretProvider = customerSessionClientSecretProvider
        self.customerSheetIntentConfiguration = intentConfiguration
    }

    let customerSessionClientSecretProvider: (() async throws -> CustomerSessionClientSecret)?
    let customerSheetIntentConfiguration: CustomerSheet.IntentConfiguration?
    let customerAdapter: CustomerAdapter?

    private var csCompletion: CustomerSheetCompletion?

    /// The result of the CustomerSheet
    @frozen public enum CustomerSheetResult {
        /// The customer cancelled the sheet. (e.g. by tapping outside it or tapping the "X")
        /// The associated value is the original payment method, before the sheet was opened, as long
        /// that payment method is still available.
        case canceled(PaymentOptionSelection?)

        /// The customer selected a payment method. The associated value is the selected payment method.
        case selected(PaymentOptionSelection?)

        /// An error occurred when presenting the sheet
        case error(Error)
    }

    public func present(from presentingViewController: UIViewController,
                        completion csCompletion: @escaping (CustomerSheetResult) -> Void
    ) {
        let loadingStartDate = Date()
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.initEvent)
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .customerSheetLoadStarted)
        // Retain self when being presented, it is not guaranteed that CustomerSheet instance
        // will be retained by caller
        let completion: () -> Void = {
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true)
            }
            self.bottomSheetViewController.setViewControllers([self.loadingViewController])
            self.completion = nil
        }
        self.completion = completion
        self.csCompletion = csCompletion

        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = CustomerSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            csCompletion(.error(error))
            return
        }
        guard let customerSheetDataSource = createCustomerSheetDataSource() else {
            let error = CustomerSheetError.unknown(
                debugDescription: "Unable to determine configuration"
            )
            csCompletion(.error(error))
            return
        }

        customerSheetDataSource.loadPaymentMethodInfo { result in
            switch result {
            case .success((let savedPaymentMethods, let selectedPaymentMethodOption, let elementsSession)):
                let merchantSupportedPaymentMethodTypes = customerSheetDataSource.merchantSupportedPaymentMethodTypes(elementsSession: elementsSession)
                let paymentMethodRemove = customerSheetDataSource.paymentMethodRemove(elementsSession: elementsSession)
                let paymentMethodUpdate = customerSheetDataSource.paymentMethodUpdate(elementsSession: elementsSession)
                let paymentMethodSyncDefault = customerSheetDataSource.paymentMethodSyncDefault(elementsSession: elementsSession)
                let allowsRemovalOfLastSavedPaymentMethod = CustomerSheet.allowsRemovalOfLastPaymentMethod(elementsSession: elementsSession, configuration: self.configuration)
                self.present(from: presentingViewController,
                             savedPaymentMethods: savedPaymentMethods,
                             selectedPaymentMethodOption: selectedPaymentMethodOption,
                             merchantSupportedPaymentMethodTypes: merchantSupportedPaymentMethodTypes,
                             customerSheetDataSource: customerSheetDataSource,
                             paymentMethodRemove: paymentMethodRemove,
                             paymentMethodUpdate: paymentMethodUpdate,
                             paymentMethodSyncDefault: paymentMethodSyncDefault,
                             allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                             cbcEligible: elementsSession.cardBrandChoice?.eligible ?? false)
                var params: [String: Any] = [:]
                if elementsSession.customer?.customerSession != nil {
                    params["sync_default_enabled"] = paymentMethodSyncDefault
                    if paymentMethodSyncDefault {
                        params["has_default_payment_method"] = elementsSession.customer?.defaultPaymentMethod != nil
                    }
                }
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .customerSheetLoadSucceeded,
                                                                     duration: Date().timeIntervalSince(loadingStartDate),
                                                                     params: params)
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .customerSheetLoadFailed,
                                                                     duration: Date().timeIntervalSince(loadingStartDate),
                                                                     error: error)
                csCompletion(.error(CustomerSheetError.errorFetchingSavedPaymentMethods(error)))
                DispatchQueue.main.async {
                    self.bottomSheetViewController.dismiss(animated: true)
                }
            }
        }
        presentingViewController.presentAsBottomSheet(bottomSheetViewController,
                                                      appearance: configuration.appearance)
    }

    func present(from presentingViewController: UIViewController,
                 savedPaymentMethods: [STPPaymentMethod],
                 selectedPaymentMethodOption: CustomerPaymentOption?,
                 merchantSupportedPaymentMethodTypes: [STPPaymentMethodType],
                 customerSheetDataSource: CustomerSheetDataSource,
                 paymentMethodRemove: Bool,
                 paymentMethodUpdate: Bool,
                 paymentMethodSyncDefault: Bool,
                 allowsRemovalOfLastSavedPaymentMethod: Bool,
                 cbcEligible: Bool) {
        let loadSpecsPromise = Promise<Void>()
        AddressSpecProvider.shared.loadAddressSpecs {
            loadSpecsPromise.resolve(with: ())
        }

        loadSpecsPromise.observe(on: .main) { _ in
            let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePayEnabled
            let savedPaymentSheetVC = CustomerSavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                                                selectedPaymentMethodOption: selectedPaymentMethodOption,
                                                                                merchantSupportedPaymentMethodTypes: merchantSupportedPaymentMethodTypes,
                                                                                configuration: self.configuration,
                                                                                customerSheetDataSource: customerSheetDataSource,
                                                                                isApplePayEnabled: isApplePayEnabled,
                                                                                paymentMethodRemove: paymentMethodRemove,
                                                                                paymentMethodUpdate: paymentMethodUpdate,
                                                                                paymentMethodSyncDefault: paymentMethodSyncDefault,
                                                                                allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                cbcEligible: cbcEligible,
                                                                                csCompletion: self.csCompletion,
                                                                                delegate: self)
            self.bottomSheetViewController.setViewControllers([savedPaymentSheetVC])
        }
    }

    func createCustomerSheetDataSource() -> CustomerSheetDataSource? {
        if let customerAdapater = self.customerAdapter {
            return CustomerSheetDataSource(customerAdapater, configuration: configuration)
        } else if let customerSessionClientSecretProvider = self.customerSessionClientSecretProvider,
                  let intentConfiguration = self.customerSheetIntentConfiguration {
            let customerSessionAdapter = CustomerSessionAdapter(customerSessionClientSecretProvider: customerSessionClientSecretProvider,
                                                                intentConfiguration: intentConfiguration,
                                                                configuration: configuration)
            return CustomerSheetDataSource(customerSessionAdapter)
        }
        return nil
    }

    // MARK: - Internal Properties
    var completion: (() -> Void)?
    var userCompletion: ((Result<PaymentOptionSelection?, Error>) -> Void)?
}

extension CustomerSheet {
    static func allowsRemovalOfLastPaymentMethod(elementsSession: STPElementsSession, configuration: CustomerSheet.Configuration) -> Bool {
        if !configuration.allowsRemovalOfLastSavedPaymentMethod {
            // Merchant has set local configuration to false, so honor it.
            return false
        } else {
            // Merchant is using client side default, so defer to CustomerSession's value
            return elementsSession.paymentMethodRemoveLastForCustomerSheet
        }
    }
}

extension CustomerSheet: CustomerSavedPaymentMethodsViewControllerDelegate {
    func savedPaymentMethodsViewControllerShouldConfirm(_ intent: Intent, elementsSession: STPElementsSession, with paymentOption: PaymentOption, completion: @escaping (InternalCustomerSheetResult) -> Void) {
        guard case .setupIntent = intent else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedCustomerSheetError,
                                              error: InternalError.expectedSetupIntent)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Setup intent not available")
            completion(.failed(error: CustomerSheetError.unknown(debugDescription: "No setup intent available")))
            return
        }
        self.confirmIntent(intent: intent, elementsSession: elementsSession, paymentOption: paymentOption) { result in
            completion(result)
        }
    }

    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: CustomerSavedPaymentMethodsViewController, completion _completion: @escaping () -> Void) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            _completion()
            self.completion?()
        }
    }

    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: CustomerSavedPaymentMethodsViewController, completion _completion: @escaping () -> Void) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            _completion()
            self.completion?()
        }
    }
}

extension CustomerSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}

@_spi(STP) extension CustomerSheet: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "CustomerSheet"
}

extension StripeCustomerAdapter {
    /// Returns the selected Payment Option for this customer adapter.
    /// You can use this to obtain the selected payment method without loading the CustomerSheet.
    public func retrievePaymentOptionSelection() async throws -> CustomerSheet.PaymentOptionSelection?
    {
        let selectedPaymentOption = try await self.fetchSelectedPaymentOption()
        switch selectedPaymentOption {
        case .applePay:
            return .applePay()
        case .stripeId(let paymentMethodId):
            let paymentMethods = try await self.fetchPaymentMethods()
            guard let matchingPaymentMethod = paymentMethods.first(where: { $0.stripeId == paymentMethodId }) else {
                return nil
            }
            return CustomerSheet.PaymentOptionSelection.paymentMethod(matchingPaymentMethod)
        default:
            return nil
        }
    }
}
extension CustomerSheet {
    /// Returns the selected Payment Option
    /// You can use this to obtain the selected payment method
    /// Calling this method causes CustomerSheet to load and throws an error if loading fails.
    @_spi(CustomerSessionBetaAccess)
    public func retrievePaymentOptionSelection() async throws -> CustomerSheet.PaymentOptionSelection? {
        guard let customerSheetDataSource = createCustomerSheetDataSource() else {
            return nil
        }
        switch customerSheetDataSource.dataSource {
        case .customerSession(let customerSessionAdapter):
            let (elementsSession, customerSessionClientSecret) = try await customerSessionAdapter.elementsSessionWithCustomerSessionClientSecret()

            let selectedPaymentOption = CustomerPaymentOption.selectedPaymentMethod(for: customerSessionClientSecret.customerId, elementsSession: elementsSession, surface: .customerSheet)

            switch selectedPaymentOption {
            case .applePay:
                return .applePay()
            case .stripeId(let paymentMethodId):
                let paymentMethods = elementsSession.customer?.paymentMethods.filter({ paymentMethod in
                    guard let card = paymentMethod.card else { return true }
                    return configuration.cardBrandFilter.isAccepted(cardBrand: card.preferredDisplayBrand)
                }) ?? []
                guard let matchingPaymentMethod = paymentMethods.first(where: { $0.stripeId == paymentMethodId }) else {
                    return nil
                }
                return CustomerSheet.PaymentOptionSelection.paymentMethod(matchingPaymentMethod)
            default:
                return nil
            }
        case .customerAdapter(let customerAdapter):
            let selectedPaymentOption = try await customerAdapter.fetchSelectedPaymentOption()
            switch selectedPaymentOption {
            case .applePay:
                return .applePay()
            case .stripeId(let paymentMethodId):
                let paymentMethods = try await customerAdapter.fetchPaymentMethods()
                guard let matchingPaymentMethod = paymentMethods.first(where: { $0.stripeId == paymentMethodId }) else {
                    return nil
                }
                return CustomerSheet.PaymentOptionSelection.paymentMethod(matchingPaymentMethod)
            default:
                return nil
            }
        }
    }
}

public extension CustomerSheet {
    @_spi(CustomerSessionBetaAccess)
    struct IntentConfiguration {
        internal var paymentMethodTypes: [String]?
        internal let setupIntentClientSecretProvider: () async throws -> String

        /// - Parameter paymentMethodTypes: A list of payment method types to display to the customers
        ///             Valid values include: "card", "us_bank_account", "sepa_debit"
        ///             If nil or empty, the SDK will dynamically determine the payment methods using your
        ///             Stripe Dashboard settings.
        /// - Parameter setupIntentClientSecretProvider: Creates a SetupIntent configured to attach a new
        ///             payment method to a customer. Returns the client secret for the created SetupIntent.
        ///             This will be used to confirm a new payment method.
        public init(paymentMethodTypes: [String]? = nil,
                    setupIntentClientSecretProvider: @escaping (() async throws -> String)) {
            self.paymentMethodTypes = paymentMethodTypes
            self.setupIntentClientSecretProvider = setupIntentClientSecretProvider
        }
    }
}

@_spi(CustomerSessionBetaAccess)
public struct CustomerSessionClientSecret {
    /// The identifier of the Stripe Customer object.
    /// See https://stripe.com/docs/api/customers/object#customer_object-id
    internal let customerId: String

    /// Customer session client secret
    /// See: https://docs.corp.stripe.com/api/customer_sessions/object
    internal let clientSecret: String

    public init(customerId: String, clientSecret: String) {
        self.customerId = customerId
        self.clientSecret = clientSecret

        stpAssert(!clientSecret.hasPrefix("ek_"),
                  "Argument looks like an Ephemeral Key secret, but expecting a CustomerSession client secret. See CustomerSession API: https://docs.stripe.com/api/customer_sessions/create")
        stpAssert(clientSecret.hasPrefix("cuss_"),
                  "Argument does not look like a CustomerSession client secret. See CustomerSession API: https://docs.stripe.com/api/customer_sessions/create")
    }
}
