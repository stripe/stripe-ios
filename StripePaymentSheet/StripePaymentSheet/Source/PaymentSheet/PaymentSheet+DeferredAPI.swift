//
//  PaymentSheet+DeferredAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/23.
//

import Foundation
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
        Task {
            do {
                // Create PM if necessary
                let paymentMethod = try await createPaymentMethodIfNeeded(apiClient: deferredIntentContext.configuration.apiClient,
                                                                           paymentMethod: paymentMethod,
                                                                           paymentMethodParams: paymentMethodParams)
                // Get Intent client secret from merchant
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: deferredIntentContext.intentConfig,
                                                                                 paymentMethodID: paymentMethod.stripeId,
                                                                                 shouldSavePaymentMethod: shouldSavePaymentMethod)
                // Finish confirmation
                if deferredIntentContext.isServerSideConfirmation {
                    // Server-side confirmation
                    func handleStatus(status: STPPaymentHandlerActionStatus, error: Error?) {
                        switch status {
                        case .succeeded:
                            deferredIntentContext.completion(.completed)
                        case .canceled:
                            deferredIntentContext.completion(.canceled)
                        case .failed:
                            let error = error ?? PaymentSheetError.unknown(debugDescription: "Unknown error occured while handling intent next action")
                            deferredIntentContext.completion(.failed(error: error))
                        @unknown default:
                            deferredIntentContext.completion(.failed(error: PaymentSheetError.unknown(debugDescription: "Unrecognized intent status")))
                        }
                    }

                    switch deferredIntentContext.intentConfig.mode {
                    case .payment:
                        deferredIntentContext.paymentHandler.handleNextAction(forPayment: clientSecret,
                                                                        with: deferredIntentContext.authenticationContext,
                                                                        returnURL: deferredIntentContext.configuration.returnURL,
                                                                        completion: { status, _, error in
                            handleStatus(status: status, error: error)
                        })
                    case .setup:
                        deferredIntentContext.paymentHandler.handleNextAction(forSetupIntent: clientSecret,
                                                                        with: deferredIntentContext.authenticationContext,
                                                                        returnURL: deferredIntentContext.configuration.returnURL,
                                                                        completion: { status, _, error in
                            handleStatus(status: status, error: error)
                        })
                    }
                } else {
                    // Client-side confirmation
                    // TODO(porter) Future optimization: Only fetch intent when strictly requried
                    let intent = try await deferredIntentContext.configuration.apiClient.retrieveIntent(for: deferredIntentContext.intentConfig,
                                                                                                        withClientSecret: clientSecret)
                    confirm(configuration: deferredIntentContext.configuration,
                            authenticationContext: deferredIntentContext.authenticationContext,
                            intent: intent,
                            paymentOption: deferredIntentContext.paymentOption,
                            paymentHandler: deferredIntentContext.paymentHandler,
                            completion: deferredIntentContext.completion)
                }

            } catch {
                deferredIntentContext.completion(.failed(error: error))
            }
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

    var isServerSideConfirmation: Bool {
        return intentConfig.confirmHandlerForServerSideConfirmation != nil
    }

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
