//
//  PaymentSheet+DeferredAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension PaymentSheet {
    /// Routes deferred intent confirmation to either the regular flow or confirmation token flow based on available handlers
    @MainActor
    static func routeDeferredIntentConfirmation(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        // Route based on which handler is available in the intent configuration
        if let confirmationTokenConfirmHandler = intentConfig.confirmationTokenConfirmHandler {
            guard let elementsSession else {
                stpAssertionFailure("Unexpected nil elementsSession when handling deferred intent confirmation with confirmation token flow")
                return (.failed(error: PaymentSheetError.unknown(debugDescription: "Missing elementsSession for confirmation token flow")), nil)
            }
            // Use confirmation token flow
            return await handleDeferredIntentConfirmation_confirmationToken(
                confirmType: confirmType,
                configuration: configuration,
                intentConfig: intentConfig,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                isFlowController: isFlowController,
                allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                elementsSession: elementsSession,
                mandateData: mandateData,
                confirmHandler: confirmationTokenConfirmHandler
            )
        } else if let confirmHandler = intentConfig.confirmHandler {
            // Use regular confirmation flow
            return await handleDeferredIntentConfirmation(
                confirmType: confirmType,
                configuration: configuration,
                intentConfig: intentConfig,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler,
                isFlowController: isFlowController,
                allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                mandateData: mandateData,
                confirmHandler: confirmHandler
            )
        } else {
            stpAssertionFailure("Unexpectedly found nil confirmHandler and confirmationTokenConfirmHandler in intentConfig")
            return (.failed(error: PaymentSheetError.unknown(debugDescription: "No confirm handler available")), nil)
        }
    }

    @MainActor
    private static func handleDeferredIntentConfirmation(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        mandateData: STPMandateDataParams? = nil,
        confirmHandler: @escaping IntentConfiguration.ConfirmHandler
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        do {
            var confirmType = confirmType
            // 1. Create PM if necessary
            let paymentMethod: STPPaymentMethod
            switch confirmType {
            case let .saved(savedPaymentMethod, _, _, _):
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
                return await withCheckedContinuation { continuation in
                    configuration.apiClient.createSavedPaymentMethodRadarSession(paymentMethodId: paymentMethod.stripeId) { _, error in
                        // If radar session creation fails, just continue with the payment method directly
                        if let error {
                            // Log the error but don't fail the payment
                            let errorAnalytic = ErrorAnalytic(event: .savedPaymentMethodRadarSessionFailure, error: error)
                            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: configuration.apiClient)
                        }

                        // Call the handler regardless of radar session success/failure
                        preparePaymentMethodHandler(paymentMethod, shippingAddress)
                        continuation.resume(returning: (.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent))
                    }
                }
            }

            // 2b. Otherwise, call the payment method confirmHandler
            let shouldSavePaymentMethod: Bool = {
                // If `confirmType.shouldSave` is true, that means the customer has decided to save by checking the checkbox.
                if confirmType.shouldSave {
                    return true
                }
                // Otherwise, set shouldSavePaymentMethod according to the IntentConfiguration SFU/PMO SFU values
                return getShouldSavePaymentMethodValue(for: paymentMethod.type, intentConfiguration: intentConfig)
            }()

            let clientSecret = try await confirmHandler(paymentMethod, shouldSavePaymentMethod)
            guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                // Force close PaymentSheet and early exit
                return (.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent)
            }

            // 3. Retrieve the PaymentIntent or SetupIntent and confirm
            let result: (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?)
            switch intentConfig.mode {
            case let .payment(_, _, setupFutureUsage, _, paymentMethodOptions):
                let paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])

                // Check if it needs confirmation
                if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                    // 4a. Client-side confirmation
                    try PaymentSheetDeferredValidator.validate(paymentIntent: paymentIntent, intentConfiguration: intentConfig, isFlowController: isFlowController)
                    try PaymentSheetDeferredValidator.validateSFUAndPMOSFU(setupFutureUsage: setupFutureUsage,
                                             paymentMethodOptions: paymentMethodOptions,
                                             paymentMethodType: paymentMethod.type, paymentIntent: paymentIntent)
                    try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: paymentIntent.paymentMethod, paymentMethod: paymentMethod)
                    let paymentIntentParams = makePaymentIntentParams(
                        confirmPaymentMethodType: confirmType,
                        paymentIntent: paymentIntent,
                        configuration: configuration,
                        mandateData: mandateData
                    )
                    // Set top-level SFU and PMO SFU to match the intent config
                    setSetupFutureUsage(for: paymentMethod.type, intentConfiguration: intentConfig, on: paymentIntentParams)

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
                    // 4b. Server-side confirmation
                    try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: paymentIntent.paymentMethod, paymentMethod: paymentMethod)
                    assert(!allowsSetAsDefaultPM, "(Debug-build-only error) The default payment methods feature is not yet supported with deferred intents. Please contact us if you'd like to use this feature via a Github issue on stripe-ios.")
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
                    // 4a. Client-side confirmation
                    try PaymentSheetDeferredValidator.validate(intentConfiguration: intentConfig)
                    try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: setupIntent.paymentMethod, paymentMethod: paymentMethod)
                    let setupIntentParams = makeSetupIntentParams(
                        confirmPaymentMethodType: confirmType,
                        setupIntent: setupIntent,
                        configuration: configuration,
                        mandateData: mandateData
                    )
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
                    // 4b. Server-side confirmation
                    try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: setupIntent.paymentMethod, paymentMethod: paymentMethod)
                    assert(!allowsSetAsDefaultPM, "(Debug-build-only error) The default payment methods feature is not yet supported with deferred intents. Please contact us if you'd like to use this feature via a Github issue on stripe-ios.")
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

    static func makeDeferredPaymentUserAgentValue(intentConfiguration: IntentConfiguration) -> [String] {
        var paymentUserAgentValues = ["deferred-intent"]
        if intentConfiguration.paymentMethodTypes?.isEmpty ?? true {
            // Add "autopm" tag when using deferred intents and merchant is using automatic_payment_methods
            // If paymentMethodTypes is empty, assume they are using automatic_payment_methods.
            paymentUserAgentValues.append("autopm")
        }
        return paymentUserAgentValues
    }

    /// Sets PMO SFU or SFU on the given `paymentIntentParams` object if the given `intentConfiguration` has SFU set / PMO SFU set for the given `paymentMethodType`.
    /// See https://docs.google.com/document/d/1AW8j-cJ9ZW5h-LapzXOYrrE2b1XtmVo_SnvbNf-asOU
    static func setSetupFutureUsage(for paymentMethodType: STPPaymentMethodType, intentConfiguration: IntentConfiguration, on paymentIntentParams: STPPaymentIntentConfirmParams) {
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
