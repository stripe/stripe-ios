//
//  PaymentSheet+DeferredAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/23.
//

import Foundation
@_spi(STP) import StripeCore
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
                
                // 1. Create the ConfirmationToken
                let confirmationTokenParams = STPConfirmationTokenParams()
                confirmationTokenParams.returnURL = configuration.returnURL
                confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams

                switch confirmType {
                case .saved(let sTPPaymentMethod, let paymentOptions, let clientAttributionMetadata):
                    confirmationTokenParams.paymentMethod = sTPPaymentMethod.stripeId
                    confirmationTokenParams.paymentMethodOptions = paymentOptions // TODO(porter) CVC recollection
                    confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata
                case .new(let params, let paymentOptions, let newPaymentMethod, let shouldSave, let shouldSetAsDefaultPM):
                    if let newPaymentMethod {
                        let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError,
                                                          error: PaymentSheetError.unexpectedNewPaymentMethod,
                                                          additionalNonPIIParams: ["payment_method_type": newPaymentMethod.type])
                        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                    }
                    stpAssert(newPaymentMethod == nil)
                    confirmationTokenParams.paymentMethodData = params
                    // Confirmation tokens only supports card payment method options
                    if let _ = paymentOptions.cardOptions {
                        confirmationTokenParams.paymentMethodOptions = paymentOptions
                    }
                    // Not setting clientAttributionMetadata on the CT params as it's already contained on the params

                    // Handle setup future usage based on intent type
                    switch intentConfig.mode {
                    case .setup:
                        // SetupIntents always save payment methods, so always set off_session
                        confirmationTokenParams.setupFutureUsage = .offSession
                    case .payment:
                        // For PaymentIntents, respect user's explicit choice
                        if shouldSave {
                            confirmationTokenParams.setupFutureUsage = .offSession
                        }
                    }

                    if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                        confirmationTokenParams.setAsDefaultPM = NSNumber(value: true)
                    }
                }

                // TODO(porter) Handle radarOptions

                // Set Setup Future Usage (SFU) based on intent configuration
                let paymentMethodType = Self.paymentMethodType(from: confirmType)
                
                // Handle SetupIntents explicitly (they always save payment methods)
                switch intentConfig.mode {
                case .setup:
                    confirmationTokenParams.setupFutureUsage = .offSession
                case .payment:
                    // For PaymentIntents, use the existing logic that respects intent config SFU/PMO SFU
                    setSetupFutureUsage(for: paymentMethodType, intentConfiguration: intentConfig, on: confirmationTokenParams)
                }

                // Set mandate data - use explicit or auto-generate for specific payment methods
                if let mandateData = mandateData {
                    // Use explicit mandate data if provided
                    confirmationTokenParams.mandateData = mandateData
                } else {
                    let paymentMethodType = Self.paymentMethodType(from: confirmType)
                    
                    // Auto-generate for payment methods that require it with setup_future_usage
                    let requiresMandateDataWithSFU: [STPPaymentMethodType] = [.payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay]
                    // Check if we'll have setup_future_usage set (either explicitly by user or by intent config)
                    let willHaveSetupFutureUsage = (confirmationTokenParams.setupFutureUsage != .none)
                    if requiresMandateDataWithSFU.contains(paymentMethodType) && willHaveSetupFutureUsage {
                        confirmationTokenParams.mandateData = .makeWithInferredValues()
                    }
                    
                    // Auto-generate mandate data for bank-based payment methods (matches STPPaymentIntentParams.mandateData behavior)
                    // These payment methods automatically get mandate data in the regular flow, so confirmation token flow should behave the same
                    let bankBasedPaymentMethods: [STPPaymentMethodType] = [.AUBECSDebit, .bacsDebit, .bancontact, .iDEAL, .SEPADebit, .EPS, .sofort, .link, .USBankAccount]
                    if bankBasedPaymentMethods.contains(paymentMethodType) {
                        confirmationTokenParams.mandateData = .makeWithInferredValues()
                    }
                }
                
                // Compute ephemeral key secret for customer session support
                let ephemeralKeySecret = configuration.customer?.ephemeralKeySecretBasedOn(elementsSession: elementsSession)
                let confirmationToken = try await configuration.apiClient.createConfirmationToken(with: confirmationTokenParams, ephemeralKeySecret: ephemeralKeySecret)
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
                        paymentIntentParams.returnURL = configuration.returnURL

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
                        setupIntentParams.returnURL = configuration.returnURL

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

    static func handleDeferredIntentConfirmation(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            do {
                var confirmType = confirmType
                // 1. Create PM if necessary
                let paymentMethod: STPPaymentMethod
                switch confirmType {
                case let .saved(savedPaymentMethod, _, _):
                    paymentMethod = savedPaymentMethod
                case let .new(params, paymentOptions, newPaymentMethod, shouldSave, shouldSetAsDefaultPM):
                    if let newPaymentMethod {
                        let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError,
                                                          error: PaymentSheetError.unexpectedNewPaymentMethod,
                                                          additionalNonPIIParams: ["payment_method_type": newPaymentMethod.type])
                        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                    }
                    stpAssert(newPaymentMethod == nil)
                    paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params, additionalPaymentUserAgentValues: makeDeferredPaymentUserAgentValue(intentConfiguration: intentConfig))
                    confirmType = .new(params: params, paymentOptions: paymentOptions, paymentMethod: paymentMethod, shouldSave: shouldSave, shouldSetAsDefaultPM: shouldSetAsDefaultPM)
                }

                // 2a. If we have a preparePaymentMethodHandler, use the shared payment token session flow
                if let preparePaymentMethodHandler = intentConfig.preparePaymentMethodHandler {
                    // For shared payment token sessions, call the preparePaymentMethodHandler and complete successfully
                    // Note: Shipping address is passed for Apple Pay in STPApplePayContext+PaymentSheet.swift.
                    // For other payment methods, get shipping address from configuration.
                    let shippingAddress = configuration.shippingDetails()?.stpAddress

                    // Try to create a radar session for the payment method before calling the handler
                    configuration.apiClient.createSavedPaymentMethodRadarSession(paymentMethodId: paymentMethod.stripeId) { _, error in
                        // If radar session creation fails, just continue with the payment method directly
                        if let error {
                            // Log the error but don't fail the payment
                            let errorAnalytic = ErrorAnalytic(event: .savedPaymentMethodRadarSessionFailure, error: error)
                            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: configuration.apiClient)
                        }

                        // Call the handler regardless of radar session success/failure
                        preparePaymentMethodHandler(paymentMethod, shippingAddress)
                        completion(.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent)
                    }
                    return
                }

                // 2b. Otherwise, call the standard confirmHandler
                let shouldSavePaymentMethod: Bool = {
                    // If `confirmType.shouldSave` is true, that means the customer has decided to save by checking the checkbox.
                    if confirmType.shouldSave {
                        return true
                    }
                    // Otherwise, set shouldSavePaymentMethod according to the IntentConfiguration SFU/PMO SFU values
                    return getShouldSavePaymentMethodValue(for: paymentMethod.type, intentConfiguration: intentConfig)
                }()
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 paymentMethod: paymentMethod,
                                                                                 shouldSavePaymentMethod: shouldSavePaymentMethod)
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
                        // 4a. Client-side confirmation
                        try PaymentSheetDeferredValidator.validate(paymentIntent: paymentIntent, intentConfiguration: intentConfig, paymentMethod: paymentMethod, isFlowController: isFlowController)
                        let paymentIntentParams = makePaymentIntentParams(
                            confirmPaymentMethodType: confirmType,
                            paymentIntent: paymentIntent,
                            configuration: configuration,
                            mandateData: mandateData,
                            radarOptions: radarOptions
                        )
                        // Set top-level SFU and PMO SFU to match the intent config
                        setSetupFutureUsage(for: paymentMethod.type, intentConfiguration: intentConfig, on: paymentIntentParams)

                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext
                        ) { status, paymentIntent, error in
                            completion(status, paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: paymentIntent.paymentMethod, paymentMethod: paymentMethod)
                        assert(!allowsSetAsDefaultPM, "(Debug-build-only error) The default payment methods feature is not yet supported with deferred intents. Please contact us if you'd like to use this feature via a Github issue on stripe-ios.")
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
                        // 4a. Client-side confirmation
                        try PaymentSheetDeferredValidator.validate(setupIntent: setupIntent, intentConfiguration: intentConfig, paymentMethod: paymentMethod)
                        let setupIntentParams = makeSetupIntentParams(
                            confirmPaymentMethodType: confirmType,
                            setupIntent: setupIntent,
                            configuration: configuration,
                            mandateData: mandateData,
                            radarOptions: radarOptions
                        )
                        paymentHandler.confirmSetupIntent(
                            setupIntentParams,
                            with: authenticationContext
                        ) { status, setupIntent, error in
                            completion(status, setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: setupIntent.paymentMethod, paymentMethod: paymentMethod)
                        assert(!allowsSetAsDefaultPM, "(Debug-build-only error) The default payment methods feature is not yet supported with deferred intents. Please contact us if you'd like to use this feature via a Github issue on stripe-ios.")
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

    /// Routes deferred intent confirmation to either the regular flow or confirmation token flow based on available handlers
    static func routeDeferredIntentConfirmation(
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
        // Route based on which handler is available in the intent configuration
        if intentConfig.confirmationTokenConfirmHandler != nil {
            // Use confirmation token flow
            handleDeferredIntentConfirmation_confirmationToken(
                confirmType: confirmType,
                configuration: configuration,
                intentConfig: intentConfig,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                isFlowController: isFlowController,
                allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                elementsSession: elementsSession,
                mandateData: mandateData,
                radarOptions: radarOptions,
                completion: completion
            )
        } else {
            // Use regular confirmation flow
            handleDeferredIntentConfirmation(
                confirmType: confirmType,
                configuration: configuration,
                intentConfig: intentConfig,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                isFlowController: isFlowController,
                allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                mandateData: mandateData,
                radarOptions: radarOptions,
                completion: completion
            )
        }
    }

    // MARK: - Helper methods

    /// Convenience method that converts a STPPaymentHandlerActionStatus + error into a PaymentSheetResult
    static func makePaymentSheetResult(for status: STPPaymentHandlerActionStatus, error: Error?) -> PaymentSheetResult {
        switch status {
        case .succeeded:
            return .completed
        case .canceled:
            return .canceled
        case .failed:
            let error = error ?? PaymentSheetError.errorHandlingNextAction
            return .failed(error: error)
        @unknown default:
            return .failed(error: PaymentSheetError.unrecognizedHandlerStatus)
        }
    }

    static func fetchIntentClientSecretFromMerchant(
        intentConfig: IntentConfiguration,
        paymentMethod: STPPaymentMethod,
        shouldSavePaymentMethod: Bool
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                intentConfig.confirmHandler?(paymentMethod, shouldSavePaymentMethod) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    static func fetchIntentClientSecretFromMerchant(
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

    static func makeDeferredPaymentUserAgentValue(intentConfiguration: IntentConfiguration) -> [String] {
        var paymentUserAgentValues = ["deferred-intent"]
        if intentConfiguration.paymentMethodTypes?.isEmpty ?? true {
            // Add "autopm" tag when using deferred intents and merchant is using automatic_payment_methods
            // If paymentMethodTypes is empty, assume they are using automatic_payment_methods.
            paymentUserAgentValues.append("autopm")
        }
        return paymentUserAgentValues
    }

    /// Extract the payment method type from a ConfirmPaymentMethodType
    static func paymentMethodType(from confirmType: ConfirmPaymentMethodType) -> STPPaymentMethodType {
        switch confirmType {
        case .saved(let paymentMethod, _, _):
            return paymentMethod.type
        case .new(let params, _, _, _, _):
            return params.type
        }
    }

    /// Sets PMO SFU or SFU on the given `paymentIntentParams` object if the given `intentConfiguration` has SFU set / PMO SFU set for the given `paymentMethodType`.
    /// See https://docs.google.com/document/d/1AW8j-cJ9ZW5h-LapzXOYrrE2b1XtmVo_SnvbNf-asOU
    static func setSetupFutureUsage(for paymentMethodType: STPPaymentMethodType, intentConfiguration: IntentConfiguration, on paymentIntentParams: STPPaymentIntentParams) {
        // We only set SFU/PMO SFU for PaymentIntents
        guard
            case let .payment(amount: _, currency: _, setupFutureUsage: topLevelSFUValue, captureMethod: _, paymentMethodOptions: paymentMethodOptions) = intentConfiguration.mode
        else {
            return
        }
        guard paymentIntentParams.setupFutureUsage == nil && paymentIntentParams.nonnil_paymentMethodOptions.setupFutureUsage(for: paymentMethodType) == nil else {
            // If the PI params has SFU/PMO SFU set already, assume it was set to respect the checkbox, don't overwrite.
           return
        }
        // Set top-level SFU
        if let topLevelSFUValue {
            paymentIntentParams.setupFutureUsage = topLevelSFUValue.paymentIntentParamsValue
        }
        // Set PMO SFU for the PM type
        if let pmoSFUValues = paymentMethodOptions?.setupFutureUsageValues, let pmoSFUValue = pmoSFUValues[paymentMethodType] {
            // e.g. payment_method_options["card"]["setup_future_usage"] = "off_session"
            paymentIntentParams.nonnil_paymentMethodOptions.additionalAPIParameters[paymentMethodType.identifier] = ["setup_future_usage": pmoSFUValue.rawValue]
        }
    }

    /// Sets PMO SFU or SFU on the given `confirmationTokenParams` object if the given `intentConfiguration` has SFU set / PMO SFU set for the given `paymentMethodType`.
    /// See https://docs.google.com/document/d/1AW8j-cJ9ZW5h-LapzXOYrrE2b1XtmVo_SnvbNf-asOU
    static func setSetupFutureUsage(for paymentMethodType: STPPaymentMethodType, intentConfiguration: IntentConfiguration, on confirmationTokenParams: STPConfirmationTokenParams) {
        // We only set SFU/PMO SFU for PaymentIntents
        guard
            case let .payment(amount: _, currency: _, setupFutureUsage: topLevelSFUValue, captureMethod: _, paymentMethodOptions: paymentMethodOptions) = intentConfiguration.mode
        else {
            return
        }
        guard confirmationTokenParams.setupFutureUsage == .none else {
            // If the confirmation token params has SFU set already, assume it was set to respect the checkbox, don't overwrite.
            return
        }
        // Set top-level SFU
        if let topLevelSFUValue {
            confirmationTokenParams.setupFutureUsage = topLevelSFUValue.paymentIntentParamsValue
        }
        // Set PMO SFU for the PM type
        if let pmoSFUValues = paymentMethodOptions?.setupFutureUsageValues, let pmoSFUValue = pmoSFUValues[paymentMethodType] {
            // Create or update payment method options
            if confirmationTokenParams.paymentMethodOptions == nil {
                confirmationTokenParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
            }
            // e.g. payment_method_options["card"]["setup_future_usage"] = "off_session"
            confirmationTokenParams.paymentMethodOptions!.additionalAPIParameters[paymentMethodType.identifier] = ["setup_future_usage": pmoSFUValue.rawValue]
        }
    }

    /// Returns `true` if the PMO SFU / SFU value in the IntentConfiguration requires the PM to be saved.
    /// See https://docs.google.com/document/d/1AW8j-cJ9ZW5h-LapzXOYrrE2b1XtmVo_SnvbNf-asOU
    static func getShouldSavePaymentMethodValue(for paymentMethodType: STPPaymentMethodType, intentConfiguration: IntentConfiguration) -> Bool {
        // We only respect SFU/PMO SFU IntentConfiguration for PaymentIntents
        guard
            case let .payment(amount: _, currency: _, setupFutureUsage: topLevelSFUValue, captureMethod: _, paymentMethodOptions: paymentMethodOptions) = intentConfiguration.mode
        else {
            return false
        }
        // If PMO SFU for the PM type is set, use that value
        if let pmoSFUValues = paymentMethodOptions?.setupFutureUsageValues, let pmoSFUValue = pmoSFUValues[paymentMethodType] {
            return pmoSFUValue == .offSession || pmoSFUValue == .onSession
        }
        // Otherwise, if top-level SFU is set, use that value
        if let topLevelSFUValue {
            return topLevelSFUValue == .offSession || topLevelSFUValue == .onSession
        }
        // Otherwise, there is no SFU / PMO SFU set for the PM and it shouldn't be saved
        return false
    }
}

extension PaymentSheet.IntentConfiguration.SetupFutureUsage {
    var paymentIntentParamsValue: STPPaymentIntentSetupFutureUsage {
        switch self {
        case .none: return .none
        case .offSession: return .offSession
        case .onSession: return .onSession
        }
    }
}
