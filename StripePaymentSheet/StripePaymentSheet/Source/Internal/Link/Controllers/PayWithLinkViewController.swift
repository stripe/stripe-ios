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
        result: PaymentSheetResult,
        deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?
    )

}

protocol PayWithLinkCoordinating: AnyObject {
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras?,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    )
    func confirmWithApplePay()
    func startInstantDebits(completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void)
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?)
    func logout(cancel: Bool)
    func bailToWebFlow()
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

    private var isBailingToWebFlow: Bool = false

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

        // Prewarm attestation if needed
        Task {
            // Attempt to attest
            let canAttest = await context.configuration.apiClient.stripeAttest.prepareAttestation()
            // If we can't attest and we're in livemode, let's bail and switch to the web controller
            if !canAttest && !context.configuration.apiClient.isTestmode {
                DispatchQueue.main.async {
                    self.bailToWebFlow()
                }
                return
            }
        }
        // The internal delegate of the interactive pop gesture disables
        // the gesture when the navigation bar is hidden. Use a custom delegate
        // to restore the functionality.
        interactivePopGestureRecognizer?.delegate = self

        LinkAccountContext.shared.addObserver(self, selector: #selector(onAccountChange(_:)))
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    @objc
    func onAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            linkAccount?.paymentSheetLinkAccountDelegate = self
        }
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

        let supportedPaymentDetailsTypes = linkAccount
            .supportedPaymentDetailsTypes(for: context.elementsSession)
            .toSortedArray()

        linkAccount.listPaymentDetails(
            supportedTypes: supportedPaymentDetailsTypes
        ) { result in
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
                    self,
                    result: PaymentSheetResult.failed(error: error),
                    deferredIntentConfirmationType: nil
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
        confirmationExtras: LinkConfirmationExtras?,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        view.isUserInteractionEnabled = false

        payWithLinkDelegate?.payWithLinkViewControllerDidConfirm(
            self,
            intent: context.intent,
            elementsSession: context.elementsSession,
            with: PaymentOption.link(
                option: .withPaymentDetails(
                    account: linkAccount,
                    paymentDetails: paymentDetails,
                    confirmationExtras: confirmationExtras
                )
            )
        ) { [weak self] result, confirmationType in
            self?.view.isUserInteractionEnabled = true
            completion(result, confirmationType)
        }
    }

    func confirmWithApplePay() {
        payWithLinkDelegate?.payWithLinkViewControllerDidConfirm(
            self,
            intent: context.intent,
            elementsSession: context.elementsSession,
            with: .applePay
        ) { [weak self] result, confirmationType in
            switch result {
            case .canceled:
                // no-op -- we don't dismiss/finish for canceled Apple Pay interactions
                break
            case .completed, .failed:
                self?.finish(withResult: result, deferredIntentConfirmationType: confirmationType)
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

    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        view.isUserInteractionEnabled = false
        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: result, deferredIntentConfirmationType: deferredIntentConfirmationType)
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

    // Dismiss the native Link VC and launch into the web Link flow
    func bailToWebFlow() {
        guard !isBailingToWebFlow else {
            // Multiple things can kick off bailing to web flow, but we only want to do it once
            return
        }
        isBailingToWebFlow = true
        // Make sure we're presenting over a VC
        guard let presentingViewController else {
            // No VC to present over, so don't bail
            return
        }
        // Make sure we have an active delegate that responds to all Link delegate methods
        guard let payWithLinkWebDelegate = payWithLinkDelegate as? PayWithLinkWebControllerDelegate else {
            stpAssertionFailure("Delegate doesn't exist or can't be transformed into a PayWithLinkWebControllerDelegate")
            return
        }
        // Set up a web controller with the same settings and swap to it
        let payWithLinkVC = PayWithLinkWebController(
            intent: context.intent,
            elementsSession: context.elementsSession,
            configuration: context.configuration,
            alwaysUseEphemeralSession: true
        )
        payWithLinkVC.payWithLinkDelegate = payWithLinkWebDelegate
        // Dismis ourselves...
        self.dismiss(animated: false)
        // ... and present the web controller. (This presentation will be handled by ASWebAuthenticationSession)
        payWithLinkVC.present(over: presentingViewController)
        STPAnalyticsClient.sharedClient.logLinkBailedToWebFlow()
    }

}

extension PayWithLinkViewController: STPAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        return self
    }

}

extension PayWithLinkViewController: PaymentSheetLinkAccountDelegate {
    func refreshLinkSession(completion: @escaping (Result<ConsumerSession, any Error>) -> Void) {
        // Tell the LinkAccountService to lookup again
        let accountService = LinkAccountService(apiClient: context.configuration.apiClient, elementsSession: context.elementsSession)
        accountService.lookupAccount(
            withEmail: linkAccount?.email,
            emailSource: .prefilledEmail,
            doNotLogConsumerFunnelEvent: false
        ) { result in
            switch result {
            case .success(let account):
                DispatchQueue.main.async {
                    guard let account else {
                        completion(.failure(PaymentSheetError.unknown(debugDescription: "No account found")))
                        return
                    }
                    let verificationController = LinkVerificationController(
                        mode: .modal,
                        linkAccount: account,
                        configuration: self.context.configuration
                    )
                    verificationController.present(from: self) { result in
                        switch result {
                        case .completed:
                            // Return the session from the new account
                            guard let newSession = account.currentSession else {
                                completion(.failure(PaymentSheetError.unknown(debugDescription: "No session found")))
                                return
                            }
                            completion(.success(newSession))
                        case .canceled, .failed:
                            completion(.failure(PaymentSheetError.unknown(debugDescription: "Authentication failed")))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

    }

}

// Used to get deterministic ordering
private extension Set where Element == ConsumerPaymentDetails.DetailsType {
    func toSortedArray() -> [ConsumerPaymentDetails.DetailsType] {
        return self.sorted { lhs, rhs in
            lhs.rawValue.localizedCaseInsensitiveCompare(rhs.rawValue) == .orderedAscending
        }
    }
}
