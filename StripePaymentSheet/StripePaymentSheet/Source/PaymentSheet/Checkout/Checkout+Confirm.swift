@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - Types

protocol CheckoutSessionPolling {
    func poll(checkoutSessionId: String) async -> CheckoutSessionPoller.Outcome
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
        let confirmationSource: ConfirmingElement
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
        let confirmationSource: ConfirmingElement
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
        let confirmationSource: ConfirmingElement
    }

    /// Identifies which Checkout Elements component is confirming a Checkout Session, so
    /// `payment_user_agent` can carry an unambiguous label for payment/attribution purposes.
    /// Exactly one of these is chosen per confirmation attempt (set once in `makeConfirmationFlow(for:)`
    /// and `makeExpressCheckoutConfirmationFlow`), so `PaymentElement` and `ExpressCheckoutElement`
    /// never appear together in a single request's `payment_user_agent`.
    enum ConfirmingElement {
        case paymentElement
        case expressCheckoutElement

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
                confirmationSource: .paymentElement
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
                confirmationSource: .paymentElement
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
                    confirmationSource: .paymentElement
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
                    confirmationSource: .paymentElement
                ),
                preconfirmIntegrationShape: integrationShape
            )
        case .external:
            // TODO: fatal error here so we can not reutrn nil
            return nil
        }
    }

    // MARK: - Confirmation

    func confirm(_ flow: CheckoutConfirmationFlow) async -> ConfirmResult {
        // Validations
        guard sessionIsOpen else {
            let error = PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot confirm a Checkout Session that is no longer open.")
            return .failed(error)
        }
        guard !confirmationInProgress else {
            let error = PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot start a second confirmation while one is in progress.")
            return .failed(error)
        }
        guard pendingOperations.isEmpty else {
            let error = PaymentSheetError.integrationError(nonPIIDebugDescription: "CheckoutController cannot confirm while the Checkout Session is updating. Wait until isUpdating is false.")
            return .failed(error)
        }

        confirmationInProgress = true
        defer { confirmationInProgress = false }

        do {
            // 1. Put the confirm on the queue
            let result = try await enqueueSessionUpdate {
                // Switch based on the confirmation flow
                let result: InternalConfirmResult
                switch flow {
                case .withoutPaymentMethod(let authenticationContext):
                    let requestParameters = CheckoutSessionConfirmationRequestParameters.createWithoutPaymentMethod(
                        sessionId: self.session.id,
                        // .withoutPaymentMethod only ever comes from makeConfirmationFlow(for: paymentElement:)
                        // — ExpressCheckoutElement's flow builder has no such case — so this is always PaymentElement.
                        confirmationSource: .paymentElement,
                        expectedAmount: self.session.amount,
                        returnURL: self.configuration.returnURL,
                        clientAttributionMetadata: STPClientAttributionMetadata.makeClientAttributionMetadata(
                            intent: .checkout(self.session),
                            elementsSession: self.session.elementsSession
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
                                nativeSheetPresentation: paymentMethodParameters.nativeSheetPresentation
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
            return Self.mapConfirmationResult(result)
        } catch {
            return .failed(error)
        }
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
            integrationShape: preconfirmIntegrationShape
        )
    }

    static func makeConfirmationRequestParameters(
        for paymentMethodParameters: PaymentMethodConfirmationParameters,
        checkoutSession: Session,
        preconfirmedIntentParams: IntentConfirmParams?
    ) async -> CheckoutSessionConfirmationRequestParameters {
        let elementsSession = checkoutSession.elementsSession
        let configuration = paymentMethodParameters.configuration
        let confirmationChallenge = paymentMethodParameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: elementsSession
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
                paymentMethodData: confirmParams.paymentMethodParams,
                confirmationSource: paymentMethodParameters.confirmationSource,
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
                paymentMethodId: savedPaymentMethod.stripeId,
                confirmationSource: paymentMethodParameters.confirmationSource,
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

        if response.submissionAttempt?.state == .failed {
            return .failed(paymentError(from: response), sessionResponse: response)
        }

        // Manual approval isn't supported yet
        if response.submissionAttempt?.state == .requiresApproval {
            let error = CheckoutError.unknown(debugDescription: "Checkout Session confirmation unexpectedly requires manual approval.")
            return .failed(error, sessionResponse: response)
        }

        // Orchestration isn't supported yet
        if response.routeToOrchestrationInterface == true {
            let error = CheckoutError.unknown(debugDescription: "Checkout Session confirmation unexpectedly requires orchestration.")
            return .failed(error, sessionResponse: response)
        }

        // 2. Handle any next action required by the Intent.
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
        var didPollToCompletion = false
        switch response.status {
        case .open:
            let pollOutcome = await poller.poll(checkoutSessionId: response.sessionId)
            switch pollOutcome {
            case .completed:
                didPollToCompletion = true
                // Continue to step 4.
            case .timedOut:
                // Continue to step 4.
                break
            case .requiresPaymentMethod,
                 .failedAsyncPayment:
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
        let lastErrorFields = session.paymentIntent?.lastPaymentError?.allResponseFields
            ?? session.setupIntent?.lastSetupError?.allResponseFields
        return NSError.stp_error(fromStripeResponse: lastErrorFields.map { ["error": $0] })
            ?? PaymentSheetError.errorHandlingNextAction
    }

}
