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
    func startFinancialConnections(completion: @escaping (PaymentSheetResult) -> Void)
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
final class PayWithLinkViewController: BottomSheetViewController {

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

        var isDismissible: Bool = true

        var secondaryButtonLabel: String {
            if intent.isPaymentIntent {
                String.Localized.pay_another_way
            } else {
                String.Localized.continue_another_way
            }
        }

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
            self.callToAction = callToAction ?? .makeDefaultTypeForLink(intent: intent)
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

    private var isBailingToWebFlow: Bool = false

    convenience init(
        intent: Intent,
        linkAccount: PaymentSheetLinkAccount?,
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
            ),
            linkAccount: linkAccount
        )
    }

    private init(context: Context, linkAccount: PaymentSheetLinkAccount?) {
        self.context = context
        let initialVC: BaseViewController = Self.initialVC(linkAccount: linkAccount, context: context)
        super.init(contentViewController: initialVC, appearance: context.configuration.appearance, isTestMode: false, didCancelNative3DS2: {})
        initialVC.coordinator = self
        initialVC.navigationBar.delegate = self
        self.linkAccount = linkAccount
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: BottomSheetContentViewController, appearance: PaymentSheet.Appearance, isTestMode: Bool, didCancelNative3DS2: @escaping () -> Void) {
        fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Stripe.Link.PayWithLinkViewController"
        view.tintColor = .linkIconBrand

        context.configuration.style.configure(self)

        updateSupportedPaymentMethods()

        if linkAccount?.sessionState == .verified {
            loadAndPresentWallet()
        }

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

    override func pushContentViewController(_ contentViewController: any BottomSheetContentViewController) {
        super.pushContentViewController(contentViewController)
        if let viewController = contentViewController as? BaseViewController {
            viewController.coordinator = self
            if contentStack.count > 1 {
                viewController.navigationBar.setStyle(.back(showAdditionalButton: false))
            }
            viewController.navigationBar.delegate = self
        }
    }

    override func setViewControllers(_ viewControllers: [any BottomSheetContentViewController]) {
        super.setViewControllers(viewControllers)
        for viewController in viewControllers {
            guard let viewController = viewController as? BaseViewController else { continue }
            viewController.coordinator = self
            viewController.navigationBar.delegate = self
        }
    }

    private static func initialVC(linkAccount: PaymentSheetLinkAccount?, context: Context) -> BaseViewController {
        guard let linkAccount = linkAccount else {
            return SignUpViewController(linkAccount: nil, context: context)
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            return SignUpViewController(linkAccount: linkAccount, context: context)
        case .requiresVerification:
            return VerifyAccountViewController(linkAccount: linkAccount, context: context)
        case .verified:
            return LoaderViewController(context: context)
        }
    }

    private func updateUI() {
        guard let linkAccount = linkAccount else {
            if !(rootViewController is SignUpViewController) {
                self.setViewControllers(
                    [SignUpViewController(linkAccount: nil, context: self.context)]
                )
            }
            return
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            if !(rootViewController is SignUpViewController) {
                setViewControllers(
                    [SignUpViewController(linkAccount: linkAccount, context: context)]
                )
            }
        case .requiresVerification:
            setViewControllers([VerifyAccountViewController(linkAccount: linkAccount, context: context)])
        case .verified:
            loadAndPresentWallet()
        }
    }
}

// MARK: - Utils

private extension PayWithLinkViewController {

    func loadAndPresentWallet() {
        if rootViewController as? LoaderViewController == nil {
            setViewControllers([LoaderViewController(context: context)])
        }

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

                    self.setViewControllers([addPaymentMethodVC])
                } else {
                    let walletViewController = WalletViewController(
                        linkAccount: linkAccount,
                        context: self.context,
                        paymentMethods: paymentDetails
                    )

                    self.setViewControllers([walletViewController])
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

extension PayWithLinkViewController {
    var rootViewController: UIViewController? {
        return contentStack.first
    }
}

extension PayWithLinkViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = self.popContentViewController()
    }
}

// MARK: - Coordinating

extension PayWithLinkViewController: PayWithLinkCoordinating {
    func startFinancialConnections(completion: @escaping (PaymentSheetResult) -> Void) {
        guard let linkAccount else {
            let error = PaymentSheetError.unknown(debugDescription: "No Link account found")
            completion(.failed(error: error))
            return
        }

        // Provides either the existing session or fetches a new session.
        let sessionProvider: (@escaping (Result<ConsumerSession, Error>) -> Void) -> Void = { completion in
            if let existingSession = linkAccount.currentSession {
                completion(.success(existingSession))
            } else {
                self.refreshLinkSession(completion: completion)
            }
        }

        sessionProvider { sessionResult in
            switch sessionResult {
            case .success(let session):
                session.createLinkAccountSession(
                    consumerAccountPublishableKey: linkAccount.publishableKey
                ) { [session, weak self] linkAccountSessionResult in
                    switch linkAccountSessionResult {
                    case .success(let linkAccountSession):
                        self?.launchFinancialConnections(
                            with: linkAccountSession,
                            linkAccount: linkAccount,
                            consumerSession: session,
                            completion: completion
                        )
                    case .failure(let error):
                        completion(.failed(error: error))
                    }
                }
            case .failure(let error):
                completion(.failed(error: error))
            }
        }
    }

    private func launchFinancialConnections(
        with linkAccountSession: LinkAccountSession,
        linkAccount: PaymentSheetLinkAccount,
        consumerSession: ConsumerSession,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        let bankAccountCollector = STPBankAccountCollector(apiClient: context.configuration.apiClient)
        bankAccountCollector.collectBankAccountForDeferredIntent(
            sessionId: linkAccountSession.stripeID,
            returnURL: nil,
            onEvent: nil,
            amount: nil,
            currency: nil,
            onBehalfOf: nil,
            elementsSessionContext: nil,
            from: self,
            financialConnectionsCompletion: { (result, _, possibleError) in
                if let error = possibleError {
                    completion(.failed(error: error))
                    return
                }

                guard let result else {
                    let error = PaymentSheetError.unknown(debugDescription: "No Financial Connections result")
                    completion(.failed(error: error))
                    return
                }

                switch result {
                case .completed(let financialConnectionsResult):
                    switch financialConnectionsResult {
                    case .financialConnections(let linkedBank):
                        consumerSession.createPaymentDetails(
                            linkedAccountId: linkedBank.accountId,
                            consumerAccountPublishableKey: linkAccount.publishableKey,
                            completion: { paymentDetailsResult in
                                switch paymentDetailsResult {
                                case .success:
                                    completion(.completed)
                                case .failure(let error):
                                    completion(.failed(error: error))
                                }
                            }
                        )
                    case .instantDebits:
                        fallthrough
                    @unknown default:
                        let error = PaymentSheetError.unknown(debugDescription: "Unknown Financial Connections result")
                        completion(.failed(error: error))
                    }
                case .cancelled:
                    completion(.canceled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            }
        )
    }

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
        context.isDismissible = false
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
            self?.context.isDismissible = true
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
extension Set where Element == ConsumerPaymentDetails.DetailsType {
    func toSortedArray() -> [ConsumerPaymentDetails.DetailsType] {
        return self.sorted { lhs, rhs in
            lhs.rawValue.localizedCaseInsensitiveCompare(rhs.rawValue) == .orderedAscending
        }
    }
}
