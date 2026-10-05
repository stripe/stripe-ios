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

@MainActor
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

@MainActor
protocol PayWithLinkCoordinating: AnyObject {
    func pushContentViewController(_ contentViewController: PayWithLinkViewController.BaseViewController)
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

/// Coordinates Link content inside the selected sheet container.
///
/// Instantiate this coordinator when the user chooses to pay with Link, then present its `sheetContainer`.
/// For internal SDK use only
@objc(STP_Internal_PayWithLinkViewController)
@MainActor
final class PayWithLinkViewController: NSObject {

    enum LinkAccountError: LocalizedError {
        case noLinkAccount
        case noFundingSources

        var errorDescription: String? {
            switch self {
            case .noLinkAccount:
                return "No Link account is set"
            case .noFundingSources:
                return "No supported payment methods available for this Link session"
            }
        }
    }

    @MainActor
    final class Context {
        let intent: Intent
        let elementsSession: STPElementsSession
        let configuration: PaymentElementConfiguration
        var linkBrand: LinkBrand
        let shouldOfferApplePay: Bool
        let shouldFinishOnClose: Bool
        let canContinueWithoutLink: Bool
        let launchedFromFlowController: Bool
        let initiallySelectedPaymentDetailsID: String?
        let callToAction: ConfirmButton.CallToActionType
        let supportedPaymentMethodTypes: [LinkPaymentMethodType]?
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
        /// Returns an empty set if no funding sources are available at the session-level, consumer-level, or their intersection.
        func getSupportedPaymentDetailsTypes(linkAccount: PaymentSheetLinkAccount) -> Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> {
            var allSupportedPaymentDetailsTypes = linkAccount.supportedPaymentDetailsTypes(for: elementsSession)

            if let supportedPaymentDetailsTypes = supportedPaymentMethodTypes?.detailsTypes,
               !supportedPaymentDetailsTypes.isEmpty {
                allSupportedPaymentDetailsTypes = allSupportedPaymentDetailsTypes.intersection(supportedPaymentDetailsTypes)
            }

            return allSupportedPaymentDetailsTypes
        }

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - elementsSession: elements/session response.
        ///   - configuration: PaymentSheet configuration.
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        ///   - shouldFinishOnClose: Whether or not Link should finish with `.canceled` result instead of returning to Payment Sheet when the close button is tapped.
        ///   - canContinueWithoutLink: Whether the user can exit Link and pay with a different method (e.g. via PaymentSheet).
        ///   - launchedFromFlowController: Whether the flow was opened from `FlowController`.
        ///   - initiallySelectedPaymentDetailsID: The ID of an initially selected payment method. This is set when opened instead of FlowController.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        ///   - supportedPaymentMethodTypes: The payment method types to support in the Link sheet. If `nil` or empty, all available types are supported.
        ///   - analyticsHelper: An instance of `AnalyticsHelper` to use for logging.
        ///   - linkAppearance: Optional appearance overrides for Link UI.
        ///   - linkConfiguration: Configuration for Link behavior and content.
        init(
            intent: Intent,
            elementsSession: STPElementsSession,
            configuration: PaymentElementConfiguration,
            linkBrand: LinkBrand,
            shouldOfferApplePay: Bool,
            shouldFinishOnClose: Bool,
            canContinueWithoutLink: Bool = true,
            launchedFromFlowController: Bool = false,
            initiallySelectedPaymentDetailsID: String?,
            callToAction: ConfirmButton.CallToActionType?,
            supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
            analyticsHelper: PaymentSheetAnalyticsHelper,
            linkAppearance: LinkAppearance? = nil,
            linkConfiguration: LinkConfiguration? = nil
        ) {
            self.intent = intent
            self.elementsSession = elementsSession
            self.configuration = configuration
            self.linkBrand = linkBrand
            self.shouldOfferApplePay = shouldOfferApplePay
            self.shouldFinishOnClose = shouldFinishOnClose
            self.canContinueWithoutLink = canContinueWithoutLink
            self.launchedFromFlowController = launchedFromFlowController
            self.initiallySelectedPaymentDetailsID = initiallySelectedPaymentDetailsID
            self.callToAction = callToAction ?? .makeDefaultType(intent: intent, withLock: false)
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

    let sheetContainer: any PaymentSheetContainer

    var shippingAddressResponse: ShippingAddressesResponse?

    var defaultShippingAddress: ShippingAddressesResponse.ShippingAddress? {
        shippingAddressResponse?.shippingAddresses.first {
            $0.isDefault ?? false
        } ?? shippingAddressResponse?.shippingAddresses.first
    }

    private var isBailingToWebFlow: Bool = false

    convenience init(
        intent: Intent,
        linkAccount: PaymentSheetLinkAccount?,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        nativeSheetPresentation: SheetImplementationResolver? = nil,
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false,
        canContinueWithoutLink: Bool = true,
        launchedFromFlowController: Bool = false,
        initiallySelectedPaymentDetailsID: String? = nil,
        callToAction: ConfirmButton.CallToActionType? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        linkAppearance: LinkAppearance? = nil,
        linkConfiguration: LinkConfiguration? = nil
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)

        self.init(
            context: Context(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                linkBrand: configuration.resolvedLinkBrand(elementsSession: elementsSession, linkAccount: linkAccount),
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose,
                canContinueWithoutLink: canContinueWithoutLink,
                launchedFromFlowController: launchedFromFlowController,
                initiallySelectedPaymentDetailsID: initiallySelectedPaymentDetailsID,
                callToAction: callToAction,
                supportedPaymentMethodTypes: supportedPaymentMethodTypes,
                analyticsHelper: analyticsHelper,
                linkAppearance: linkAppearance,
                linkConfiguration: linkConfiguration
            ),
            linkAccount: linkAccount,
            nativeSheetPresentation: nativeSheetPresentation
        )
    }

    private init(context: Context, linkAccount: PaymentSheetLinkAccount?, nativeSheetPresentation: SheetImplementationResolver?) {
        self.context = context
        let initialVC: BaseViewController = Self.initialVC(linkAccount: linkAccount, context: context)

        // Create a local variable that will hold the handler
        var cancellationHandler: (() -> Void)?
        let didCancelNative3DS2: () -> Void = {
            if let cancellationHandler {
                cancellationHandler()
            }
        }

        sheetContainer = LinkSheetContainerFactory.make(
            contentViewController: initialVC,
            usesNativeSheet: nativeSheetPresentation?.usesNativeSheet ?? false,
            didCancelNative3DS2: didCancelNative3DS2
        )

        super.init()

        cancellationHandler = { [weak self] in
            self?.cancel3DS2ChallengeFlow()
        }

        initialVC.coordinator = self
        initialVC.navigationBar.delegate = self
        self.linkAccount = linkAccount
        start()
    }

    private func start() {
        sheetContainer.view.accessibilityIdentifier = "Stripe.Link.PayWithLinkViewController"

        context.configuration.style.configure(sheetContainer)

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

    var presentingViewController: UIViewController? {
        sheetContainer.presentingViewController
    }

    var contentStack: [BottomSheetContentViewController] {
        sheetContainer.contentStack
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        sheetContainer.dismiss(animated: animated, completion: completion)
    }

    @objc
    func onAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            linkAccount?.paymentSheetLinkAccountDelegate = self
            self?.syncContextLinkBrand(using: linkAccount)
        }
    }

    func pushContentViewController(_ contentViewController: BaseViewController) {
        // Configure Link actions before the container displays the screen or publishes its navigation items.
        contentViewController.coordinator = self
        contentViewController.navigationBar.delegate = self
        if !contentStack.isEmpty {
            contentViewController.navigationBar.setStyle(.back(showAdditionalButton: false))
        }

        // Re-enable user interaction when presenting a new controller.
        if !sheetContainer.view.isUserInteractionEnabled {
            setUserInteractionEnabled(true)
        }
        sheetContainer.pushContentViewController(contentViewController)
    }

    func setViewControllers(_ viewControllers: [any BottomSheetContentViewController]) {
        sheetContainer.setViewControllers(viewControllers)
        for viewController in viewControllers {
            guard let viewController = viewController as? BaseViewController else { continue }
            viewController.coordinator = self
            viewController.navigationBar.delegate = self
        }
    }

    @discardableResult
    func popContentViewController(completion: (() -> Void)? = nil) -> BottomSheetContentViewController? {
        sheetContainer.popContentViewController(completion: completion)
    }

    func setUserInteractionEnabled(_ enabled: Bool) {
        sheetContainer.setUserInteractionEnabled(enabled)
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

    func syncContextLinkBrand(using linkAccount: PaymentSheetLinkAccount?) {
        context.linkBrand = context.configuration.resolvedLinkBrand(
            elementsSession: context.elementsSession,
            linkAccount: linkAccount
        )
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

        guard !supportedPaymentDetailsTypesSet.isEmpty else {
            finish(withResult: .failed(error: LinkAccountError.noFundingSources), deferredIntentConfirmationType: nil)
            return
        }

        let supportedPaymentDetailsTypes = supportedPaymentDetailsTypesSet.toSortedArray()

        Task { @MainActor in
            let paymentDetailsTask = Task {
                try await linkAccount.listPaymentDetails(
                    supportedTypes: supportedPaymentDetailsTypes,
                    shouldRetryOnAuthError: false
                )
            }
            let shippingAddressTask = Task {
                try? await self.fetchShippingAddress(
                    using: linkAccount,
                    shouldFetch: context.launchedFromFlowController
                )
            }
            defer {
                paymentDetailsTask.cancel()
                shippingAddressTask.cancel()
            }

            do {
                let paymentDetails = try await paymentDetailsTask.value

                // Ignore any errors that might happen here.
                shippingAddressResponse = await shippingAddressTask.value

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
                    self.syncContextLinkBrand(using: account)
                    continuation.resume(returning: account)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
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
        // Check if only bank accounts are supported - if so, launch Financial Connections directly
        let supportedTypes = context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
        if paymentDetails.isEmpty && supportedTypes == [ParsedEnum(.bankAccount)] {
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
            brand: context.linkBrand,
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
                let permissions = self?.context.linkConfiguration?.financialConnectionsPermissions
                // The LAS response includes the default `payment_method` permission even when the merchant did not
                // request data permissions. Use the normalized request to determine the session's authentication mode.
                let requestedPermissions = (permissions?.isEmpty ?? true) ? nil : permissions
                session.createLinkAccountSession(
                    linkMode: self?.context.elementsSession.linkSettings?.linkMode,
                    intentToken: self?.context.intent.stripeId ?? self?.context.elementsSession.sessionID,
                    permissions: requestedPermissions,
                    merchantToken: requestedPermissions == nil ? nil : self?.context.elementsSession.accountID
                ) { [session, weak self] linkAccountSessionResult in
                    switch linkAccountSessionResult {
                    case .success(let linkAccountSession):
                        self?.launchFinancialConnections(
                            with: linkAccountSession,
                            linkAccount: linkAccount,
                            consumerSession: session,
                            hasRequestedDataPermissions: requestedPermissions != nil,
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
        hasRequestedDataPermissions: Bool,
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
            verificationSessions: verificationSessions,
            linkBrand: consumerSession.linkBrand
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
            hasRequestedDataPermissions: hasRequestedDataPermissions,
            style: {
                switch context.linkAppearance?.style {
                case .alwaysLight: return .alwaysLight
                case .alwaysDark: return .alwaysDark
                default: return .automatic
                }
            }(),
            elementsSessionContext: ElementsSessionContext(
                linkSettings: context.elementsSession.linkSettings.map {
                    ElementsSessionContext.LinkSettings(
                        useAttestationEndpoints: $0.useAttestationEndpoints,
                        brand: context.linkBrand
                    )
                },
                clientAttributionMetadata: clientAttributionMetadata
            ),
            preCollectedConsent: nil,
            linkBrand: context.configuration.financialConnectionsLinkBrandOverride,
            onEvent: nil,
            from: sheetContainer,
            completion: { result in
                switch result {
                case .completed(let financialConnectionsResult):
                    switch financialConnectionsResult {
                    case .paymentDetails:
                        completion(.completed)
                    case .linkedAccount(let id):
                        guard !hasRequestedDataPermissions else {
                            completion(.failed(error: PaymentSheetError.unknown(
                                debugDescription: "Permissioned Link Account Session completed without generated payment details."
                            )))
                            return
                        }
                        createPaymentDetails(linkedAccountId: id)
                    case .financialConnections(let linkedBank):
                        if hasRequestedDataPermissions {
                            completion(.completed)
                        } else {
                            createPaymentDetails(linkedAccountId: linkedBank.accountId)
                        }
                    case .instantDebits(let linkedBank):
                        guard !hasRequestedDataPermissions else {
                            completion(.failed(error: PaymentSheetError.unknown(
                                debugDescription: "Permissioned Link Account Session completed without generated payment details."
                            )))
                            return
                        }
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
                    brand: context.linkBrand,
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
        setUserInteractionEnabled(enable)
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
        syncContextLinkBrand(using: linkAccount)
        updateSupportedPaymentMethods()
        updateUI()
    }

    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        setUserInteractionEnabled(false)
        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: result, deferredIntentConfirmationType: deferredIntentConfirmationType)
    }

    func logout(cancel: Bool) {
        linkAccount?.logout()
        linkAccount = nil

        if cancel && context.canContinueWithoutLink {
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
            payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, confirmOption: .wallet(brand: context.linkBrand))
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
            linkAccount: linkAccount,
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
                        brand: account.linkBrand ?? self.context.linkBrand,
                        configuration: self.context.configuration,
                        appearance: self.context.linkAppearance
                    )
                    verificationController.present(from: self.sheetContainer) { result in
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
extension Set where Element == ParsedEnum<ConsumerPaymentDetails.DetailsType> {
    func toSortedArray() -> [ParsedEnum<ConsumerPaymentDetails.DetailsType>] {
        return self.sorted { lhs, rhs in
            lhs.rawValue.localizedCaseInsensitiveCompare(rhs.rawValue) == .orderedAscending
        }
    }
}
