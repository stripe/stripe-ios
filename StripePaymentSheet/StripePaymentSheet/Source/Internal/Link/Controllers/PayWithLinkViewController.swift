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

    func payWithLinkViewControllerDidCancel(
        _ payWithLinkViewController: PayWithLinkViewController,
        shouldReturnToPaymentSheet: Bool
    )

    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        result: PaymentSheetResult,
        deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?
    )

    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        confirmOption: PaymentSheet.LinkConfirmOption
    )

    func payWithLinkViewControllerShouldCancel3DS2ChallengeFlow(
        _ payWithLinkViewController: PayWithLinkViewController
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
    func cancel(shouldReturnToPaymentSheet: Bool)
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?)
    func handlePaymentDetailsSelected(_ paymentDetails: ConsumerPaymentDetails, confirmationExtras: LinkConfirmationExtras)
    func logout(cancel: Bool)
    func bailToWebFlow()
    func allowSheetDismissal(_ enable: Bool)
    func cancel3DS2ChallengeFlow()
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
        let shouldShowSecondaryCta: Bool
        let launchedFromFlowController: Bool
        let canSkipWalletAfterVerification: Bool
        let initiallySelectedPaymentDetailsID: String?
        let callToAction: ConfirmButton.CallToActionType
        let supportedPaymentMethodTypes: [LinkPaymentMethodType]
        var lastAddedPaymentDetails: ConsumerPaymentDetails?
        var analyticsHelper: PaymentSheetAnalyticsHelper
        let linkAppearance: LinkAppearance?
        let linkConfiguration: LinkConfiguration?

        var isDismissible: Bool = true

        var secondaryButtonLabel: String {
            if intent.isPaymentIntent && !launchedFromFlowController {
                String.Localized.pay_another_way
            } else {
                String.Localized.continue_another_way
            }
        }

        var showProcessingLabel: Bool {
            // If launched from FlowController for payment method selection (and not confirmation), we don't
            // want to show the "Processing…" label, as that label implies that the transaction is being
            // completed, which is not the case.
            !launchedFromFlowController
        }

        /// Returns the supported payment details types for the current Link account, filtered by the supportedPaymentMethodTypes.
        /// Returns [.card] as fallback if no types are supported after filtering.
        func getSupportedPaymentDetailsTypes(linkAccount: PaymentSheetLinkAccount) -> Set<ConsumerPaymentDetails.DetailsType> {
            let allSupportedPaymentDetailsTypes = linkAccount.supportedPaymentDetailsTypes(for: elementsSession)
            let filteredSupportedPaymentDetailsTypes = allSupportedPaymentDetailsTypes.intersection(supportedPaymentMethodTypes.detailsTypes)

            if !filteredSupportedPaymentDetailsTypes.isEmpty {
                return filteredSupportedPaymentDetailsTypes
            } else {
                // Card is the default payment method type when no other type is available.
                return [.card]
            }
        }

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - elementsSession: elements/session response.
        ///   - configuration: PaymentSheet configuration.
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        ///   - shouldFinishOnClose: Whether or not Link should finish with `.canceled` result instead of returning to Payment Sheet when the close button is tapped.
        ///   - shouldShowSecondaryCta: Whether or not a secondary CTA to pay another way should be shown.
        ///   - launchedFromFlowController: Whether the flow was opened from `FlowController`.
        ///   - canSkipWalletAfterVerification: Whether or not we should try to skip showing the wallet after verification.
        ///   - initiallySelectedPaymentDetailsID: The ID of an initially selected payment method. This is set when opened instead of FlowController.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        ///   - supportedPaymentMethodTypes: The payment method types to support in the Link sheet. Defaults to all available types.
        ///   - analyticsHelper: An instance of `AnalyticsHelper` to use for logging.
        ///   - linkAppearance: Optional appearance overrides for Link UI.
        ///   - linkConfiguration: Configuration for Link behavior and content.
        init(
            intent: Intent,
            elementsSession: STPElementsSession,
            configuration: PaymentElementConfiguration,
            shouldOfferApplePay: Bool,
            shouldFinishOnClose: Bool,
            shouldShowSecondaryCta: Bool = true,
            launchedFromFlowController: Bool = false,
            canSkipWalletAfterVerification: Bool,
            initiallySelectedPaymentDetailsID: String?,
            callToAction: ConfirmButton.CallToActionType?,
            supportedPaymentMethodTypes: [LinkPaymentMethodType] = LinkPaymentMethodType.allCases,
            analyticsHelper: PaymentSheetAnalyticsHelper,
            linkAppearance: LinkAppearance? = nil,
            linkConfiguration: LinkConfiguration? = nil
        ) {
            self.intent = intent
            self.elementsSession = elementsSession
            self.configuration = configuration
            self.shouldOfferApplePay = shouldOfferApplePay
            self.shouldFinishOnClose = shouldFinishOnClose
            self.shouldShowSecondaryCta = shouldShowSecondaryCta
            self.launchedFromFlowController = launchedFromFlowController
            self.canSkipWalletAfterVerification = canSkipWalletAfterVerification
            self.initiallySelectedPaymentDetailsID = initiallySelectedPaymentDetailsID
            self.callToAction = callToAction ?? .makeDefaultTypeForLink(intent: intent)
            self.supportedPaymentMethodTypes = supportedPaymentMethodTypes
            self.analyticsHelper = analyticsHelper
            self.linkAppearance = linkAppearance
            self.linkConfiguration = linkConfiguration
        }
    }

    private var context: Context
    private var accountContext: LinkAccountContext = .shared

    private var linkAccount: PaymentSheetLinkAccount? {
        get { accountContext.account }
        set { accountContext.account = newValue }
    }

    weak var payWithLinkDelegate: PayWithLinkViewControllerDelegate?

    var shippingAddressResponse: ShippingAddressesResponse?

    var defaultShippingAddress: ShippingAddressesResponse.ShippingAddress? {
        shippingAddressResponse?.shippingAddresses.first {
            $0.isDefault ?? false
        } ?? shippingAddressResponse?.shippingAddresses.first
    }

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }

    override var navigationBarHeight: CGFloat {
        LinkUI.navigationBarHeight
    }

    private var isBailingToWebFlow: Bool = false

    convenience init(
        intent: Intent,
        linkAccount: PaymentSheetLinkAccount?,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false,
        shouldShowSecondaryCta: Bool = true,
        launchedFromFlowController: Bool = false,
        initiallySelectedPaymentDetailsID: String? = nil,
        canSkipWalletAfterVerification: Bool,
        callToAction: ConfirmButton.CallToActionType? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        supportedPaymentMethodTypes: [LinkPaymentMethodType] = LinkPaymentMethodType.allCases,
        linkAppearance: LinkAppearance? = nil,
        linkConfiguration: LinkConfiguration? = nil
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)

        self.init(
            context: Context(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose,
                shouldShowSecondaryCta: shouldShowSecondaryCta,
                launchedFromFlowController: launchedFromFlowController,
                canSkipWalletAfterVerification: canSkipWalletAfterVerification,
                initiallySelectedPaymentDetailsID: initiallySelectedPaymentDetailsID,
                callToAction: callToAction,
                supportedPaymentMethodTypes: supportedPaymentMethodTypes,
                analyticsHelper: analyticsHelper,
                linkAppearance: linkAppearance,
                linkConfiguration: linkConfiguration
            ),
            linkAccount: linkAccount
        )
    }

    private init(context: Context, linkAccount: PaymentSheetLinkAccount?) {
        self.context = context
        let initialVC: BaseViewController = Self.initialVC(linkAccount: linkAccount, context: context)

        // Create a local variable that will hold the handler
        var cancellationHandler: (() -> Void)?

        super.init(
            contentViewController: initialVC,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: {
                cancellationHandler?()
            }
        )

        cancellationHandler = { [weak self] in
            self?.cancel3DS2ChallengeFlow()
        }

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

        // Re-enable user interaction when presenting a new controller.
        let wasUserInteractionEnabled = view.isUserInteractionEnabled
        if !wasUserInteractionEnabled {
            view.isUserInteractionEnabled = true
        }

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

        let supportedPaymentDetailsTypesSet = context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
        let supportedPaymentDetailsTypes = supportedPaymentDetailsTypesSet.toSortedArray()

        Task { @MainActor in
            async let paymentDetailsResult = linkAccount.listPaymentDetails(
                supportedTypes: supportedPaymentDetailsTypes,
                shouldRetryOnAuthError: false
            )

            async let shippingAddressResult = fetchShippingAddress(
                using: linkAccount,
                shouldFetch: context.launchedFromFlowController
            )

            do {
                let paymentDetails = try await paymentDetailsResult

                // Ignore any errors that might happen here.
                shippingAddressResponse = try? await shippingAddressResult

                let defaultPaymentDetails = paymentDetails.first(where: \.isDefault) ?? paymentDetails.first

                if let defaultPaymentDetails, canSkipWallet(for: linkAccount, with: defaultPaymentDetails) {
                    let billingDetailsValidator = LinkBillingDetailsValidator(linkAccount: linkAccount, context: context)
                    let validationResult = await billingDetailsValidator.validate(defaultPaymentDetails)

                    switch validationResult {
                    case .complete(let updatedPaymentDetails, let confirmationExtras):
                        // We have valid payment details, so we can skip the wallet and return the selection to the caller.
                        handlePaymentDetailsSelected(updatedPaymentDetails, confirmationExtras: confirmationExtras)
                        return
                    case .incomplete:
                        // We don't have valid payment details since we need to recollect missing billing details,
                        // so show the wallet.
                        break
                    }
                }

                presentAppropriateViewController(
                    with: linkAccount,
                    paymentDetails: paymentDetails
                )
            } catch {
                if error.isLinkAuthError {
                    // Ask the user to verify the session again, as it might have expired.
                    if let updatedAccount = await attemptReauthentication() {
                        setViewControllers([VerifyAccountViewController(linkAccount: updatedAccount, context: context)])
                        return
                    }
                }

                payWithLinkDelegate?.payWithLinkViewControllerDidFinish(
                    self,
                    result: PaymentSheetResult.failed(error: error),
                    deferredIntentConfirmationType: nil
                )
            }
        }
    }

    private func attemptReauthentication() async -> PaymentSheetLinkAccount? {
        // Tell the LinkAccountService to lookup again
        let accountService = LinkAccountService(apiClient: context.configuration.apiClient, elementsSession: context.elementsSession)

        return await withCheckedContinuation { continuation in
            accountService.lookupAccount(
                withEmail: linkAccount?.email,
                emailSource: .prefilledEmail,
                doNotLogConsumerFunnelEvent: false
            ) { result in
                switch result {
                case .success(let account):
                    self.linkAccount = account
                    continuation.resume(returning: account)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func canSkipWallet(
        for linkAccount: PaymentSheetLinkAccount,
        with paymentDetails: ConsumerPaymentDetails
    ) -> Bool {
        return linkAccount.sessionState == .verified && context.canSkipWalletAfterVerification && paymentDetails.isValidCard
    }

    private func fetchShippingAddress(
        using account: PaymentSheetLinkAccount,
        shouldFetch: Bool
    ) async throws -> ShippingAddressesResponse? {
        guard shouldFetch else { return nil }
        return try await account.listShippingAddress(shouldRetryOnAuthError: false)
    }

    private func presentAppropriateViewController(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: [ConsumerPaymentDetails]
    ) {
        let viewController: BottomSheetContentViewController
        if paymentDetails.isEmpty {
            // Check if only bank accounts are supported - if so, launch Financial Connections directly
            let supportedTypes = context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
            if supportedTypes == [.bankAccount] {
                startFinancialConnections { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .completed:
                        self.loadAndPresentWallet()
                    case .canceled:
                        self.cancel(shouldReturnToPaymentSheet: false)
                    case .failed(let error):
                        self.finish(withResult: .failed(error: error), deferredIntentConfirmationType: nil)
                    }
                }
                // Show a loading view while Financial Connections is being prepared
                viewController = LoaderViewController(context: context)
            } else {
                let addPaymentMethodVC = NewPaymentViewController(
                    linkAccount: linkAccount,
                    context: context,
                    isAddingFirstPaymentMethod: true
                )
                viewController = addPaymentMethodVC
            }
        } else {
            let walletViewController = WalletViewController(
                linkAccount: linkAccount,
                context: context,
                paymentMethods: paymentDetails
            )
            viewController = walletViewController
        }
        setViewControllers([viewController])
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
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self, shouldReturnToPaymentSheet: false)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = self.popContentViewController()
    }
}

// MARK: - Coordinating

extension PayWithLinkViewController: PayWithLinkCoordinating {
    func handlePaymentDetailsSelected(
        _ paymentDetails: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras
    ) {
        guard let linkAccount else {
            stpAssertionFailure(LinkAccountError.noLinkAccount.localizedDescription)
            return
        }

        let confirmOption = PaymentSheet.LinkConfirmOption.withPaymentDetails(
            account: linkAccount,
            paymentDetails: paymentDetails,
            confirmationExtras: confirmationExtras,
            shippingAddress: defaultShippingAddress
        )

        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, confirmOption: confirmOption)
    }

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

        sessionProvider { [weak self] sessionResult in
            switch sessionResult {
            case .success(let session):
                session.createLinkAccountSession(
                    linkMode: self?.context.elementsSession.linkSettings?.linkMode,
                    intentToken: self?.context.intent.stripeId
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
        guard let financialConnectionsAPI = FinancialConnectionsSDKAvailability.financialConnections() else {
            let error = PaymentSheetError.unknown(debugDescription: "Financial Connections is not available.")
            completion(.failed(error: error))
            return
        }

        let verificationSessions = consumerSession.verificationSessions.map { verificationSession in
            StripeCore.VerificationSession(
                type: .init(rawValue: verificationSession.type.rawValue) ?? .unparsable,
                state: .init(rawValue: verificationSession.state.rawValue)  ?? .unparsable
            )
        }
        let consumer = StripeCore.FinancialConnectionsConsumer(
            publishableKey: linkAccount.publishableKey,
            clientSecret: consumerSession.clientSecret,
            emailAddress: consumerSession.emailAddress,
            redactedFormattedPhoneNumber: consumerSession.redactedFormattedPhoneNumber,
            verificationSessions: verificationSessions
        )

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadataIfNecessary(analyticsHelper: context.analyticsHelper, intent: context.intent, elementsSession: context.elementsSession)

        func createPaymentDetails(linkedAccountId: String) {
            linkAccount.createPaymentDetails(
                linkedAccountId: linkedAccountId,
                isDefault: false,
                clientAttributionMetadata: clientAttributionMetadata,
                completion: { paymentDetailsResult in
                    switch paymentDetailsResult {
                    case .success:
                        completion(.completed)
                    case .failure(let error):
                        completion(.failed(error: error))
                    }
                }
            )
        }

        financialConnectionsAPI.presentFinancialConnectionsSheet(
            apiClient: context.configuration.apiClient,
            clientSecret: linkAccountSession.clientSecret,
            returnURL: context.configuration.returnURL,
            existingConsumer: consumer,
            style: .automatic,
            elementsSessionContext: ElementsSessionContext(clientAttributionMetadata: clientAttributionMetadata),
            onEvent: nil,
            from: self,
            completion: { result in
                switch result {
                case .completed(let financialConnectionsResult):
                    switch financialConnectionsResult {
                    case .linkedAccount(let id):
                        createPaymentDetails(linkedAccountId: id)
                    case .financialConnections(let linkedBank):
                        createPaymentDetails(linkedAccountId: linkedBank.accountId)
                    case .instantDebits(let linkedBank):
                        guard let linkedAccountId = linkedBank.linkAccountId else { fallthrough }
                        createPaymentDetails(linkedAccountId: linkedAccountId)
                    @unknown default:
                        let error = PaymentSheetError.unknown(debugDescription: "Unexpected Financial Connections result")
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
        payWithLinkDelegate?.payWithLinkViewControllerDidConfirm(
            self,
            intent: context.intent,
            elementsSession: context.elementsSession,
            with: PaymentOption.link(
                option: .withPaymentDetails(
                    account: linkAccount,
                    paymentDetails: paymentDetails,
                    confirmationExtras: confirmationExtras,
                    shippingAddress: defaultShippingAddress
                )
            ),
            completion: completion
        )
    }

    func allowSheetDismissal(_ enable: Bool) {
        view.isUserInteractionEnabled = enable
        context.isDismissible = enable
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

    func cancel(shouldReturnToPaymentSheet: Bool) {
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self, shouldReturnToPaymentSheet: shouldReturnToPaymentSheet)
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
            self.cancel(shouldReturnToPaymentSheet: true)
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
        guard !context.launchedFromFlowController else {
            // If we're launched from FlowController, then just finish with a wallet confirm option.
            // The wallet confirm option will trigger Link at the time of confirmation, where we can
            // use the web flow without issue.
            payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, confirmOption: .wallet)
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
        // Dismiss ourselves...
        self.dismiss(animated: false) {
            // ... and present the web controller. (This presentation will be handled by ASWebAuthenticationSession)
            payWithLinkVC.present(over: presentingViewController)
        }
        STPAnalyticsClient.sharedClient.logLinkBailedToWebFlow()
    }

    func cancel3DS2ChallengeFlow() {
        payWithLinkDelegate?.payWithLinkViewControllerShouldCancel3DS2ChallengeFlow(self)
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
                        case .canceled, .failed, .switchAccount:
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
