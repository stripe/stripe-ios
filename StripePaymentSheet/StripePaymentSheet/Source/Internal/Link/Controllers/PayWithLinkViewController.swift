//
//  PayWithLinkViewController.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 9/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol PayWithLinkViewControllerDelegate: AnyObject {

    func payWithLinkViewControllerDidConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    )

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController)

    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        result: PaymentSheetResult
    )

}

protocol PayWithLinkCoordinating: AnyObject {
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        completion: @escaping (PaymentSheetResult) -> Void
    )
    func confirmWithApplePay()
    func startInstantDebits(completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void)
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func finish(withResult result: PaymentSheetResult)
    func logout(cancel: Bool)
}

/// A view controller for paying with Link.
///
/// Instantiate and present this controller when the user chooses to pay with Link.
/// For internal SDK use only
@objc(STP_Internal_PayWithLinkViewController)
final class PayWithLinkViewController: UINavigationController {

    enum LinkAccountError: Error {
        case noLinkAccount

        var localizedDescription: String {
            "No Link account is set"
        }
    }

    final class Context {
        let intent: Intent
        let elementsSession: STPElementsSession
        let configuration: PaymentElementConfiguration
        let shouldOfferApplePay: Bool
        let shouldFinishOnClose: Bool
        let callToAction: ConfirmButton.CallToActionType
        var lastAddedPaymentDetails: ConsumerPaymentDetails?
        var analyticsHelper: PaymentSheetAnalyticsHelper

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - elementsSession: elements/session response.
        ///   - configuration: PaymentSheet configuration.
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        ///   - shouldFinishOnClose: Whether or not Link should finish with `.canceled` result instead of returning to Payment Sheet when the close button is tapped.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        ///   - analyticsHelper: An instance of `AnalyticsHelper` to use for logging.
        init(
            intent: Intent,
            elementsSession: STPElementsSession,
            configuration: PaymentElementConfiguration,
            shouldOfferApplePay: Bool,
            shouldFinishOnClose: Bool,
            callToAction: ConfirmButton.CallToActionType?,
            analyticsHelper: PaymentSheetAnalyticsHelper
        ) {
            self.intent = intent
            self.elementsSession = elementsSession
            self.configuration = configuration
            self.shouldOfferApplePay = shouldOfferApplePay
            self.shouldFinishOnClose = shouldFinishOnClose
            self.callToAction = callToAction ?? intent.callToAction
            self.analyticsHelper = analyticsHelper
        }
    }

    private var context: Context
    private var accountContext: LinkAccountContext = .shared

    private var linkAccount: PaymentSheetLinkAccount? {
        get { accountContext.account }
        set { accountContext.account = newValue }
    }

    weak var payWithLinkDelegate: PayWithLinkViewControllerDelegate?

    private var isShowingLoader: Bool {
        guard let rootViewController = viewControllers.first else {
            return false
        }

        return rootViewController is LoaderViewController
    }

    convenience init(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false,
        callToAction: ConfirmButton.CallToActionType? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.init(
            context: Context(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose,
                callToAction: callToAction,
                analyticsHelper: analyticsHelper
            )
        )
    }

    private init(context: Context) {
        self.context = context
        super.init(nibName: nil, bundle: nil)

        // Show loader
        setRootViewController(LoaderViewController(context: context), animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "Stripe.Link.PayWithLinkViewController"
        view.tintColor = .linkBrand

        // Hide the default navigation bar.
        setNavigationBarHidden(true, animated: false)

        // Apply the preferred user interface style.
        context.configuration.style.configure(self)

        updateSupportedPaymentMethods()
        updateUI()

        // The internal delegate of the interactive pop gesture disables
        // the gesture when the navigation bar is hidden. Use a custom delegate
        // to restore the functionality.
        interactivePopGestureRecognizer?.delegate = self
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
            viewController.customNavigationBar.linkAccount = linkAccount
            viewController.customNavigationBar.showBackButton = !viewControllers.isEmpty
        }

        super.pushViewController(viewController, animated: animated)
    }

    private func updateUI() {
        guard let linkAccount = linkAccount else {
            if !(rootViewController is SignUpViewController) {
                setRootViewController(
                    SignUpViewController(linkAccount: nil, context: context)
                )
            }
            return
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            if !(rootViewController is SignUpViewController) {
                setRootViewController(
                    SignUpViewController(linkAccount: linkAccount, context: context)
                )
            }
        case .requiresVerification:
            setRootViewController(VerifyAccountViewController(linkAccount: linkAccount, context: context))
        case .verified:
            loadAndPresentWallet()
        }
    }

}

extension PayWithLinkViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }

}

// MARK: - Utils

private extension PayWithLinkViewController {

    func loadAndPresentWallet() {
        let shouldAnimate = !(rootViewController is WalletViewController)
        setRootViewController(LoaderViewController(context: context), animated: shouldAnimate)

        guard let linkAccount else {
            stpAssertionFailure(LinkAccountError.noLinkAccount.localizedDescription)
            return
        }

        linkAccount.listPaymentDetails { result in
            switch result {
            case .success(let paymentDetails):
                if paymentDetails.isEmpty {
                    let addPaymentMethodVC = NewPaymentViewController(
                        linkAccount: linkAccount,
                        context: self.context,
                        isAddingFirstPaymentMethod: true
                    )

                    self.setRootViewController(addPaymentMethodVC)
                } else {
                    let walletViewController = WalletViewController(
                        linkAccount: linkAccount,
                        context: self.context,
                        paymentMethods: paymentDetails
                    )

                    self.setRootViewController(walletViewController)
                }
            case .failure(let error):
                self.payWithLinkDelegate?.payWithLinkViewControllerDidFinish(
                    self, result: PaymentSheetResult.failed(error: error)
                )
            }
        }
    }

    func updateSupportedPaymentMethods() {
        PaymentSheet.supportedLinkPaymentMethods =
            linkAccount?.supportedPaymentMethodTypes(for: context.elementsSession) ?? []
    }

}

// MARK: - Navigation

private extension PayWithLinkViewController {

    var rootViewController: UIViewController? {
        return viewControllers.first
    }

    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
            viewController.customNavigationBar.linkAccount = linkAccount
            viewController.customNavigationBar.showBackButton = false
        }

        setViewControllers([viewController], animated: isShowingLoader ? false : animated)
    }

}

// MARK: - Coordinating

extension PayWithLinkViewController: PayWithLinkCoordinating {
    func startInstantDebits(completion: @escaping (Result<ConsumerPaymentDetails, any Error>) -> Void) {
        // TODO(link): Not yet implemented.
    }

    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        view.isUserInteractionEnabled = false

        payWithLinkDelegate?.payWithLinkViewControllerDidConfirm(
            self,
            intent: context.intent,
            elementsSession: context.elementsSession,
            with: PaymentOption.link(
                option: .withPaymentDetails(account: linkAccount, paymentDetails: paymentDetails)
            )
        ) { [weak self] result, _ in
//            TODO(link): Log confirmation type here
            self?.view.isUserInteractionEnabled = true
            completion(result)
        }
    }

    func confirmWithApplePay() {
        payWithLinkDelegate?.payWithLinkViewControllerDidConfirm(
            self,
            intent: context.intent,
            elementsSession: context.elementsSession,
            with: .applePay
        ) { [weak self] result, _ in
            //            TODO(link): Log confirmation type here
            switch result {
            case .canceled:
                // no-op -- we don't dismiss/finish for canceled Apple Pay interactions
                break
            case .completed, .failed:
                self?.finish(withResult: result)
            }
        }
    }

    func cancel() {
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self)
    }

    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {
        self.linkAccount = linkAccount
        updateSupportedPaymentMethods()
        updateUI()
    }

    func finish(withResult result: PaymentSheetResult) {
        view.isUserInteractionEnabled = false
        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: result)
    }

    func logout(cancel: Bool) {
        linkAccount?.logout()
        linkAccount = nil

        if cancel {
            self.cancel()
        } else {
            updateUI()
        }
    }

}

extension PayWithLinkViewController: STPAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        return self
    }

}
