//
//  SavedPaymentMethodsSheet.swift
//  StripePaymentSheet
//
//
//  ⚠️🏗 This is feature has not been released yet, and is under construction
//  Note: Do not import Stripe using `@_spi(STP)` or @_spi(PrivateBetaSavedPaymentMethodsSheet) in production.
//  Doing so exposes internal functionality which may cause unexpected behavior if used directly.
//
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) @_spi(PrivateBetaSavedPaymentMethodsSheet) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

enum SavedPaymentMethodsSheetResult {
    case completed(NSObject?)
    case canceled
    case failed(error: Error)
}

@_spi(PrivateBetaSavedPaymentMethodsSheet) public class SavedPaymentMethodsSheet {
    let configuration: SavedPaymentMethodsSheet.Configuration

    private var savedPaymentMethodsViewController: SavedPaymentMethodsViewController?

    private weak var savedPaymentMethodsSheetDelegate: SavedPaymentMethodsSheetDelegate?

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
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: configuration.appearance,
            isTestMode: isTestMode
        )

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

    public init(configuration: SavedPaymentMethodsSheet.Configuration,
                delegate: SavedPaymentMethodsSheetDelegate?) {
        self.configuration = configuration
        self.savedPaymentMethodsSheetDelegate = delegate
    }

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public func present(from presentingViewController: UIViewController) {
        // Retain self when being presented, it is not guarnteed that SavedPaymentMethodsSheet instance
        // will be retained by caller
        let completion: () -> Void = {
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true)
            }
            self.completion = nil
        }
        self.completion = completion

        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = SavedPaymentMethodsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            savedPaymentMethodsSheetDelegate?.didFail(with: error)
            return
        }
        loadPaymentMethods { result in
            switch result {
            case .success(let savedPaymentMethods):
                self.present(from: presentingViewController, savedPaymentMethods: savedPaymentMethods)
            case .failure(let error):
                self.savedPaymentMethodsSheetDelegate?.didFail(with: .errorFetchingSavedPaymentMethods(error))
                return
            }
        }
        presentingViewController.presentAsBottomSheet(bottomSheetViewController,
                                                      appearance: configuration.appearance)
    }

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    func present(from presentingViewController: UIViewController,
                 savedPaymentMethods: [STPPaymentMethod]) {
        let loadSpecsPromise = Promise<Void>()
        AddressSpecProvider.shared.loadAddressSpecs {
            loadSpecsPromise.resolve(with: ())
        }

        loadSpecsPromise.observe { _ in
            DispatchQueue.main.async {
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePayEnabled
                let savedPaymentSheetVC = SavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                                            configuration: self.configuration,
                                                                            isApplePayEnabled: isApplePayEnabled,
                                                                            savedPaymentMethodsSheetDelegate: self.savedPaymentMethodsSheetDelegate,
                                                                            delegate: self)
                self.bottomSheetViewController.contentStack = [savedPaymentSheetVC]
            }
        }
    }
    // MARK: - Internal Properties
    var completion: (() -> Void)?
}

extension SavedPaymentMethodsSheet {
    func loadPaymentMethods(completion: @escaping (Result<[STPPaymentMethod], Error>) -> Void) {
        configuration.customerContext.listPaymentMethodsForCustomer {
            paymentMethods, error in
            guard let paymentMethods = paymentMethods, error == nil else {
                let error = error ?? PaymentSheetError.unknown(
                    debugDescription: "Failed to retrieve PaymentMethods for the customer"
                )
                completion(.failure(error))
                return
            }
            let filteredPaymentMethods = paymentMethods.filter { $0.type == .card }
            completion(.success(filteredPaymentMethods))
        }

    }

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension SavedPaymentMethodsSheet: SavedPaymentMethodsViewControllerDelegate {
    func savedPaymentMethodsViewControllerShouldConfirm(_ intent: Intent?, with paymentOption: PaymentOption, completion: @escaping (SavedPaymentMethodsSheetResult) -> Void) {
        guard let intent = intent,
              case .setupIntent = intent else {
            assertionFailure("Setup intent not available")
            completion(.failed(error: SavedPaymentMethodsSheetError.unknown(debugDescription: "No setup intent available")))
            return
        }
        self.confirmIntent(intent: intent, paymentOption: paymentOption) { result in
            completion(result)
        }
    }

    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController, completion _completion: @escaping () -> Void) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            _completion()
            self.completion?()
        }
    }

    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController, completion _completion: @escaping () -> Void) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            _completion()
            self.completion?()
        }
    }
}

extension SavedPaymentMethodsSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}

@_spi(PrivateBetaSavedPaymentMethodsSheet) extension _stpspmsbeta_STPCustomerContext {
    /// Returns the selected Payment Option for this customer context.
    /// You can use this to obtain the selected payment method without loading the SavedPaymentMethodsSheet.
    public func retrievePaymentOptionSelection(
        completion: @escaping (SavedPaymentMethodsSheet.PaymentOptionSelection?, Error?) -> Void
    ) {
        self.listPaymentMethodsForCustomer { paymentMethods, error in
            guard let paymentMethods = paymentMethods, error == nil else {
                completion(nil, error)
                return
            }
            self.retrieveSelectedPaymentMethodOption { paymentMethodOption, error in
                guard error == nil,
                let paymentMethodOption = paymentMethodOption else {
                    completion(nil, error)
                    return
                }
                switch paymentMethodOption.type {
                case .applePay:
                    completion(SavedPaymentMethodsSheet.PaymentOptionSelection.applePay(), nil)
                case .stripe:
                    guard let stripePaymentMethod = paymentMethodOption.stripePaymentMethodId,
                        let matchingPaymentMethod = paymentMethods.first(where: { $0.stripeId == stripePaymentMethod }) else {
                        completion(nil, nil)
                        return
                    }
                    completion(SavedPaymentMethodsSheet.PaymentOptionSelection.savedPaymentMethod(matchingPaymentMethod), nil)
                default:
                    completion(nil, nil)
                }
            }
        }
    }
}
