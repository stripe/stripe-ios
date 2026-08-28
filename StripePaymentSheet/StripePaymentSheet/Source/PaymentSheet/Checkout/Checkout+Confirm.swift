@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - Types

protocol CheckoutSessionPolling {
    func poll(checkoutSessionId: String) async -> CheckoutSessionPoller.Outcome
}

extension CheckoutSessionPoller: CheckoutSessionPolling {}

extension CheckoutController {
    /// The supported confirmation flows for a Checkout Session.
    enum CheckoutConfirmationFlow {
        case applePay(ApplePayConfirmationParameters)
        case link(LinkConfirmationParameters)
        case paymentMethod(PaymentMethodConfirmationParameters, preconfirmIntegrationShape: PaymentSheet.IntegrationShape)
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
        let billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration
        let defaultBillingDetails: Configuration.Defaults.BillingDetails?
        let presentationWindow: UIWindow?
        // TODO: This should probably live with the other methods that delegate to CheckoutController
        // to update shipping, billing, etc., unless those methods end up living here too.
        let confirmationHandler: ConfirmationHandler
    }

    /// The parameters needed to confirm a Checkout Session with Link.
    struct LinkConfirmationParameters {
        // TODO: Lots of stuff in here because current Link code nominally requires it but it may not all really be necessary.
        let confirmOption: PaymentSheet.LinkConfirmOption
        let configuration: PaymentElementConfiguration
        let confirmationChallenge: ConfirmationChallenge?
        let analyticsHelper: PaymentSheetAnalyticsHelper
        let authenticationContext: STPAuthenticationContext
        let paymentHandler: STPPaymentHandler
    }

    /// The parameters needed to confirm a Checkout Session with a new or saved payment method.
    struct PaymentMethodConfirmationParameters {
        enum Option {
            case new(IntentConfirmParams)
            case saved(STPPaymentMethod, IntentConfirmParams?)
        }

        let option: Option
        let configuration: PaymentElementConfiguration
        let confirmationChallenge: ConfirmationChallenge?
        let authenticationContext: STPAuthenticationContext
        let paymentHandler: STPPaymentHandler
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
        for paymentElement: PaymentElement,
        presentingViewController: UIViewController
    ) -> CheckoutConfirmationFlow? {
        let paymentOption: PaymentOption
        let configuration: PaymentElementConfiguration
        let integrationShape: PaymentSheet.IntegrationShape
        let confirmationChallenge: ConfirmationChallenge?

        if paymentElement.paymentOptionSourceOfTruthIsFlowController {
            guard let resolvedPaymentOption = paymentElement.paymentSheetFlowController.internalPaymentOption else {
                return nil
            }
            paymentOption = resolvedPaymentOption
            configuration = paymentElement.paymentSheetFlowController.configuration
            integrationShape = .flowController
            confirmationChallenge = paymentElement.paymentSheetFlowController.confirmationChallenge
        } else {
            guard let resolvedPaymentOption = paymentElement.embeddedPaymentElement._paymentOption else {
                return nil
            }
            paymentOption = resolvedPaymentOption
            configuration = paymentElement.embeddedPaymentElement.configuration
            integrationShape = .embedded
            confirmationChallenge = paymentElement.embeddedPaymentElement.confirmationChallenge
        }

        let authenticationContext = AuthenticationContext(
            presentingViewController: presentingViewController,
            appearance: configuration.appearance
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
                billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration,
                defaultBillingDetails: self.configuration.defaults.billingDetails,
                presentationWindow: presentingViewController.view.window,
                confirmationHandler: { [apiClient, paymentHandler] requestParameters in
                    await Self.confirmCheckoutSession(
                        with: requestParameters,
                        apiClient: apiClient,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler
                    )
                }
            ))
        case .link(let confirmOption):
            let analyticsHelper = paymentElement.paymentOptionSourceOfTruthIsFlowController
            ? paymentElement.paymentSheetFlowController.analyticsHelper
            : paymentElement.embeddedPaymentElement.analyticsHelper
            return .link(.init(
                confirmOption: confirmOption,
                configuration: configuration,
                confirmationChallenge: confirmationChallenge,
                analyticsHelper: analyticsHelper,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            ))
        case .new(let confirmParams):
            return .paymentMethod(
                .init(
                    option: .new(confirmParams),
                    configuration: configuration,
                    confirmationChallenge: confirmationChallenge,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler
                ),
                preconfirmIntegrationShape: integrationShape
            )
        case .saved(let paymentMethod, let confirmParams):
            return .paymentMethod(
                .init(
                    option: .saved(paymentMethod, confirmParams),
                    configuration: configuration,
                    confirmationChallenge: confirmationChallenge,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler
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
                case .applePay(let parameters):
                    result = await Self.confirmApplePay(checkoutSession: self.session, parameters: parameters, checkoutWalletUpdater: self)
                case .link(let parameters):
                    result = await Self.confirmLink(checkoutSession: self.session, parameters: parameters)
                case .paymentMethod(let paymentMethodParameters, let integrationShape):
                    // 2. Do pre-confirm actions (CVC recollection, etc)
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
                    let confirmRequestParameters = try await Self.makeConfirmationRequestParameters(
                        for: paymentMethodParameters,
                        checkoutSession: self.session,
                        preconfirmedIntentParams: paymentOptionsOverride
                    )
                    // 4. Confirm the CheckoutSession
                    result = await Self.confirmCheckoutSession(
                        with: confirmRequestParameters,
                        apiClient: paymentMethodParameters.configuration.apiClient,
                        authenticationContext: paymentMethodParameters.authenticationContext,
                        paymentHandler: paymentMethodParameters.paymentHandler
                    )
                }
                // 3. Update the Session
                if let response = result.checkoutSessionResponse {
                    do {
                        // TODO: This doesn't need to and should never actually throw
                        try await self.commitSession(response)
                    } catch {
                        stpAssertionFailure("commit session should never fail")
                        STPAnalyticsClient.sharedClient.log(
                            analytic: ErrorAnalytic(event: .unexpectedCheckoutElementsError, error: error)
                        )
                        throw error
                    }
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
    ) async throws -> CheckoutSessionConfirmationRequestParameters {
        let elementsSession = checkoutSession.elementsSession
        let configuration = paymentMethodParameters.configuration
        let confirmationChallenge = paymentMethodParameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: elementsSession
        )

        let shouldCompleteConfirmationChallenge: Bool = {
            if case .new = paymentMethodParameters.option {
                return true
            }
            return false
        }()
        defer {
            // TODO: When we stop making a PM, make sure to call this after the CS /confirm
            // But also, this `complete` API is broken; it is async but does not actually await anything :/
            // But we should really make a helper like:
            // try await confirmationChallenge.withRadarOptions(for: type) { radarOptions in
            //     // Make the network request using radarOptions.
            // }
            if shouldCompleteConfirmationChallenge {
                Task {
                    await confirmationChallenge?.complete()
                }
            }
        }

        switch paymentMethodParameters.option {
        case .new(let confirmParams):
            // MARK: - New PM
            let paymentMethodType = confirmParams.paymentMethodParams.type
            confirmParams.setAllowRedisplayForCheckoutSession(
                merchantWillSavePaymentMethod: checkoutSession.merchantWillSavePaymentMethod(paymentMethodType)
            )
            confirmParams.paymentMethodParams.radarOptions = await confirmationChallenge?.makeRadarOptions(for: confirmParams.paymentMethodParams.type)
            // TODO: Why set client attribution metadata here and also in /confirm request?
            confirmParams.paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
            // Ensure email is set on the payment method — fall back to the Checkout Session's customer email.
            if confirmParams.paymentMethodParams.billingDetails?.email == nil,
               let customerEmail = checkoutSession.email {
                confirmParams.paymentMethodParams.nonnil_billingDetails.email = customerEmail
            }
            // TODO: Stop creating a PaymentMethod and send payment_method_data directly to /confirm.
            let paymentMethod = try await configuration.apiClient.createPaymentMethod(
                with: confirmParams.paymentMethodParams
            )
            let savePaymentMethod: Bool?
            switch confirmParams.saveForFutureUseCheckboxState {
            case .hidden:
                savePaymentMethod = nil
            case .deselected:
                savePaymentMethod = false
            case .selected:
                savePaymentMethod = true
            }
            return CheckoutSessionConfirmationRequestParameters(
                checkoutSession: checkoutSession,
                paymentMethod: paymentMethod,
                configuration: configuration,
                paymentMethodOptions: confirmParams.confirmPaymentMethodOptions,
                savePaymentMethod: savePaymentMethod,
                clientAttributionMetadata: clientAttributionMetadata
            )
        case .saved(let savedPaymentMethod, let confirmParams):
            // MARK: - Saved PM
            let paymentMethodOptions = preconfirmedIntentParams?.confirmPaymentMethodOptions
                ?? confirmParams?.confirmPaymentMethodOptions
            return CheckoutSessionConfirmationRequestParameters(
                checkoutSession: checkoutSession,
                paymentMethod: savedPaymentMethod,
                configuration: configuration,
                paymentMethodOptions: paymentMethodOptions,
                savePaymentMethod: nil,
                clientAttributionMetadata: clientAttributionMetadata
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
        poller injectedPoller: (any CheckoutSessionPolling)? = nil
    ) async -> InternalConfirmResult {
        let poller: any CheckoutSessionPolling
        if let injectedPoller {
            poller = injectedPoller
        } else {
            poller = CheckoutSessionPoller(apiClient: apiClient)
        }

        // 1. Call /confirm
        let response: PaymentPagesAPIResponse
        do {
            response = try await apiClient.confirmCheckoutSession(with: requestParameters)
        } catch {
            return .failed(error)
        }

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
        let clientCompletedIntent: PaymentOrSetupIntent
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
            let error = CheckoutError.unknown(debugDescription: "Checkout Session confirm response contained neither a PaymentIntent nor a SetupIntent.")
            return .failed(error, sessionResponse: response)
        }

        // 3. Poll if the Checkout Session is still in progress.
        switch response.status {
        case .open:
            let pollOutcome = await poller.poll(checkoutSessionId: response.sessionId)
            switch pollOutcome {
            case .completed,
                 .timedOut:
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
