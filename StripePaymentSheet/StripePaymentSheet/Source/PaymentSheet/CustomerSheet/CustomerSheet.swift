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
    let configuration: CustomerSheet.Configuration

    internal typealias CustomerSheetCompletion = (CustomerSheetResult) -> Void

    /// The STPPaymentHandler instance
    lazy var paymentHandler: STPPaymentHandler = {
        STPPaymentHandler(apiClient: configuration.apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler())
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

    ///
    /// Use a StripeCustomerAdapter, or build your own.
    public init(configuration: CustomerSheet.Configuration,
                customer: CustomerAdapter) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: CustomerSheet.self)
        self.configuration = configuration
        self.customerAdapter = customer
    }

    var customerAdapter: CustomerAdapter

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
        // Retain self when being presented, it is not guaranteed that CustomerSheet instance
        // will be retained by caller
        let completion: () -> Void = {
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true)
            }
            self.bottomSheetViewController.contentStack = [self.loadingViewController]
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
        loadPaymentMethodInfo { result in
            switch result {
            case .success((let savedPaymentMethods, let selectedPaymentMethodOption, let elementsSession)):
                let merchantSupportedPaymentMethodTypes = self.customerAdapter.canCreateSetupIntents ? elementsSession.orderedPaymentMethodTypes : [.card]
                self.present(from: presentingViewController,
                             savedPaymentMethods: savedPaymentMethods,
                             selectedPaymentMethodOption: selectedPaymentMethodOption,
                             merchantSupportedPaymentMethodTypes: merchantSupportedPaymentMethodTypes,
                             cbcEligible: elementsSession.cardBrandChoice?.eligible ?? false)
            case .failure(let error):
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
                 cbcEligible: Bool) {
        let loadSpecsPromise = Promise<Void>()
        AddressSpecProvider.shared.loadAddressSpecs {
            loadSpecsPromise.resolve(with: ())
        }

        loadSpecsPromise.observe { _ in
            DispatchQueue.main.async {
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePayEnabled
                let savedPaymentSheetVC = CustomerSavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                                                    selectedPaymentMethodOption: selectedPaymentMethodOption,
                                                                                    merchantSupportedPaymentMethodTypes: merchantSupportedPaymentMethodTypes,
                                                                                    configuration: self.configuration,
                                                                                    customerAdapter: self.customerAdapter,
                                                                                    isApplePayEnabled: isApplePayEnabled,
                                                                                    cbcEligible: cbcEligible,
                                                                                    csCompletion: self.csCompletion,
                                                                                    delegate: self)
                self.bottomSheetViewController.contentStack = [savedPaymentSheetVC]
            }
        }
    }
    // MARK: - Internal Properties
    var completion: (() -> Void)?
    var userCompletion: ((Result<PaymentOptionSelection?, Error>) -> Void)?
}

extension CustomerSheet {
    func loadPaymentMethodInfo(completion: @escaping (Result<([STPPaymentMethod], CustomerPaymentOption?, STPElementsSession), Error>) -> Void) {
        Task {
            do {
                async let paymentMethodsResult = try customerAdapter.fetchPaymentMethods()
                async let selectedPaymentMethodResult = try self.customerAdapter.fetchSelectedPaymentOption()
                async let elementsSessionResult = try self.configuration.apiClient.retrieveElementsSessionForCustomerSheet()

                // Ensure local specs are loaded prior to the ones from elementSession
                await loadFormSpecs()

                let (paymentMethods, selectedPaymentMethod, elementSession) = try await (paymentMethodsResult, selectedPaymentMethodResult, elementsSessionResult)

                // Override with specs from elementSession
                _ = FormSpecProvider.shared.loadFrom(elementSession.paymentMethodSpecs as Any)

                completion(.success((paymentMethods, selectedPaymentMethod, elementSession)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func loadFormSpecs() async {
        await withCheckedContinuation { continuation in
            Task {
                FormSpecProvider.shared.load { _ in
                    continuation.resume()
                }
            }
        }
    }
}

extension CustomerSheet: CustomerSavedPaymentMethodsViewControllerDelegate {
    func savedPaymentMethodsViewControllerShouldConfirm(_ intent: Intent?, with paymentOption: PaymentOption, completion: @escaping (InternalCustomerSheetResult) -> Void) {
        guard let intent = intent,
              case .setupIntent = intent else {
            assertionFailure("Setup intent not available")
            completion(.failed(error: CustomerSheetError.unknown(debugDescription: "No setup intent available")))
            return
        }
        self.confirmIntent(intent: intent, paymentOption: paymentOption) { result in
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
