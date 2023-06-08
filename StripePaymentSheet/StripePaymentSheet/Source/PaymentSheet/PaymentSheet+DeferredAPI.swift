//
//  PaymentSheet+DeferredAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    static func handleDeferredIntentConfirmation(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentSheet.Configuration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        // Hack: Add deferred to analytics product usage as a hack to get it into the payment_user_agent string in the request to create a PaymentMethod
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: IntentConfiguration.self)
        Task { @MainActor in
            do {
                var confirmType = confirmType
                // 1. Create PM if necessary
                let paymentMethod: STPPaymentMethod
                switch confirmType {
                case let .saved(savedPaymentMethod):
                    paymentMethod = savedPaymentMethod
                case let .new(params, newPaymentMethod, shouldSave):
                    assert(newPaymentMethod == nil)
                    paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params)
                    confirmType = .new(params: params, paymentMethod: paymentMethod, shouldSave: shouldSave)
                }

                // 2. Get Intent client secret from merchant
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 paymentMethod: paymentMethod,
                                                                                 shouldSavePaymentMethod: confirmType.shouldSave)
                guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    // Force close PaymentSheet and early exit
                    completion(.completed)
                    STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetForceSuccess)
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
                        let paymentIntentParams = makePaymentIntentParams(
                            confirmPaymentMethodType: confirmType,
                            paymentIntent: paymentIntent,
                            configuration: configuration
                        )
                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error))
                        }
                    } else {
                        // 4b. Server-side confirmation
                        paymentHandler.handleNextAction(
                            for: paymentIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error))
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
                            configuration: configuration
                        )
                        paymentHandler.confirmSetupIntent(
                            setupIntentParams,
                            with: authenticationContext
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error))
                        }
                    } else {
                        // 4b. Server-side confirmation
                        paymentHandler.handleNextAction(
                            for: setupIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, _, error in
                            completion(makePaymentSheetResult(for: status, error: error))
                        }
                    }
                }
            } catch {
                completion(.failed(error: error))
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
            let error = error ?? PaymentSheetError.unknown(debugDescription: "Unknown error occured while handling intent next action")
            return .failed(error: error)
        @unknown default:
            return .failed(error: PaymentSheetError.unknown(debugDescription: "Unrecognized STPPaymentHandlerActionStatus status"))
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
}

extension PaymentSheet.IntentConfiguration: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "deferred-intent"
    }
}
