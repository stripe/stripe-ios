@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - Types

extension CheckoutController {
    /// The supported confirmation flows for a Checkout Session.
    enum CheckoutConfirmationFlow {
        case applePay(ApplePayConfirmationParameters)
        case link(LinkConfirmationParameters)
        case paymentMethod(PaymentMethodConfirmationParameters, preconfirmIntegrationShape: PaymentSheet.IntegrationShape)
    }

    /// The parameters needed to confirm a Checkout Session with Apple Pay.
    struct ApplePayConfirmationParameters {
        let applePayConfiguration: any CheckoutApplePayConfiguration
        let apiClient: STPAPIClient
        let returnURL: String
        let merchantDisplayName: String
        let billingDetailsCollectionConfiguration: any CheckoutBillingDetailsCollectionConfiguration
        let defaultBillingDetails: Configuration.Defaults.BillingDetails?
        let presentationWindow: UIWindow?
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

    func confirmationFlow(
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
            guard let applePayConfiguration = self.configuration.applePayConfiguration else { return nil }
            return .applePay(.init(
                applePayConfiguration: applePayConfiguration,
                apiClient: apiClient,
                returnURL: self.configuration.returnURL,
                merchantDisplayName: effectiveMerchantDisplayName,
                billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration,
                defaultBillingDetails: self.configuration.defaults.billingDetails,
                presentationWindow: presentingViewController.view.window
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
            return .failed(
                PaymentSheetError.integrationError(
                    nonPIIDebugDescription: "CheckoutController cannot confirm a Checkout Session that is no longer open."
                )
            )
        }
        guard !confirmationInProgress else {
            return .failed(
                PaymentSheetError.integrationError(
                    nonPIIDebugDescription: "CheckoutController cannot start a second confirmation while one is in progress."
                )
            )
        }
        guard pendingOperations.isEmpty else {
            return .failed(
                PaymentSheetError.integrationError(
                    nonPIIDebugDescription: "CheckoutController cannot confirm while the Checkout Session is updating. Wait until isUpdating is false."
                )
            )
        }

        confirmationInProgress = true
        defer { confirmationInProgress = false }

        do {
            // 1. Put the confirm on the queue
            let result = try await enqueueSessionUpdate {
                // 2. Do the confirmation
                let result: InternalConfirmResult
                switch flow {
                case .applePay(let parameters):
                    result = await Self.confirmApplePay(checkoutSession: self.session, parameters: parameters)
                case .link(let parameters):
                    result = await Self.confirmLink(checkoutSession: self.session, parameters: parameters)
                case .paymentMethod(let parameters, let integrationShape):
                    result = await Self.confirmPaymentMethod(
                        checkoutSession: self.session,
                        parameters: parameters,
                        preconfirmIntegrationShape: integrationShape
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
            return mapConfirmationResult(result)
        } catch {
            return .failed(error)
        }
    }

    func mapConfirmationResult(_ result: InternalConfirmResult) -> ConfirmResult {
        switch result {
        case .completed(let response):
            return .succeeded(paymentStatus: response.paymentStatus)
        case .canceled:
            return .canceled
        case .failed(let error, _):
            return .failed(error)
        }
    }

    // MARK: - Payment Method Confirmation

    static func confirmPaymentMethod(
        checkoutSession: Session,
        parameters: PaymentMethodConfirmationParameters,
        preconfirmIntegrationShape: PaymentSheet.IntegrationShape
    ) async -> InternalConfirmResult {
        let paymentOption: PaymentOption
        switch parameters.option {
        case .new(let confirmParams):
            paymentOption = .new(confirmParams: confirmParams)
        case .saved(let paymentMethod, let confirmParams):
            paymentOption = .saved(paymentMethod: paymentMethod, confirmParams: confirmParams)
        }

        let preconfirmActionsResult = await PaymentSheet.handlePreconfirmActionsIfNecessary(
            configuration: parameters.configuration,
            authenticationContext: parameters.authenticationContext,
            intent: .checkout(checkoutSession),
            paymentOption: paymentOption,
            paymentHandler: parameters.paymentHandler,
            integrationShape: preconfirmIntegrationShape
        )

        let intentConfirmParams: IntentConfirmParams?
        switch preconfirmActionsResult {
        case .succeeded(let params):
            intentConfirmParams = params
        case .canceled:
            return .canceled()
        case .failed(let error):
            return .failed(error)
        }

        return await confirmPaymentMethodOption(
            checkoutSession: checkoutSession,
            parameters: parameters,
            intentConfirmParamsForDeferredIntent: intentConfirmParams,
        )
    }

    static func confirmPaymentMethodOption(
        checkoutSession: Session,
        parameters: PaymentMethodConfirmationParameters,
        intentConfirmParamsForDeferredIntent: IntentConfirmParams?
    ) async -> InternalConfirmResult {
        let elementsSession = checkoutSession.elementsSession
        let configuration = parameters.configuration
        let confirmationChallenge = parameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: elementsSession
        )

        switch parameters.option {
        case .new(let confirmParams):
            // MARK: - New PM
            let paymentMethodType = confirmParams.paymentMethodParams.type
            confirmParams.setAllowRedisplayForCheckoutSession(
                merchantWillSavePaymentMethod: checkoutSession.merchantWillSavePaymentMethod(paymentMethodType)
            )
            confirmParams.paymentMethodParams.radarOptions = await confirmationChallenge?.makeRadarOptions(for: confirmParams.paymentMethodParams.type)
            confirmParams.paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
            let result = await Self.handleCheckoutSessionConfirmation(
                checkoutSession: checkoutSession,
                confirmType: .new(
                    params: confirmParams.paymentMethodParams,
                    paymentOptions: confirmParams.confirmPaymentMethodOptions,
                    saveForFutureUseCheckboxState: confirmParams.saveForFutureUseCheckboxState,
                    shouldSetAsDefaultPM: confirmParams.setAsDefaultPM
                ),
                configuration: configuration,
                authenticationContext: parameters.authenticationContext,
                paymentHandler: parameters.paymentHandler,
                elementsSession: elementsSession
            )
            await confirmationChallenge?.complete()
            return result

        case .saved(let paymentMethod, let confirmParams):
            // MARK: - Saved PM
            let paymentOptions = intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions != nil
            ? intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions
            : confirmParams?.confirmPaymentMethodOptions
            let result = await Self.handleCheckoutSessionConfirmation(
                checkoutSession: checkoutSession,
                confirmType: .saved(
                    paymentMethod,
                    paymentOptions: paymentOptions,
                    clientAttributionMetadata: clientAttributionMetadata,
                    radarOptions: nil
                ),
                configuration: configuration,
                authenticationContext: parameters.authenticationContext,
                paymentHandler: parameters.paymentHandler,
                elementsSession: elementsSession
            )
            return result
        }
    }

    /// Confirms a checkout session with a new payment method
    @MainActor
    static func handleCheckoutSessionConfirmation(
        checkoutSession: CheckoutController.Session,
        confirmType: PaymentSheet.ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        elementsSession: STPElementsSession
    ) async -> InternalConfirmResult {
        do {
            let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                intent: .checkout(checkoutSession),
                elementsSession: elementsSession
            )

            // 1. Get or create payment method
            let paymentMethod: STPPaymentMethod
            let paymentMethodType: STPPaymentMethodType
            let paymentMethodOptions: STPConfirmPaymentMethodOptions?
            switch confirmType {
            case let .new(params, paymentOptions, newPaymentMethod, _, _):
                if let newPaymentMethod {
                    let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError,
                                                      error: PaymentSheetError.unexpectedNewPaymentMethod,
                                                      additionalNonPIIParams: ["payment_method_type": newPaymentMethod.type])
                    STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                }
                stpAssert(newPaymentMethod == nil, "newPaymentMethod should be nil when confirming with a new payment method; the payment method is created from params.")
                paymentMethodType = params.type
                paymentMethodOptions = paymentOptions
                params.clientAttributionMetadata = clientAttributionMetadata
                // Ensure email is set on the payment method — fall back to the checkout session's customer email
                if params.billingDetails?.email == nil, let customerEmail = checkoutSession.email {
                    params.nonnil_billingDetails.email = customerEmail
                }
                paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params)
            case let .saved(savedPaymentMethod, paymentOptions, _, _):
                paymentMethod = savedPaymentMethod
                paymentMethodType = paymentMethod.type
                paymentMethodOptions = paymentOptions
            }

            // 2. Get expected amount and save_payment_method from checkout session
            let expectedAmount = checkoutSession.expectedAmount()
            let savePaymentMethod: Bool? = {
                guard !checkoutSession.noPaymentRequired else { return nil }
                return confirmType.savePaymentMethodForCheckoutSession
            }()

            // 3. Call confirm API
            let response = try await configuration.apiClient.confirmCheckoutSession(
                sessionId: checkoutSession.id,
                paymentMethod: paymentMethod.stripeId,
                expectedAmount: expectedAmount,
                expectedPaymentMethodType: paymentMethodType.identifier,
                savePaymentMethod: savePaymentMethod,
                returnURL: configuration.returnURL,
                shipping: makeCheckoutSessionShippingParams(configuration: configuration),
                paymentMethodOptions: paymentMethodOptions,
                clientAttributionMetadata: clientAttributionMetadata
            )

            // 4. Handle the intent returned by the confirm response.
            let paymentSheetResult = try await handleCheckoutSessionConfirmResponse(
                response: response,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
            switch paymentSheetResult {
            case .completed:
                return .completed(response)
            case .canceled:
                return .canceled(sessionResponse: response)
            case .failed(let error):
                return .failed(error, sessionResponse: response)
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Confirm Response Handling

    @MainActor
    private static func handleCheckoutSessionConfirmResponse(
        response: PaymentPagesAPIResponse,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async throws -> PaymentSheetResult {
        if let setupIntent = response.setupIntent {
            return await handleCheckoutSessionSetupIntentResponse(
                setupIntent: setupIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else if let paymentIntent = response.paymentIntent {
            return await handleCheckoutSessionPaymentIntentResponse(
                paymentIntent: paymentIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else {
            throw PaymentSheetError.unknown(
                debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent"
            )
        }
    }

    @MainActor
    private static func handleCheckoutSessionPaymentIntentResponse(
        paymentIntent: STPPaymentIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: paymentIntent,
                with: authenticationContext,
                returnURL: configuration.returnURL
            ) { status, _, error in
                continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    @MainActor
    private static func handleCheckoutSessionSetupIntentResponse(
        setupIntent: STPSetupIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: setupIntent,
                with: authenticationContext,
                returnURL: configuration.returnURL
            ) { status, _, error in
                continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    // MARK: - Helpers

    private static func makeCheckoutSessionShippingParams(configuration: PaymentElementConfiguration) -> STPPaymentIntentShippingDetailsParams? {
        return STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
    }
}
