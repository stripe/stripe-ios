//
//  PaymentSheet+ConfirmationTokens.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/22/25.
//

import Foundation
@_spi(STP) import StripePayments

extension PaymentSheet {
    @MainActor
    static func handleDeferredIntentConfirmation_confirmationToken(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession,
        mandateData: STPMandateDataParams? = nil,
        confirmHandler: @escaping PaymentSheet.IntentConfiguration.ConfirmationTokenConfirmHandler
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        do {
            // 1. Create the confirmation token params
            let confirmationTokenParams = createConfirmationTokenParams(confirmType: confirmType,
                                                                        configuration: configuration,
                                                                        intentConfig: intentConfig,
                                                                        allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                                                                        elementsSession: elementsSession,
                                                                        mandateData: mandateData)

            let ephemeralKeySecret: String? = {
                // Only needed when using existing saved payment methods, API will error if provided for new payment methods
                guard confirmationTokenParams.paymentMethod != nil else { return nil }
                // Link saved payment methods don't require ephemeral keys, API will error if provided
                guard !isSavedFromLink(from: confirmType) else { return nil }

                return configuration.customer?.ephemeralKeySecret(basedOn: elementsSession)
            }()

            // 2. Create the ConfirmationToken
            let confirmationToken = try await configuration.apiClient.createConfirmationToken(with: confirmationTokenParams,
                                                                                              ephemeralKeySecret: ephemeralKeySecret,
                                                                                              additionalPaymentUserAgentValues: makeDeferredPaymentUserAgentValue(intentConfiguration: intentConfig))

            // 3. Vend the ConfirmationToken and fetch the client secret from the merchant
            let clientSecret = try await confirmHandler(confirmationToken)

            guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                // Force close PaymentSheet and early exit
                return (.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent)
            }

            let savedPaymentMethodRadarOptions: STPRadarOptions? = {
                switch confirmType {
                case .saved(_, _, _, let radarOptions):
                    // Edge-case we need to send radarOptions to level for CSC as there is no top level radarOptions property on the CT
                    // hCaptcha is only supported client-side so this is acceptable
                    return radarOptions
                case .new:
                    // Radar options is already attached to the paymentMethodData that was used to create the confirmation token
                    return nil
                }
            }()

            // 4. Retrieve the PaymentIntent or SetupIntent and confirm
            let result: (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?)
            switch intentConfig.mode {
            case .payment:
                let paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])

                // Check if it needs confirmation
                if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                    // 5a. Client-side confirmation with confirmation token
                    let paymentIntentParams = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.confirmationToken = confirmationToken.stripeId
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.radarOptions = savedPaymentMethodRadarOptions
                    paymentIntentParams.clientAttributionMetadata = confirmationTokenParams.clientAttributionMetadata

                    result = await withCheckedContinuation { continuation in
                        paymentHandler.confirmPaymentIntent(
                            params: paymentIntentParams,
                            authenticationContext: authenticationContext
                        ) { status, paymentIntent, error in
                            let intent = paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }
                            if let intent {
                                setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: intent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                            }
                            continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), .client))
                        }
                    }
                } else {
                    // 5b. Server-side confirmation
                    // Note: We cannot validate the ConfirmationToken used to confirm server-side, the backend does not return the CT on the intent object
                    result = await withCheckedContinuation { continuation in
                        paymentHandler.handleNextAction(
                            for: paymentIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, paymentIntent, error in
                            let intent = paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }
                            if let intent {
                                setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: intent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                            }
                            continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), .server))
                        }
                    }
                }
            case .setup:
                let setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret, expand: ["payment_method"])

                if [STPSetupIntentStatus.requiresPaymentMethod, STPSetupIntentStatus.requiresConfirmation].contains(setupIntent.status) {
                    // 6a. Client-side confirmation with confirmation token
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.confirmationToken = confirmationToken.stripeId
                    setupIntentParams.returnURL = configuration.returnURL
                    setupIntentParams.radarOptions = savedPaymentMethodRadarOptions
                    setupIntentParams.clientAttributionMetadata = confirmationTokenParams.clientAttributionMetadata

                    result = await withCheckedContinuation { continuation in
                        paymentHandler.confirmSetupIntent(
                            params: setupIntentParams,
                            authenticationContext: authenticationContext
                        ) { status, setupIntent, error in
                            let intent = setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }
                            if let intent {
                                setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: intent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                            }
                            continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), .client))
                        }
                    }
                } else {
                    // 6b. Server-side confirmation
                    // Note: We cannot validate the ConfirmationToken used to confirm server-side, the backend does not return the CT on the intent object
                    result = await withCheckedContinuation { continuation in
                        paymentHandler.handleNextAction(
                            for: setupIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, setupIntent, error in
                            let intent = setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }
                            if let intent {
                                setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: intent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                            }
                            continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), .server))
                        }
                    }
                }
            }
            return result
        } catch {
            return (.failed(error: error), nil)
        }
    }

    static func createConfirmationTokenParams(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession,
        mandateData: STPMandateDataParams? = nil
    ) -> STPConfirmationTokenParams {

        // 1. Initialize confirmation token with basic configuration
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.returnURL = configuration.returnURL
        confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams
        // Only send clientContext in DEBUG to validate client IntentConfiguration matches server intent.
        // This helps catch integration errors during development (e.g. mismatched currency/amount/SFU)
        // without breaking production payments if server intent changes after client configuration.
        #if DEBUG
        confirmationTokenParams.clientContext = intentConfig.createClientContext(customerId: configuration.customer?.id)
        #endif

        // 2. Configure payment method details based on confirm type
        switch confirmType {
        case .saved(let paymentMethod, let paymentOptions, let clientAttributionMetadata, _):
            // Use existing saved payment method
            confirmationTokenParams.paymentMethod = paymentMethod.stripeId
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata
        case .new(let paymentMethodParams, let paymentOptions, _, _, let shouldSetAsDefaultPM):
            confirmationTokenParams.paymentMethodData = paymentMethodParams
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            // Send CAM at the top-level of all requests in scope for consistency
            // Also send under payment_method_data because there are existing dependencies
            confirmationTokenParams.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata

            // Set as default payment method if requested and allowed
            if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                confirmationTokenParams.setAsDefaultPM = NSNumber(value: true)
            }
        }

        // 3. Set setup future usage based on intent configuration and user choice
        switch intentConfig.mode {
        case .setup(_, let setupFutureUsage):
            // Setup intents: Always use the configured setup future usage value
            confirmationTokenParams.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue
        case .payment(_, _, let intentSetupFutureUsage, _, let paymentMethodOptions):
            let paymentMethodType = paymentMethodType(from: confirmType)
            // Priority order: user checkbox > PMO SFU > top-level SFU
            if confirmType.shouldSave {
                // 1. User chose to save payment method via checkbox takes highest priority
                confirmationTokenParams.setupFutureUsage = .offSession
            } else if let pmoSFU = paymentMethodOptions?.setupFutureUsageValues?[paymentMethodType] {
                // 2. PMO SFU takes second priority
                confirmationTokenParams.setupFutureUsage = pmoSFU.paymentIntentParamsValue
            } else if let intentSetupFutureUsage = intentSetupFutureUsage {
                // 3. Use top-level intent configuration as fallback
                confirmationTokenParams.setupFutureUsage = intentSetupFutureUsage.paymentIntentParamsValue
            }
        }

        // 4. Set mandate data (explicit or auto-generated)
        if let explicitMandateData = mandateData {
            // Use explicitly provided mandate data
            confirmationTokenParams.mandateData = explicitMandateData
        } else {
            // Auto-generate mandate data based on payment method and intent requirements
            let paymentMethodType = Self.paymentMethodType(from: confirmType)

            switch intentConfig.mode {
            case .payment:
                // Payment methods that require mandate data when setup_future_usage is "off_session"
                if STPPaymentMethodType.requiresMandateDataForPaymentIntent.contains(paymentMethodType) {
                    if confirmationTokenParams.setupFutureUsage == .offSession {
                        confirmationTokenParams.mandateData = .makeWithInferredValues()
                    }
                }

                // If no mandate data, fallback to STPPaymentIntentParams auto add functionality
                if confirmationTokenParams.mandateData == nil {
                    confirmationTokenParams.mandateData = STPPaymentIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
                }
            case .setup:
                // Setup intents always require mandate data for certain payment methods
                if STPPaymentMethodType.requiresMandateDataForSetupIntent.contains(paymentMethodType) {
                    confirmationTokenParams.mandateData = .makeWithInferredValues()
                }

                // If no mandate data, fallback to STPSetupIntentConfirmParams auto add functionality
                if confirmationTokenParams.mandateData == nil {
                    confirmationTokenParams.mandateData = STPSetupIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
                }
            }
        }

        return confirmationTokenParams
    }

    /// Extracts the  payment method type from confirmation details
    ///
    /// - Parameter confirmType: The confirmation type (saved or new payment method)
    /// - Returns: The  payment method type for API operations
    private static func paymentMethodType(from confirmType: ConfirmPaymentMethodType) -> STPPaymentMethodType {
        switch confirmType {
        case .saved(let paymentMethod, _, _, _):
            return paymentMethod.type
        case .new(let params, _, _, _, _):
            return params.type
        }
    }

    /// Determines if a payment method was saved through Stripe Link
    ///
    /// - Parameter confirmType: The payment method confirmation type
    /// - Returns: True if the payment method originated from Link
    private static func isSavedFromLink(from confirmType: ConfirmPaymentMethodType) -> Bool {
        switch confirmType {
        case .saved(let paymentMethod, _, _, _):
            return paymentMethod.card?.wallet?.type == .link || paymentMethod.isLinkPaymentMethod || paymentMethod.isLinkPassthroughMode || paymentMethod.link != nil
        case .new:
            return false
        }
    }
}
