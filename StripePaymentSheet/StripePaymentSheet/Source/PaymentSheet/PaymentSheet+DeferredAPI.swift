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
        configuration: PaymentSheet.Configuration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        mandateData: STPMandateDataParams? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            do {
                var confirmType = confirmType
                // 1. Create PM if necessary
                let paymentMethod: STPPaymentMethod
                switch confirmType {
                case let .saved(savedPaymentMethod):
                    paymentMethod = savedPaymentMethod
                case let .new(params, paymentOptions, newPaymentMethod, shouldSave):
                    assert(newPaymentMethod == nil)
                    paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params, additionalPaymentUserAgentValues: makeDeferredPaymentUserAgentValue(intentConfiguration: intentConfig))
                    confirmType = .new(params: params, paymentOptions: paymentOptions, paymentMethod: paymentMethod, shouldSave: shouldSave)
                }

                // 2. Get Intent client secret from merchant
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 paymentMethod: paymentMethod,
                                                                                 shouldSavePaymentMethod: confirmType.shouldSave)
                guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    // Force close PaymentSheet and early exit
                    completion(.completed, STPAnalyticsClient.DeferredIntentConfirmationType.none)
                    return
                }

                // 3. Retrieve the PaymentIntent or SetupIntent
                switch intentConfig.mode {
                case .payment:
                    let paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])
                    // Check if it needs confirmation
                    if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                        // 4a. Client-side confirmation
                        try PaymentSheetDeferredValidator.validate(paymentIntent: paymentIntent, intentConfiguration: intentConfig, isFlowController: isFlowController)
                        var paymentIntentParams = makePaymentIntentParams(
                            confirmPaymentMethodType: confirmType,
                            paymentIntent: paymentIntent,
                            configuration: configuration,
                            mandateData: mandateData
                        )

                        // Dashboard specfic logic
                        if configuration.apiClient.publishableKeyIsUserKey {
                            paymentIntentParams = setParamsForDashboardApp(confirmType: confirmType,
                                                                           paymentIntentParams: paymentIntentParams,
                                                                           paymentIntent: paymentIntent,
                                                                           configuration: configuration)
                        }

                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error), .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        paymentHandler.handleNextAction(
                            for: paymentIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error), .server)
                        }
                    }
                case .setup:
                    let setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret, expand: ["payment_method"])
                    if [STPSetupIntentStatus.requiresPaymentMethod, STPSetupIntentStatus.requiresConfirmation].contains(setupIntent.status) {
                        // 4a. Client-side confirmation
                        try PaymentSheetDeferredValidator.validate(setupIntent: setupIntent, intentConfiguration: intentConfig)
                        let setupIntentParams = makeSetupIntentParams(
                            confirmPaymentMethodType: confirmType,
                            setupIntent: setupIntent,
                            configuration: configuration,
                            mandateData: mandateData
                        )
                        paymentHandler.confirmSetupIntent(
                            setupIntentParams,
                            with: authenticationContext
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error), .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        paymentHandler.handleNextAction(
                            for: setupIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error), .server)
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
            DispatchQueue.main.async {
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

    static func setParamsForDashboardApp(confirmType: ConfirmPaymentMethodType,
                                         paymentIntentParams: STPPaymentIntentParams,
                                         paymentIntent: STPPaymentIntent,
                                         configuration: PaymentSheet.Configuration) -> STPPaymentIntentParams {
        var intentParamsCopy = paymentIntentParams
        switch confirmType {
        case .saved:
            // The Dashboard app requires MOTO
            intentParamsCopy.paymentMethodOptions = intentParamsCopy.paymentMethodOptions == nil ? .init() : intentParamsCopy.paymentMethodOptions
            intentParamsCopy.paymentMethodOptions?.setMoto()
        case .new(_, _, let paymentMethod, let shouldSave):
            // The Dashboard app cannot pass `paymentMethodParams` ie payment_method_data
            intentParamsCopy = IntentConfirmParams.makeDashboardParams(
                paymentIntentClientSecret: paymentIntent.clientSecret,
                paymentMethodID: paymentMethod?.stripeId ?? "",
                shouldSave: shouldSave,
                paymentMethodType: paymentMethod?.type ?? .unknown,
                customer: configuration.customer
            )
            intentParamsCopy.shipping = makeShippingParams(
                for: paymentIntent,
                configuration: configuration
            )
        }

        return intentParamsCopy
    }
}
