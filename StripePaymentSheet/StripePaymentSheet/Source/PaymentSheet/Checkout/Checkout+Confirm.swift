@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

// MARK: - Types

/// Integration-side inputs for Checkout client attribution metadata (CAM) and `payment_user_agent`.
struct CheckoutAttributionContext {
    /// The element whose collection or confirmation flow is being attributed; determines the CAM subtype and `payment_user_agent`.
    let confirmingElement: CheckoutController.ConfirmingElement
    /// All elements enabled in the Checkout configuration, including the confirming element,
    /// regardless of whether they were displayed or used. Populates CAM's `merchant_integration_additional_elements`.
    let configuredElements: [STPClientAttributionMetadata.AdditionalElement]
}

protocol CheckoutSessionPolling {
    func poll(checkoutSessionId: String, clientSecret: String) async -> CheckoutSessionPoller.Outcome
}

extension CheckoutSessionPoller: CheckoutSessionPolling {}

protocol CheckoutConfirmationChallenge {
    func makeRadarOptions(for paymentMethodType: STPPaymentMethodType) async -> STPRadarOptions?
    func complete() async
}

extension ConfirmationChallenge: CheckoutConfirmationChallenge {}

extension CheckoutController {
    /// The supported confirmation flows for a Checkout Session.
    enum CheckoutConfirmationFlow {
        case applePay(ApplePayConfirmationParameters)
        case link(LinkConfirmationParameters)
        case paymentMethod(PaymentMethodConfirmationParameters, preconfirmIntegrationShape: PaymentSheet.IntegrationShape)
        case withoutPaymentMethod(STPAuthenticationContext)
    }

    /// The parameters needed to confirm a Checkout Session with Apple Pay.
    struct ApplePayConfirmationParameters {
        typealias ConfirmationHandler = @MainActor (
            CheckoutSessionConfirmationRequestParameters
        ) async -> InternalConfirmResult

        let applePayConfiguration: any CheckoutApplePayConfiguration
        let apiClient: STPAPIClient
        let returnURL: String
        let merchantDisplayName: String
        let shippingAddressRequired: Bool
        let defaultBillingDetails: Configuration.Defaults.BillingDetails?
        let presentationWindow: UIWindow?
        // TODO: This should probably live with the other methods that delegate to CheckoutController
        // to update shipping, billing, etc., unless those methods end up living here too.
        let confirmationHandler: ConfirmationHandler
        let attribution: CheckoutAttributionContext
    }

    /// The parameters needed to confirm a Checkout Session with Link.
    struct LinkConfirmationParameters {

        // TODO: Lots of stuff in here because current Link code nominally requires it but it may not all really be necessary.
        let confirmOption: PaymentSheet.LinkConfirmOption
        let configuration: PaymentElementConfiguration
        let nativeSheetPresentation: SheetImplementationResolver?
        let confirmationChallenge: ConfirmationChallenge?
        let analyticsHelper: PaymentSheetAnalyticsHelper
        let authenticationContext: STPAuthenticationContext
        let paymentHandler: STPPaymentHandler
        let attribution: CheckoutAttributionContext
    }

    /// The parameters needed to confirm a Checkout Session with a new or saved payment method.
    struct PaymentMethodConfirmationParameters {

        enum Option {
            case new(IntentConfirmParams)
            case saved(STPPaymentMethod, IntentConfirmParams?)
        }

        let option: Option
        let configuration: PaymentElementConfiguration
        let nativeSheetPresentation: SheetImplementationResolver?
        let confirmationChallenge: (any CheckoutConfirmationChallenge)?
        let authenticationContext: STPAuthenticationContext
        let paymentHandler: STPPaymentHandler
        let attribution: CheckoutAttributionContext
    }

    /// Identifies which Checkout Elements component is confirming a Checkout Session, so
    /// `payment_user_agent` and client attribution metadata can identify the confirming element.
    /// Exactly one of these is chosen per confirmation attempt (set once in `makeConfirmationFlow(for:)`
    /// and `makeExpressCheckoutConfirmationFlow`), so `PaymentElement` and `ExpressCheckoutElement`
    /// never appear together in a single request's `payment_user_agent`.
    enum ConfirmingElement: String {
        case paymentElement = "mobile-payment-element"
        case expressCheckoutElement = "mobile-express-checkout-element"

        private var identifier: String {
            switch self {
            case .paymentElement:
                return PaymentElement.stp_analyticsIdentifier
            case .expressCheckoutElement:
                return ExpressCheckoutElement.stp_analyticsIdentifier
            }
        }

        /// A `payment_user_agent` built fresh for this element, independent of whatever classes
        /// (e.g. `PaymentSheet.FlowController`, `EmbeddedPaymentElement`) have registered into the
        /// global `STPAnalyticsClient.sharedClient.productUsage` set — so it's never contaminated
        /// by that set's contents, now or if `PaymentElement`/`ExpressCheckoutElement` themselves
        /// ever register into it too.
        var paymentUserAgent: String {
            PaymentsSDKVariant.paymentUserAgent(replacingProductUsageWith: [identifier])
        }
    }

    enum InternalConfirmResult {
        case completed(PaymentPagesAPIResponse)
        case canceled(sessionResponse: PaymentPagesAPIResponse? = nil)
        case failed(Error, sessionResponse: PaymentPagesAPIResponse? = nil)

        var paymentSheetResult: PaymentSheetResult {
            switch self {
            case .completed:
                return .completed
            case .canceled:
                return .canceled
            case .failed(let error, _):
                return .failed(error: error)
            }
        }

        var checkoutSessionResponse: PaymentPagesAPIResponse? {
            switch self {
            case .completed(let response):
                return response
            case .canceled(let response), .failed(_, let response):
                return response
            }
        }
    }

    // MARK: - Flow Construction

    func makeConfirmationFlow(
        for paymentElement: PaymentElement?,
        presentingViewController: UIViewController
    ) -> CheckoutConfirmationFlow? {
        let authenticationContext = AuthenticationContext(
            presentingViewController: presentingViewController,
            appearance: configuration.paymentElement?.appearance ?? .default
        )
        if session.paymentOption == nil {
            return .withoutPaymentMethod(authenticationContext)
        }

        guard let paymentElement else {
            logUnexpectedCheckoutElementsErrorAndAssert(
                "Checkout Session has a payment option without a PaymentElement.",
                apiClient: apiClient
            )
            return nil
        }

        let paymentOption: PaymentOption
        let configuration: PaymentElementConfiguration
        let nativeSheetPresentation: SheetImplementationResolver
        let integrationShape: PaymentSheet.IntegrationShape

        if paymentElement.paymentOptionSourceOfTruthIsFlowController {
            guard let resolvedPaymentOption = paymentElement.paymentSheetFlowController.internalPaymentOption else {
                logUnexpectedCheckoutElementsErrorAndAssert(
                    "Checkout Session payment option and FlowController payment option are out of sync.",
                    apiClient: apiClient
                )
                return nil
            }
            paymentOption = resolvedPaymentOption
            configuration = paymentElement.paymentSheetFlowController.configuration
            nativeSheetPresentation = paymentElement.paymentSheetFlowController.nativeSheetPresentation
            integrationShape = .flowController
        } else {
            guard let resolvedPaymentOption = paymentElement.embeddedPaymentElement._paymentOption else {
                logUnexpectedCheckoutElementsErrorAndAssert(
                    "Checkout Session payment option and EmbeddedPaymentElement payment option are out of sync.",
                    apiClient: apiClient
                )
                return nil
            }
            paymentOption = resolvedPaymentOption
            configuration = paymentElement.embeddedPaymentElement.configuration
            nativeSheetPresentation = paymentElement.embeddedPaymentElement.nativeSheetPresentation
            integrationShape = .embedded
        }

        let attribution = CheckoutAttributionContext(
            confirmingElement: .paymentElement,
            configuredElements: self.configuration.configuredElements
        )
        // Normalize Payment Element state here, then build the corresponding confirmation flow.
        switch paymentOption {
        case .applePay:
            guard let paymentElementConfiguration = self.configuration.paymentElement,
                  let applePayConfiguration = paymentElementConfiguration.applePayConfiguration else {
                return nil
            }
            return .applePay(.init(
                applePayConfiguration: applePayConfiguration,
                apiClient: apiClient,
                returnURL: self.configuration.returnURL,
                merchantDisplayName: effectiveMerchantDisplayName,
                shippingAddressRequired: false,
                defaultBillingDetails: self.configuration.defaults.billingDetails,
                presentationWindow: presentingViewController.view.window,
                confirmationHandler: { [apiClient, paymentHandler] requestParameters in
                    await Self.confirmCheckoutSession(
                        with: requestParameters,
                        apiClient: apiClient,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler
                    )
                },
                attribution: attribution
            ))
        case .link(let confirmOption):
            let analyticsHelper = paymentElement.paymentOptionSourceOfTruthIsFlowController
            ? paymentElement.paymentSheetFlowController.analyticsHelper
            : paymentElement.embeddedPaymentElement.analyticsHelper
            return .link(.init(
                confirmOption: confirmOption,
                configuration: configuration,
                nativeSheetPresentation: nativeSheetPresentation,
                confirmationChallenge: confirmationChallenge,
                analyticsHelper: analyticsHelper,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                attribution: attribution
            ))
        case .new(let confirmParams):
            return .paymentMethod(
                .init(
                    option: .new(confirmParams),
                    configuration: configuration,
                    nativeSheetPresentation: nativeSheetPresentation,
                    confirmationChallenge: confirmationChallenge,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    attribution: attribution
                ),
                preconfirmIntegrationShape: integrationShape
            )
        case .saved(let paymentMethod, let confirmParams):
            return .paymentMethod(
                .init(
                    option: .saved(paymentMethod, confirmParams),
                    configuration: configuration,
                    nativeSheetPresentation: nativeSheetPresentation,
                    confirmationChallenge: confirmationChallenge,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    attribution: attribution
                ),
                preconfirmIntegrationShape: integrationShape
            )
        case .external:
            // TODO: fatal error here so we can not reutrn nil
            return nil
        }
    }

    // MARK: - Confirmation

    func confirm(
        source: CheckoutControllerAnalyticsHelper.InvocationSource,
        makeFlow: () throws -> CheckoutConfirmationFlow
    ) async -> ConfirmResult {
        let flow = Result(catching: makeFlow)
        // Send confirm started analytic
        var analyticParams = confirmationAnalyticsParams(paymentOption: try? flow.get().analyticsPaymentOption, source: source)
        let startedAction = analyticsHelper.logStarted(.confirm, session: session, additionalParams: analyticParams)
        let internalResult: InternalConfirmResult
        // Do the actual confirm
        do {
            let flow = try flow.get()

            // Validations
            guard sessionIsOpen else {
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot confirm a Checkout Session that is no longer open.")
            }
            guard !confirmationInProgress else {
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot start a second confirmation while one is in progress.")
            }
            guard pendingOperations.isEmpty else {
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot confirm while the Checkout Session is updating. Wait until isUpdating is false.")
            }

            confirmationInProgress = true
            defer { confirmationInProgress = false }

            // 1. Put the confirm on the queue
            internalResult = try await enqueueSessionUpdate {
                // Switch based on the confirmation flow
                let result: InternalConfirmResult
                switch flow {
                case .withoutPaymentMethod(let authenticationContext):
                    let requestParameters = CheckoutSessionConfirmationRequestParameters.createWithoutPaymentMethod(
                        sessionId: self.session.id,
                        clientSecret: self.clientSecret,
                        // .withoutPaymentMethod only ever comes from makeConfirmationFlow(for: paymentElement:)
                        // — ExpressCheckoutElement's flow builder has no such case — so this is always PaymentElement.
                        confirmationSource: .paymentElement,
                        expectedAmount: self.session.amount,
                        returnURL: self.configuration.returnURL,
                        clientAttributionMetadata: STPClientAttributionMetadata.makeClientAttributionMetadata(
                            checkoutSession: self.session,
                            attribution: .init(confirmingElement: .paymentElement, configuredElements: self.configuration.configuredElements)
                        ),
                        // Due to legacy reasons, in the no-PM case /confirm requires customerData be sent with at least email
                        // TODO: Remove this once no-PM confirmation can use the Checkout Session's server email without `customer_data`.
                        customerData: self.session.email.map { ["email": $0] }
                    )
                    result = await Self.confirmCheckoutSession(
                        with: requestParameters,
                        apiClient: self.apiClient,
                        authenticationContext: authenticationContext,
                        paymentHandler: self.paymentHandler
                    )
                case .applePay(let parameters):
                    result = await self.confirmApplePay(checkoutSession: self.session, parameters: parameters)
                case .link(let parameters):
                    result = await Self.confirmLink(checkoutSession: self.session, parameters: parameters)
                case .paymentMethod(let paymentMethodParameters, let integrationShape):
                    // 2. Do pre-confirm actions (CVC recollection, etc)
                    if self.requiresSEPAMandate(for: paymentMethodParameters.option) {
                        let didAcceptMandate = await withCheckedContinuation { continuation in
                            SepaMandateViewController.present(
                                from: paymentMethodParameters.authenticationContext.authenticationPresentingViewController(),
                                configuration: paymentMethodParameters.configuration,
                                nativeSheetPresentation: paymentMethodParameters.nativeSheetPresentation,
                                checkoutSessionID: self.session.id
                            ) { didAcceptMandate in
                                continuation.resume(returning: didAcceptMandate)
                            }
                        }
                        guard didAcceptMandate else {
                            return InternalConfirmResult.canceled()
                        }
                    }
                    let preconfirmResult = await Self.handlePaymentMethodPreconfirmActions(
                        checkoutSession: self.session,
                        parameters: paymentMethodParameters,
                        preconfirmIntegrationShape: integrationShape
                    )
                    let paymentOptionsOverride: IntentConfirmParams?
                    switch preconfirmResult {
                    case .succeeded(let cvcRecollectionPaymentOptionsOverride):
                        paymentOptionsOverride = cvcRecollectionPaymentOptionsOverride
                    case .canceled:
                        return InternalConfirmResult.canceled()
                    case .failed(let error):
                        return InternalConfirmResult.failed(error)
                    }

                    // 3. Make /confirm parameters
                    let confirmRequestParameters = await Self.makeConfirmationRequestParameters(
                        for: paymentMethodParameters,
                        checkoutSession: self.session,
                        preconfirmedIntentParams: paymentOptionsOverride
                    )
                    // 4. Confirm the CheckoutSession
                    result = await Self.confirmCheckoutSession(
                        with: confirmRequestParameters,
                        apiClient: paymentMethodParameters.configuration.apiClient,
                        authenticationContext: paymentMethodParameters.authenticationContext,
                        paymentHandler: paymentMethodParameters.paymentHandler,
                        confirmationChallenge: confirmRequestParameters.paymentMethodData == nil ? nil : paymentMethodParameters.confirmationChallenge
                    )
                }
                // 3. Update the Session
                if let response = result.checkoutSessionResponse {
                    self.commitSession(response)
                }
                return result
            }
        } catch {
            internalResult = .failed(error)
        }
        // Send confirm finished analytic
        let result = Self.mapConfirmationResult(internalResult)
        analyticParams["active_link_session"] = LinkAccountContext.shared.account?.sessionState == .verified
        switch result {
        case .completed:
            analyticsHelper.logSucceeded(startedAction, session: session, additionalParams: analyticParams)
        case .canceled:
            analyticsHelper.logCanceled(startedAction, session: session, additionalParams: analyticParams)
        case .failed(let error):
            analyticsHelper.logFailed(startedAction, error: error, session: session, additionalParams: analyticParams)
        }
        return result
    }

    static func mapConfirmationResult(_ result: InternalConfirmResult) -> ConfirmResult {
        switch result {
        case .completed(let response):
            return .completed(paymentStatus: response.paymentStatus)
        case .canceled:
            return .canceled
        case .failed(let error, _):
            return .failed(error)
        }
    }

    // MARK: - Payment Method Confirmation

    func requiresSEPAMandate(for option: PaymentMethodConfirmationParameters.Option) -> Bool {
        guard case .saved(let paymentMethod, _) = option, paymentMethod.type == .SEPADebit else {
            return false
        }
        return paymentElement?.uiView.hasBeenAttachedToWindow != true
            && paymentElement?.paymentSheetFlowController.didPresentAndContinue != true
            && configuration.paymentElement?.displaysMandateText != false
    }

    static func handlePaymentMethodPreconfirmActions(
        checkoutSession: Session,
        parameters: PaymentMethodConfirmationParameters,
        preconfirmIntegrationShape: PaymentSheet.IntegrationShape
    ) async -> PaymentSheet.PreconfirmActionsResult {
        let paymentOption: PaymentOption
        switch parameters.option {
        case .new(let confirmParams):
            paymentOption = .new(confirmParams: confirmParams)
        case .saved(let paymentMethod, let confirmParams):
            paymentOption = .saved(paymentMethod: paymentMethod, confirmParams: confirmParams)
        }

        return await PaymentSheet.handlePreconfirmActionsIfNecessary(
            configuration: parameters.configuration,
            nativeSheetPresentation: parameters.nativeSheetPresentation,
            authenticationContext: parameters.authenticationContext,
            intent: .checkout(checkoutSession),
            paymentOption: paymentOption,
            paymentHandler: parameters.paymentHandler,
            integrationShape: preconfirmIntegrationShape,
            checkoutSessionID: checkoutSession.id
        )
    }

    static func makeConfirmationRequestParameters(
        for paymentMethodParameters: PaymentMethodConfirmationParameters,
        checkoutSession: Session,
        preconfirmedIntentParams: IntentConfirmParams?
    ) async -> CheckoutSessionConfirmationRequestParameters {
        let configuration = paymentMethodParameters.configuration
        let confirmationChallenge = paymentMethodParameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            checkoutSession: checkoutSession,
            attribution: paymentMethodParameters.attribution
        )

        switch paymentMethodParameters.option {
        case .new(let confirmParams):
            // MARK: - New PM
            let paymentMethodType = confirmParams.paymentMethodParams.type
            confirmParams.setAllowRedisplayForCheckoutSession(
                merchantWillSavePaymentMethod: checkoutSession.merchantWillSavePaymentMethod(paymentMethodType)
            )
            confirmParams.paymentMethodParams.radarOptions = await confirmationChallenge?.makeRadarOptions(for: confirmParams.paymentMethodParams.type)
            // Nested CAM attributes the PaymentMethodCreated event; top-level CAM links Checkout
            // confirmation events to the Elements session configuration. The backend reads each
            // copy independently, so keep both.
            confirmParams.paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
            let savePaymentMethod: Bool?
            switch confirmParams.saveForFutureUseCheckboxState {
            case .hidden:
                savePaymentMethod = nil
            case .deselected:
                savePaymentMethod = false
            case .selected:
                savePaymentMethod = true
            }
            return .createWithPaymentMethodData(
                sessionId: checkoutSession.id,
                clientSecret: checkoutSession.clientSecret,
                paymentMethodData: confirmParams.paymentMethodParams,
                confirmationSource: paymentMethodParameters.attribution.confirmingElement,
                expectedAmount: checkoutSession.amount,
                savePaymentMethod: checkoutSession.noPaymentRequired ? nil : savePaymentMethod,
                returnURL: configuration.returnURL,
                shipping: STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration),
                paymentMethodOptions: confirmParams.confirmPaymentMethodOptions,
                clientAttributionMetadata: clientAttributionMetadata,
                collectedInformation: .init(email: checkoutSession.localState.email)
            )
        case .saved(let savedPaymentMethod, let confirmParams):
            // MARK: - Saved PM
            let paymentMethodOptions = preconfirmedIntentParams?.confirmPaymentMethodOptions
                ?? confirmParams?.confirmPaymentMethodOptions
            return .createWithPaymentMethodID(
                sessionId: checkoutSession.id,
                clientSecret: checkoutSession.clientSecret,
                paymentMethodId: savedPaymentMethod.stripeId,
                confirmationSource: paymentMethodParameters.attribution.confirmingElement,
                expectedAmount: checkoutSession.amount,
                expectedPaymentMethodType: savedPaymentMethod.type.identifier,
                returnURL: configuration.returnURL,
                shipping: STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration),
                paymentMethodOptions: paymentMethodOptions,
                clientAttributionMetadata: clientAttributionMetadata,
                collectedInformation: .init(email: checkoutSession.localState.email)
            )
        }
    }

    // MARK: - Confirm Response Handling

    // TODO(CC migration): [1] Verify the deployed CC poll contract; the removed-field guards below need no replacement.
    // Timeout succeeds with the last server-reported Session state; not_started is an integration error.
    // Phase numbers follow CHECKOUT_CONFIRM_MIGRATION.md; update fixtures and tests alongside phases 2–5.
    /// Confirms a Checkout Session, handles any next action, and waits for confirmation to settle.
    @MainActor
    static func confirmCheckoutSession(
        with requestParameters: CheckoutSessionConfirmationRequestParameters,
        apiClient: STPAPIClient,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        confirmationChallenge: (any CheckoutConfirmationChallenge)? = nil,
        poller injectedPoller: (any CheckoutSessionPolling)? = nil
    ) async -> InternalConfirmResult {
        let poller: any CheckoutSessionPolling
        if let injectedPoller {
            poller = injectedPoller
        } else {
            poller = CheckoutSessionPoller(apiClient: apiClient)
        }

        // 1. Call /confirm
        // TODO: Scope Radar option creation and this request with confirmationChallenge.withRadarOptions(for:).
        // complete() is async, but the underlying AssertionHandle.complete() schedules rather than awaits release.
        let response: PaymentPagesAPIResponse
        do {
            response = try await apiClient.confirmCheckoutSession(with: requestParameters)
        } catch {
            await confirmationChallenge?.complete()
            return .failed(error)
        }
        // Release the assertion only after the request using it has finished, before handling next actions.
        await confirmationChallenge?.complete()

        // TODO(CC migration): [3] Remove this guard without reconstructing submission-attempt state.
        // PP only exposes submission_attempt for manual approval; CC does not expose it.
        // Ordinary card/CVC confirmation failures are API errors handled by the catch above.
        if response.submissionAttempt?.state == .failed {
            return .failed(paymentError(from: response), sessionResponse: response)
        }

        // Manual approval isn't supported yet
        // TODO(CC migration): [3] Remove this guard; CC does not expose manual-approval submission state.
        if response.submissionAttempt?.state == .requiresApproval {
            let error = CheckoutError.unknown(debugDescription: "Checkout Session confirmation unexpectedly requires manual approval.")
            return .failed(error, sessionResponse: response)
        }

        // Orchestration isn't supported yet
        // TODO(CC migration): [3] Remove this guard; CC normalizes orchestration into payment_response.
        // Handle supported next actions without trying to infer the internal routing choice.
        if response.routeToOrchestrationInterface == true {
            let error = CheckoutError.unknown(debugDescription: "Checkout Session confirmation unexpectedly requires orchestration.")
            return .failed(error, sessionResponse: response)
        }

        // 2. Handle any next action required by the Intent.
        // TODO(CC migration): [3] Use paymentResponse's PI/SI client-secret references with PaymentHandler, as in #7500.
        // Keep retrieved Intents local and preserve this Session response on retrieval/action failure or cancellation.
        let clientCompletedIntent: PaymentOrSetupIntent?
        if let paymentIntent = response.paymentIntent {
            let result: (STPPaymentHandlerActionStatus, STPPaymentIntent?, Error?) = await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: paymentIntent,
                    with: authenticationContext,
                    returnURL: requestParameters.returnURL
                ) { status, paymentIntent, error in
                    continuation.resume(returning: (status, paymentIntent, error))
                }
            }
            switch result.0 {
            case .succeeded:
                guard let paymentIntent = result.1 else {
                    let error = CheckoutError.unknown(debugDescription: "PaymentHandler completed without returning a PaymentIntent.")
                    return .failed(error, sessionResponse: response)
                }
                clientCompletedIntent = .paymentIntent(paymentIntent)
            case .canceled:
                return .canceled(sessionResponse: response)
            case .failed:
                let error = result.2 ?? PaymentSheetError.errorHandlingNextAction
                return .failed(error, sessionResponse: response)
            @unknown default:
                let error = CheckoutError.unknown(debugDescription: "PaymentHandler returned an unknown action status for a PaymentIntent.")
                return .failed(error, sessionResponse: response)
            }
        } else if let setupIntent = response.setupIntent {
            let result: (STPPaymentHandlerActionStatus, STPSetupIntent?, Error?) = await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: setupIntent,
                    with: authenticationContext,
                    returnURL: requestParameters.returnURL
                ) { status, setupIntent, error in
                    continuation.resume(returning: (status, setupIntent, error))
                }
            }
            switch result.0 {
            case .succeeded:
                guard let setupIntent = result.1 else {
                    let error = CheckoutError.unknown(debugDescription: "PaymentHandler completed without returning a SetupIntent.")
                    return .failed(error, sessionResponse: response)
                }
                clientCompletedIntent = .setupIntent(setupIntent)
            case .canceled:
                return .canceled(sessionResponse: response)
            case .failed:
                let error = result.2 ?? PaymentSheetError.errorHandlingNextAction
                return .failed(error, sessionResponse: response)
            @unknown default:
                let error = CheckoutError.unknown(debugDescription: "PaymentHandler returned an unknown action status for a SetupIntent.")
                return .failed(error, sessionResponse: response)
            }
        } else {
            clientCompletedIntent = nil
        }

        // 3. Poll if the Checkout Session is still in progress.
        // TODO(CC migration): [5] Consume the CC outcomes implemented in [4].
        // Keep this gate based on the original /confirm status, after successful next-action handling.
        var didPollToCompletion = false
        switch response.status {
        case .open:
            let pollOutcome = await poller.poll(
                checkoutSessionId: response.sessionId,
                clientSecret: requestParameters.clientSecret
            )
            switch pollOutcome {
            case .completed:
                didPollToCompletion = true
                // Continue to step 4.
            case .timedOut:
                // TODO(CC migration): [5] Return success with status/payment_status from the last successful poll.
                // If no poll succeeded, preserve /confirm fields. Never infer Session completion from the Intent.
                // Retain this explanation in the implementation: Like EwCS, we optimistically succeed on timeout.
                // We preserve the last server-reported Session state rather than calculate it from the Intent,
                // intentionally allowing Session status/payment_status to be stale in this edge case.
                // Continue to step 4.
                break
            case .requiresPaymentMethod,
                 .failedAsyncPayment:
                // TODO(CC migration): [5] Handle CC confirmation_status == failed and apply poll Session fields.
                // Poll has no confirmation_error; retrieve details best-effort with requestParameters.clientSecret.
                // If retrieval is rejected, retain the polled Session state and return a confirmation failure.
                let latestSession: PaymentPagesAPIResponse
                do {
                    latestSession = try await apiClient.retrieveCheckoutSession(
                        checkoutSessionId: response.sessionId
                    )
                } catch {
                    return .failed(error, sessionResponse: response)
                }

                // Update the local Session and return its last payment error, if available.
                let error = paymentError(from: latestSession)
                return .failed(error, sessionResponse: latestSession)
            case .invalidOrExpired:
                // TODO(CC migration): [5] Fold this into CC's failed outcome, using poll status to identify expiration.
                // If retrieving details, pass requestParameters.clientSecret; failure must not lose polled state.
                let latestSession: PaymentPagesAPIResponse
                do {
                    latestSession = try await apiClient.retrieveCheckoutSession(
                        checkoutSessionId: response.sessionId
                    )
                } catch {
                    return .failed(error, sessionResponse: response)
                }

                // Update the local Session and return an unexpected confirmation error.
                let error = CheckoutError.unknown(debugDescription: "Checkout Session unexpectedly became invalid or expired during polling.")
                return .failed(error, sessionResponse: latestSession)
            }
        case .complete:
            // Continue to step 4 without polling.
            break
        case .expired:
            // The confirm response should only be open or complete.
            return .failed(CheckoutError.unknown(debugDescription: "Checkout Session unexpectedly expired after confirmation."), sessionResponse: response)
        }

        // 4. Hackily update the PaymentPages response `status` and `payment_status` based on the `/confirm` response and client-completed Intent.
        // Unfortunately, this logic has to live on the client today. The /retrieve endpoint 400s for completed Checkout Sessions.
        // TODO(CC migration): [5] Use the last server-reported status/payment_status, including on timeout.
        // Update both typed fields consistently (Status embeds PaymentStatus); stop adding expanded Intent fields.
        // Preserve /confirm fields when no poll succeeded; remove all Intent-based Session status inference.
        do {
            var responseFields = response.allResponseFields

            // PaymentHandler already verified that the Intent is client-complete. Only update
            // Session fields we can derive from the newer Intent; otherwise preserve `/confirm`.
            switch clientCompletedIntent {
            case nil:
                if didPollToCompletion {
                    responseFields["status"] = "complete"
                }
            case .paymentIntent(let paymentIntent):
                responseFields["payment_intent"] = paymentIntent.allResponseFields
                switch paymentIntent.status {
                case .succeeded:
                    responseFields["status"] = "complete"
                    responseFields["payment_status"] = "paid"
                case .processing:
                    responseFields["status"] = "complete"
                default:
                    break
                }
            case .setupIntent(let setupIntent):
                responseFields["setup_intent"] = setupIntent.allResponseFields
                switch setupIntent.status {
                case .succeeded:
                    responseFields["status"] = "complete"
                default:
                    break
                }
            }

            let data = try JSONSerialization.data(withJSONObject: responseFields)
            let updatedResponse = try StripeJSONDecoder().decode(PaymentPagesAPIResponse.self, from: data)
            return .completed(updatedResponse)
        } catch {
            return .failed(error, sessionResponse: response)
        }
    }

    private static func paymentError(from session: PaymentPagesAPIResponse) -> Error {
        // TODO(CC migration): [3] Read paymentResponse.lastPaymentError for either PI or SI; keep the generic fallback.
        let lastErrorFields = session.paymentIntent?.lastPaymentError?.allResponseFields
            ?? session.setupIntent?.lastSetupError?.allResponseFields
        return NSError.stp_error(fromStripeResponse: lastErrorFields.map { ["error": $0] })
            ?? PaymentSheetError.errorHandlingNextAction
    }

}
