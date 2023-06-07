//
//  CustomerSheet.swift
//  StripePaymentSheet
//
//
//  ⚠️🏗 This is feature has not been released yet, and is under construction
//  Note: Do not import Stripe using `@_spi(STP)` or @_spi(PrivateBetaCustomerSheet) in production.
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

@_spi(PrivateBetaCustomerSheet) public class CustomerSheet {
    let configuration: CustomerSheet.Configuration

    internal typealias CustomerSheetCompletion = (CustomerSheetResult) -> Void

    /// The STPPaymentHandler instance
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    lazy var paymentHandler: STPPaymentHandler = {
        STPPaymentHandler(apiClient: configuration.apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler())
    }()

    /// The parent view controller to present
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
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
        self.configuration = configuration
        self.customerAdapter = customer
    }

    var customerAdapter: CustomerAdapter

    /// The result of the CustomerSheet
    @frozen public enum CustomerSheetResult {
        /// The customer cancelled the sheet. (e.g. by tapping outside it or tapping the "X")
        case canceled
        /// The customer selected a payment method.
        case selected(PaymentOptionSelection?)
        /// An error occurred when presenting the sheet
        case error(Error)
    }

    private var csCompletion: CustomerSheetCompletion?

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
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
            case .success((let savedPaymentMethods, let selectedPaymentMethodOption)):
                self.present(from: presentingViewController, savedPaymentMethods: savedPaymentMethods, selectedPaymentMethodOption: selectedPaymentMethodOption)
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

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    func present(from presentingViewController: UIViewController,
                 savedPaymentMethods: [STPPaymentMethod],
                 selectedPaymentMethodOption: CustomerPaymentOption?) {
        let loadSpecsPromise = Promise<Void>()
        AddressSpecProvider.shared.loadAddressSpecs {
            loadSpecsPromise.resolve(with: ())
        }

        loadSpecsPromise.observe { _ in
            DispatchQueue.main.async {
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePayEnabled
                let savedPaymentSheetVC = CustomerSavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                                                    selectedPaymentMethodOption: selectedPaymentMethodOption,
                                                                                    configuration: self.configuration,
                                                                                    customerAdapter: self.customerAdapter,
                                                                                    isApplePayEnabled: isApplePayEnabled,
                                                                                    csCompletion: self.csCompletion,
                                                                                    delegate: self)
                self.bottomSheetViewController.contentStack = [savedPaymentSheetVC]
            }
        }
    }
    // MARK: - Internal Properties
    var completion: (() -> Void)?
    var userCompletion: ((CustomerSheetResult) -> Void)?
}

extension CustomerSheet {
    func loadPaymentMethodInfo(completion: @escaping (Result<([STPPaymentMethod], CustomerPaymentOption?), Error>) -> Void) {
        Task {
            do {
                async let paymentMethodsResult = try customerAdapter.fetchPaymentMethods()
                async let selectedPaymentMethodResult = try self.customerAdapter.fetchSelectedPaymentOption()
                let (paymentMethods, selectedPaymentMethod) = try await (paymentMethodsResult, selectedPaymentMethodResult)
                completion(.success((paymentMethods, selectedPaymentMethod)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
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

@_spi(PrivateBetaCustomerSheet) extension StripeCustomerAdapter {
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
            return CustomerSheet.PaymentOptionSelection.savedPaymentMethod(matchingPaymentMethod)
        default:
            return nil
        }
    }
}
