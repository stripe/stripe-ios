//
//  PaymentSheet+DeferredAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/23.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    static func createPaymentMethodIfNeeded(apiClient: STPAPIClient,
                                            paymentMethod: STPPaymentMethod?,
                                            paymentMethodParams: STPPaymentMethodParams?) async throws -> STPPaymentMethod {
        if let paymentMethod = paymentMethod {
            return paymentMethod
        }

        guard let paymentMethodParams = paymentMethodParams else {
            throw PaymentSheetError.unknown(debugDescription: "paymentMethodParams unexpectedly nil")
        }
        return try await apiClient.createPaymentMethod(with: paymentMethodParams)
    }

    static func handleDeferredIntentConfirmation(deferredIntentContext: DeferredIntentContext,
                                                 paymentMethod: STPPaymentMethod?,
                                                 paymentMethodParams: STPPaymentMethodParams?,
                                                 shouldSavePaymentMethod: Bool) {
        // Hack: Add deferred to analytics product usage as a hack to get it into the payment_user_agent string in the request to create a PaymentMethod
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: IntentConfiguration.self)
        Task {
            do {
                // 1. Create PM if necessary
                let paymentMethod = try await createPaymentMethodIfNeeded(apiClient: deferredIntentContext.configuration.apiClient,
                                                                           paymentMethod: paymentMethod,
                                                                           paymentMethodParams: paymentMethodParams)
                // 2. Get Intent client secret from merchant
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: deferredIntentContext.intentConfig,
                                                                                 paymentMethodID: paymentMethod.stripeId,
                                                                                 shouldSavePaymentMethod: shouldSavePaymentMethod)
                guard clientSecret != IntentConfiguration.FORCE_SUCCESS else {
                    // Force close PaymentSheet and early exit
                    deferredIntentContext.completion(.completed)
                    STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetForceSuccess)
                    return
                }

                // 3. Retrieve the PaymentIntent or SetupIntent
                switch deferredIntentContext.intentConfig.mode {
                case .payment:
                    let paymentIntent = try await deferredIntentContext.configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret)
                    // Check if it needs confirmation
                    if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                        // 4a. Client-side confirmation
                        confirm(configuration: deferredIntentContext.configuration,
                                authenticationContext: deferredIntentContext.authenticationContext,
                                intent: .paymentIntent(paymentIntent),
                                paymentOption: deferredIntentContext.paymentOption,
                                paymentHandler: deferredIntentContext.paymentHandler,
                                paymentMethodID: paymentMethod.stripeId,
                                completion: deferredIntentContext.completion)
                    } else {
                       // 4b. Server-side confirmation
                        // TODO: Make a new handleNextAction version that takes a STPPaymentIntent to avoid re-fetching
                        deferredIntentContext.paymentHandler.handleNextAction(
                            forPayment: clientSecret,
                            with: deferredIntentContext.authenticationContext,
                            returnURL: deferredIntentContext.configuration.returnURL
                        ) { status, _, error in
                            deferredIntentContext.completion(paymentSheetResult(forPaymentHandlerActionStatus: status, error: error))
                        }
                    }
                case .setup:
                    let setupIntent = try await deferredIntentContext.configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret)
                    if [STPSetupIntentStatus.requiresPaymentMethod, STPSetupIntentStatus.requiresConfirmation].contains(setupIntent.status) {
                        // 4a. Client-side confirmation
                        confirm(configuration: deferredIntentContext.configuration,
                                authenticationContext: deferredIntentContext.authenticationContext,
                                intent: .setupIntent(setupIntent),
                                paymentOption: deferredIntentContext.paymentOption,
                                paymentHandler: deferredIntentContext.paymentHandler,
                                paymentMethodID: paymentMethod.stripeId,
                                completion: deferredIntentContext.completion)
                    } else {
                        // 4b. Server-side confirmation
                        // TODO: Make a new handleNextAction version that takes an STPSetupIntent to avoid re-fetching
                        deferredIntentContext.paymentHandler.handleNextAction(
                            forSetupIntent: clientSecret,
                            with: deferredIntentContext.authenticationContext,
                            returnURL: deferredIntentContext.configuration.returnURL
                        ) { status, _, error in
                            deferredIntentContext.completion(paymentSheetResult(forPaymentHandlerActionStatus: status, error: error))
                        }
                    }
                }
            } catch {
                deferredIntentContext.completion(.failed(error: error))
            }
        }
    }

    // MARK: - Helper methods

    /// Convenience method that converts a STPPayymentHandlerActionStatus + error into a PaymentSheetResult
    static func paymentSheetResult(forPaymentHandlerActionStatus status: STPPaymentHandlerActionStatus, error: Error?) -> PaymentSheetResult {
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

    static func fetchIntentClientSecretFromMerchant(intentConfig: IntentConfiguration,
                                                    paymentMethodID: String,
                                                    shouldSavePaymentMethod: Bool) async throws -> String {
      try await withCheckedThrowingContinuation { continuation in

          if let confirmHandlerForServerSideConfirmation = intentConfig.confirmHandlerForServerSideConfirmation {
              DispatchQueue.main.async {
                  confirmHandlerForServerSideConfirmation(paymentMethodID, shouldSavePaymentMethod, { result in
                      continuation.resume(with: result)
                  })
              }
          } else if let confirmHandler = intentConfig.confirmHandler {
              DispatchQueue.main.async {
                  confirmHandler(paymentMethodID, { result in
                      continuation.resume(with: result)
                  })
              }
          }
      }
    }
}

/// Convenience class to avoid passing long argument lists when confirming deferred intents
class DeferredIntentContext {
    let configuration: PaymentSheet.Configuration
    let intentConfig: PaymentSheet.IntentConfiguration
    let paymentOption: PaymentOption
    let authenticationContext: STPAuthenticationContext
    let paymentHandler: STPPaymentHandler
    let completion: PaymentSheetResultCompletionBlock

    init(configuration: PaymentSheet.Configuration,
         intentConfig: PaymentSheet.IntentConfiguration,
         paymentOption: PaymentOption,
         authenticationContext: STPAuthenticationContext,
         paymentHandler: STPPaymentHandler,
         completion: @escaping PaymentSheetResultCompletionBlock) {
        self.configuration = configuration
        self.intentConfig = intentConfig
        self.paymentOption = paymentOption
        self.authenticationContext = authenticationContext
        self.paymentHandler = paymentHandler
        // Always invoke completion handler on main thread
        self.completion = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

extension PaymentSheet.IntentConfiguration: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "deferred-intent"
    }
}
