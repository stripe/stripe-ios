//
//  PaymentSheet+ConfirmationTokens.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/22/25.
//

import Foundation
@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments

extension PaymentSheet {
    static func handleDeferredIntentConfirmation_confirmationToken(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            do {
                // ElementsSession is required for confirmation token flow
                guard let elementsSession = elementsSession else {
                    assertionFailure("ElementsSession is required for confirmation token flow")
                    completion(.failed(error: PaymentSheetError.unknown(debugDescription: "ElementsSession is required for confirmation token flow")), nil)
                    return
                }
                
                // 1. Create the confirmation token params
                let confirmationTokenParams = createConfirmationTokenParams(confirmType: confirmType,
                                                                            configuration: configuration,
                                                                            intentConfig: intentConfig,
                                                                            elementsSession: elementsSession, radarOptions: radarOptions)
                
                // Compute ephemeral key secret for customer session support
                let ephemeralKeySecret: String? = {
                    // ConfirmationToken creation requests fail if an eph key is provided when not required
                    guard confirmationTokenParams.paymentMethod != nil else { return nil }
                    // ConfirmationToken creation requests fail if an eph key is provided for Link saved PMs
                    guard !isSavedFromLink(from: confirmType) else { return nil }
                    
                    return configuration.customer?.ephemeralKeySecretBasedOn(elementsSession: elementsSession)
                }()
                
                let confirmationToken = try await configuration.apiClient.createConfirmationToken(with: confirmationTokenParams,
                                                                                                  ephemeralKeySecret: ephemeralKeySecret)
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 confirmationToken: confirmationToken)
                guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    // Force close PaymentSheet and early exit
                    completion(.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent)
                    return
                }

                // Overwrite `completion` to ensure we set the default if necessary before completing.
                let completion = { (status: STPPaymentHandlerActionStatus, paymentOrSetupIntent: PaymentOrSetupIntent?, error: NSError?, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType) in
                    if let paymentOrSetupIntent {
                        setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: paymentOrSetupIntent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                    }
                    completion(makePaymentSheetResult(for: status, error: error), deferredIntentConfirmationType)
                }

                // 3. Retrieve the PaymentIntent or SetupIntent
                switch intentConfig.mode {
                case .payment:
                    let paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])

                    // Check if it needs confirmation
                    if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                        // 4a. Client-side confirmation with confirmation token
                        // TODO(porter) Add confirmation token flow validation
                        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, confirmationToken: confirmationToken)
                        paymentIntentParams.radarOptions = radarOptions
                        
                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext
                        ) { status, paymentIntent, error in
                            completion(status, paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        // TODO(porter) Add confirmation token flow validation
                        paymentHandler.handleNextAction(
                            for: paymentIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, paymentIntent, error in
                            completion(status, paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }, error, .server)
                        }
                    }
                case .setup:
                    let setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret, expand: ["payment_method"])

                    if [STPSetupIntentStatus.requiresPaymentMethod, STPSetupIntentStatus.requiresConfirmation].contains(setupIntent.status) {
                        // 4a. Client-side confirmation with confirmation token
                        // TODO(porter) Add confirmation token flow validation
                        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret, confirmationToken: confirmationToken)
                        setupIntentParams.radarOptions = radarOptions
                        
                        paymentHandler.confirmSetupIntent(
                            setupIntentParams,
                            with: authenticationContext
                        ) { status, setupIntent, error in
                            completion(status, setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        // TODO(porter) Add confirmation token flow validation
                        paymentHandler.handleNextAction(
                            for: setupIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, setupIntent, error in
                            completion(status, setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }, error, .server)
                        }
                    }
                }
            } catch {
                completion(.failed(error: error), nil)
            }
        }
    }
    
    /// Creates confirmation token parameters for deferred intent confirmation
    ///
    /// This method handles the creation of `STPConfirmationTokenParams` by:
    /// 1. Setting up basic configuration (return URL, shipping)
    /// 2. Configuring payment method details based on confirm type
    /// 3. Setting setup future usage based on intent configuration
    /// 4. Auto-generating mandate data when required
    ///
    /// - Parameters:
    ///   - confirmType: Type of payment method being confirmed (saved or new)
    ///   - configuration: PaymentSheet configuration containing URLs and shipping
    ///   - intentConfig: Intent configuration with mode and setup future usage settings
    ///   - allowsSetAsDefaultPM: Whether setting payment method as default is allowed
    ///   - elementsSession: Elements session (required for confirmation token flow)
    ///   - mandateData: Explicit mandate data (optional, auto-generated if nil)
    ///   - radarOptions: Radar options for fraud detection
    /// - Returns: Configured `STPConfirmationTokenParams` ready for API submission
    private static func createConfirmationTokenParams(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil
    ) -> STPConfirmationTokenParams {

        // STEP 1: Initialize confirmation token with basic configuration
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.returnURL = configuration.returnURL
        confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams

        // STEP 2: Configure payment method details based on confirm type
        configurePaymentMethodDetails(
            confirmationTokenParams,
            confirmType: confirmType,
            allowsSetAsDefaultPM: allowsSetAsDefaultPM,
            radarOptions: radarOptions
        )

        // STEP 3: Set setup future usage based on intent configuration and user choice
        configureSetupFutureUsage(
            confirmationTokenParams,
            confirmType: confirmType,
            intentConfig: intentConfig
        )

        // STEP 4: Set mandate data (explicit or auto-generated)
        configureMandateData(
            confirmationTokenParams,
            confirmType: confirmType,
            intentConfig: intentConfig,
            explicitMandateData: mandateData
        )

        return confirmationTokenParams
    }

    /// Configures payment method details based on the confirmation type
    private static func configurePaymentMethodDetails(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        allowsSetAsDefaultPM: Bool,
        radarOptions: STPRadarOptions?
    ) {
        switch confirmType {
        case .saved(let paymentMethod, let paymentOptions, let clientAttributionMetadata):
            // Use existing saved payment method
            params.paymentMethod = paymentMethod.stripeId
            params.paymentMethodOptions = paymentOptions
            params.clientAttributionMetadata = clientAttributionMetadata

        case .new(let paymentMethodParams, let paymentOptions, let unexpectedPaymentMethod, _, let shouldSetAsDefaultPM):
            // Create new payment method from parameters
            handleUnexpectedPaymentMethod(unexpectedPaymentMethod)

            params.paymentMethodData = paymentMethodParams
            params.paymentMethodData?.radarOptions = radarOptions
            params.paymentMethodOptions = paymentOptions

            // Set as default payment method if requested and allowed
            if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                params.setAsDefaultPM = NSNumber(value: true)
            }
        }
    }

    /// Configures setup future usage based on intent configuration and user preferences
    private static func configureSetupFutureUsage(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration
    ) {
        switch intentConfig.mode {
        case .setup(_, let setupFutureUsage):
            // Setup intents: Always use the configured setup future usage value
            params.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue

        case .payment(_, _, let intentSetupFutureUsage, _, _):
            // Payment intents: Priority order is user choice > intent configuration
            if confirmType.shouldSave {
                // User chose to save payment method, hardcode to offSession
                params.setupFutureUsage = .offSession
            } else if let intentSetupFutureUsage = intentSetupFutureUsage {
                // Use intent configuration default
                params.setupFutureUsage = intentSetupFutureUsage.paymentIntentParamsValue
            }
        }
    }

    /// Configures mandate data using explicit data or auto-generation
    private static func configureMandateData(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration,
        explicitMandateData: STPMandateDataParams?
    ) {
        if let explicitMandateData = explicitMandateData {
            // Use explicitly provided mandate data
            params.mandateData = explicitMandateData
        } else {
            // Auto-generate mandate data based on payment method and intent requirements
            params.mandateData = generateMandateData(
                confirmType: confirmType,
                intentConfig: intentConfig
            )
        }
    }

    /// Generates mandate data for confirmation tokens, matching the behavior of STPPaymentIntentParams.mandateData
    ///
    /// This function handles three scenarios:
    /// 1. Payment methods that require mandate data when setup_future_usage is "off_session"
    /// 2. Payment methods that always require mandate data in setup intents
    /// 3. Bank-based payment methods that always require mandate data (matching STPPaymentIntentParams behavior)
    ///
    /// - Parameters:
    ///   - confirmType: The type of payment method being confirmed
    ///   - intentConfig: The intent configuration containing setup future usage settings
    /// - Returns: STPMandateDataParams if mandate data is required, nil otherwise
    private static func generateMandateData(
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration
    ) -> STPMandateDataParams? {
        let paymentMethodType = Self.paymentMethodType(from: confirmType)

        // SCENARIO 1 & 2: Handle payment methods that require mandate data based on intent mode
        switch intentConfig.mode {
        case .payment(_, _, let topLevelSFU, _, let paymentMethodOptions):
            // Payment methods that require mandate data when setup_future_usage is "off_session"
            let mandateRequiredWithSFU: Set<STPPaymentMethodType> = [
                .payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay
            ]
            if mandateRequiredWithSFU.contains(paymentMethodType) {
                // Check effective setup future usage (PMO SFU takes priority over top-level SFU)
                let pmoSFU = paymentMethodOptions?.setupFutureUsageValues?[paymentMethodType]
                let effectiveSFU = pmoSFU ?? topLevelSFU

                if effectiveSFU == .offSession {
                    return .makeWithInferredValues()
                }
            }
            
            // If still no mandate data, match STPPaymentIntentParams auto add functionality
            return STPPaymentIntentParams.mandateDataIfRequired(for: paymentMethodType)
        case .setup:
            // Setup intents always require mandate data for certain payment methods
            let mandateRequiredForSetup: Set<STPPaymentMethodType> = [
                .payPal, .revolutPay, .satispay
            ]
            if mandateRequiredForSetup.contains(paymentMethodType) {
                return .makeWithInferredValues()
            }
            
            // If still no mandate data, match STPSetupIntentConfirmParams auto add functionality
            return STPSetupIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
        }
    }

    private static func fetchIntentClientSecretFromMerchant(
        intentConfig: IntentConfiguration,
        confirmationToken: STPConfirmationToken
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                intentConfig.confirmationTokenConfirmHandler?(confirmationToken) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    private static func isSavedFromLink(from confirmType: ConfirmPaymentMethodType) -> Bool {
        switch confirmType {
        case .saved(let paymentMethod,_, _):
            return paymentMethod.card?.wallet?.type == .link || paymentMethod.isLinkPaymentMethod || paymentMethod.isLinkPassthroughMode || paymentMethod.usBankAccount?.linkedAccount != nil
        case .new(_, _, _, _, _):
            return false
        }
    }
    
    
    /// Logs analytics for unexpected payment method scenarios
    private static func handleUnexpectedPaymentMethod(_ unexpectedPaymentMethod: STPPaymentMethod?) {
        guard let unexpectedPaymentMethod = unexpectedPaymentMethod else { return }

        let errorAnalytic = ErrorAnalytic(
            event: .unexpectedPaymentSheetConfirmationError,
            error: PaymentSheetError.unexpectedNewPaymentMethod,
            additionalNonPIIParams: ["payment_method_type": unexpectedPaymentMethod.type]
        )
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        stpAssert(false, "Unexpected payment method provided for new confirmation type")
    }
}
