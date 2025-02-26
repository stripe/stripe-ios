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
    static func handleDeferredIntentConfirmation(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        mandateData: STPMandateDataParams? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            do {
                var confirmType = confirmType
                // 1. Create PM if necessary
                let paymentMethod: STPPaymentMethod
                switch confirmType {
                case let .saved(savedPaymentMethod, _):
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

                // 2. Get Intent client secret from merchant
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 paymentMethod: paymentMethod,
                                                                                 shouldSavePaymentMethod: confirmType.shouldSave)
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
                            mandateData: mandateData
                        )

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
                            mandateData: mandateData
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

    // MARK: - Helper methods

    /// Convenience method that converts a STPPayymentHandlerActionStatus + error into a PaymentSheetResult
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
                intentConfig.confirmHandler(paymentMethod, shouldSavePaymentMethod) { result in
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
}
