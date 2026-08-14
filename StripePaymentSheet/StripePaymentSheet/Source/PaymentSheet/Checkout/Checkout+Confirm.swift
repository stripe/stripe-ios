@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

// MARK: - CheckoutApplePayDataSource

/// Convenience bag of everything Apple Pay needs for confirmation
@MainActor
protocol CheckoutApplePayDataSource: AnyObject {
    var applePayConfiguration: Checkout.ApplePayConfiguration? { get }
    var apiClient: STPAPIClient { get }
    var returnURL: String? { get }
    var merchantDisplayName: String { get }
    var expressCheckoutElementBillingDetailsCollectionConfiguration: ExpressCheckoutElement.Configuration.BillingDetailsCollectionConfiguration { get }
    func commitSession(_ response: PaymentPagesAPIResponse) async throws
}

extension Checkout: CheckoutApplePayDataSource {
    var applePayConfiguration: ApplePayConfiguration? { configuration.applePayConfiguration }
    var returnURL: String? { configuration.returnURL }
    var merchantDisplayName: String { effectiveMerchantDisplayName }
    var expressCheckoutElementBillingDetailsCollectionConfiguration: ExpressCheckoutElement.Configuration.BillingDetailsCollectionConfiguration {
        configuration.expressCheckoutElement.billingDetailsCollectionConfiguration
    }
}

// MARK: - Confirm

extension Checkout {
    /// Convenience bag of params needed for confirmation
    struct ConfirmationContext {
        let paymentOption: PaymentOption
        let configuration: PaymentElementConfiguration
        let integrationShape: PaymentSheet.IntegrationShape
        let confirmationChallenge: ConfirmationChallenge?
        let analyticsHelper: PaymentSheetAnalyticsHelper
    }

    struct InternalConfirmResult {
        let paymentSheetResult: PaymentSheetResult
        let checkoutSessionResponse: PaymentPagesAPIResponse?

        init(
            paymentSheetResult: PaymentSheetResult,
            checkoutSessionResponse: PaymentPagesAPIResponse? = nil
        ) {
            self.paymentSheetResult = paymentSheetResult
            self.checkoutSessionResponse = checkoutSessionResponse
        }
    }

    func confirmationContext(for paymentElement: PaymentElement) -> ConfirmationContext? {
        if paymentElement.paymentOptionSourceOfTruthIsFlowController {
            guard let paymentOption = paymentElement.paymentSheetFlowController.internalPaymentOption else {
                return nil
            }
            return ConfirmationContext(
                paymentOption: paymentOption,
                configuration: paymentElement.paymentSheetFlowController.configuration,
                integrationShape: .flowController,
                confirmationChallenge: paymentElement.paymentSheetFlowController.confirmationChallenge,
                analyticsHelper: paymentElement.paymentSheetFlowController.analyticsHelper
            )
        }

        guard let paymentOption = paymentElement.embeddedPaymentElement._paymentOption else {
            return nil
        }
        return ConfirmationContext(
            paymentOption: paymentOption,
            configuration: paymentElement.embeddedPaymentElement.configuration,
            integrationShape: .embedded,
            confirmationChallenge: paymentElement.embeddedPaymentElement.confirmationChallenge,
            analyticsHelper: paymentElement.embeddedPaymentElement.analyticsHelper
        )
    }

    func confirmationContext(for paymentMethod: ExpressCheckoutElement.PaymentMethod) -> ConfirmationContext {
        // TODO: Link Payment Element Configuration
        let paymentConfiguration = PaymentSheet.Configuration()
        switch paymentMethod {
        case .applePay:
            return ConfirmationContext(
                paymentOption: .applePay,
                configuration: paymentConfiguration,
                integrationShape: .expressCheckout,
                confirmationChallenge: nil, // Apple Pay is not a Card Testing attack vector
                analyticsHelper: PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: paymentConfiguration)
            )
        case .link:
            return ConfirmationContext(
                paymentOption: .link(option: .wallet(brand: session.elementsSession.linkBrand ?? .link)),
                configuration: paymentConfiguration,
                integrationShape: .expressCheckout,
                confirmationChallenge: ConfirmationChallenge(elementsSession: session.elementsSession, stripeAttest: apiClient.stripeAttest),
                analyticsHelper: PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: paymentConfiguration) // TODO: figure out ECE analytics plan
            )
        }
    }

    static func confirm(
        checkoutSession: Checkout.Session,
        confirmationContext: ConfirmationContext,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        checkoutApplePayDataSource: CheckoutApplePayDataSource
    ) async -> InternalConfirmResult {
        // 1. Handle pre-confirm actions, such as Bacs mandate acceptance or saved-card CVC recollection.
        let preconfirmActionsResult = await PaymentSheet.handlePreconfirmActionsIfNecessary(
            configuration: confirmationContext.configuration,
            authenticationContext: authenticationContext,
            intent: .checkout(checkoutSession),
            paymentOption: confirmationContext.paymentOption,
            paymentHandler: paymentHandler,
            integrationShape: confirmationContext.integrationShape
        )

        let intentConfirmParams: IntentConfirmParams?
        switch preconfirmActionsResult {
        case .succeeded(let params):
            intentConfirmParams = params
        case .canceled:
            return .init(paymentSheetResult: .canceled)
        case .failed(let error):
            return .init(paymentSheetResult: .failed(error: error))
        }

        // 2. Confirm the Checkout Session using the selected payment option.
        return await confirmPaymentOption(
            checkoutSession: checkoutSession,
            confirmationContext: confirmationContext,
            authenticationContext: authenticationContext,
            intentConfirmParamsForDeferredIntent: intentConfirmParams,
            paymentHandler: paymentHandler,
            checkoutApplePayDataSource: checkoutApplePayDataSource
        )
    }

    static func confirmPaymentOption(
        checkoutSession: Checkout.Session,
        confirmationContext: ConfirmationContext,
        authenticationContext: STPAuthenticationContext,
        intentConfirmParamsForDeferredIntent: IntentConfirmParams?,
        paymentHandler: STPPaymentHandler,
        checkoutApplePayDataSource: CheckoutApplePayDataSource? = nil
    ) async -> InternalConfirmResult {
        let paymentOption = confirmationContext.paymentOption
        let elementsSession = checkoutSession.elementsSession
        let configuration = confirmationContext.configuration
        let confirmationChallenge = confirmationContext.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: elementsSession
        )

        switch paymentOption {
        case .applePay:
            guard let checkoutApplePayDataSource else {
                fatalError(
                    "Cannot call confirmPaymentOption with .applePay without a checkoutApplePayDataSource"
                )
            }
            return await confirmApplePay(
                checkoutSession: checkoutSession,
                checkoutApplePayDataSource: checkoutApplePayDataSource
            )
        case .new(let confirmParams):
            // MARK: - New PM
            let paymentMethodType: STPPaymentMethodType = {
                switch paymentOption.paymentMethodType {
                case .stripe(let paymentMethodType):
                    return paymentMethodType
                default:
                    return .unknown
                }
            }()
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
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
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
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                elementsSession: elementsSession
            )
            return result

        case .external:
            // MARK: - External PM
            stpAssertionFailure("External payment methods not supported.")
            return .init(paymentSheetResult: .failed(error: PaymentSheetError.confirmingWithInvalidPaymentOption))

        case .link:
            // MARK: - Link
            return await confirmLink(
                checkoutSession: checkoutSession,
                confirmationContext: confirmationContext,
                authenticationContext: authenticationContext,
                clientAttributionMetadata: clientAttributionMetadata,
                paymentHandler: paymentHandler
            )
        }
    }

    /// Confirms a checkout session with a new payment method
    @MainActor
    static func handleCheckoutSessionConfirmation(
        checkoutSession: Checkout.Session,
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
                returnURL: configuration.returnURL,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
            return .init(paymentSheetResult: paymentSheetResult, checkoutSessionResponse: response)
        } catch {
            return .init(paymentSheetResult: .failed(error: error))
        }
    }

    @MainActor
    static func handleCheckoutSessionConfirmResponse(
        response: PaymentPagesAPIResponse,
        returnURL: String?,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async throws -> PaymentSheetResult {
        if let setupIntent = response.setupIntent {
            return await handleNextAction(
                for: setupIntent,
                returnURL: returnURL,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else if let paymentIntent = response.paymentIntent {
            return await handleNextAction(
                for: paymentIntent,
                returnURL: returnURL,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else {
            throw CheckoutError.unknown(
                debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent"
            )
        }
    }

    @MainActor
    private static func handleNextAction(
        for paymentIntent: STPPaymentIntent,
        returnURL: String?,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: paymentIntent,
                with: authenticationContext,
                returnURL: returnURL
            ) { status, _, error in
                continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    @MainActor
    private static func handleNextAction(
        for setupIntent: STPSetupIntent,
        returnURL: String?,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: setupIntent,
                with: authenticationContext,
                returnURL: returnURL
            ) { status, _, error in
                continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    private static func makeCheckoutSessionShippingParams(configuration: PaymentElementConfiguration) -> STPPaymentIntentShippingDetailsParams? {
        return STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
    }
}
