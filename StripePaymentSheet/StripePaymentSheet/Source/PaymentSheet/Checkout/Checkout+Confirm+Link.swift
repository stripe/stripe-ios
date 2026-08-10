//
//  Checkout+Confirm+Link.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/30/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {
    static func confirmLink(
        checkout: Checkout,
        confirmationContext: ConfirmationContext,
        authenticationContext: STPAuthenticationContext,
        clientAttributionMetadata: STPClientAttributionMetadata,
        paymentHandler: STPPaymentHandler
    ) async -> InternalConfirmResult {
        guard case .link(let confirmOption) = confirmationContext.paymentOption else {
            stpAssertionFailure("confirmLink called with a non-Link payment option.")
            return .init(paymentSheetResult: .failed(error: PaymentSheetError.confirmingWithInvalidPaymentOption))
        }

        let checkoutSession = checkout.session
        let elementsSession = checkoutSession.elementsSession
        let configuration = confirmationContext.configuration
        let confirmationChallenge = confirmationContext.confirmationChallenge
        let isSettingUp: (STPPaymentMethodType) -> Bool = { paymentMethodType in
            checkoutSession.merchantWillSavePaymentMethod(paymentMethodType)
        }
        let setAllowRedisplay: (IntentConfirmParams, STPPaymentMethodType) -> Void = { confirmParams, paymentMethodType in
            confirmParams.setAllowRedisplayForCheckoutSession(
                merchantWillSavePaymentMethod: checkoutSession.merchantWillSavePaymentMethod(paymentMethodType)
            )
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<InternalConfirmResult, Never>) in
            let completion: (InternalConfirmResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void = { result, _ in
                continuation.resume(returning: result)
            }
            var linkCompletionResult: InternalConfirmResult?

            // Called when Link produces raw payment method params, including signup fallback/direct confirm paths.
            func confirmWithPaymentMethodParams(
                paymentMethodParams: STPPaymentMethodParams,
                linkAccount: PaymentSheetLinkAccount?,
                saveForFutureUseCheckboxState: IntentConfirmParams.SaveForFutureUseCheckboxState
            ) {
                Task { @MainActor in
                    paymentMethodParams.radarOptions = await confirmationChallenge?.makeRadarOptions(for: paymentMethodParams.type)
                    paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
                    let result = await Self.handleCheckoutSessionConfirmation(
                        checkoutSession: checkoutSession,
                        confirmType: .new(
                            params: paymentMethodParams,
                            paymentOptions: STPConfirmPaymentMethodOptions(),
                            saveForFutureUseCheckboxState: saveForFutureUseCheckboxState
                        ),
                        configuration: configuration,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        elementsSession: elementsSession
                    )
                    if PaymentSheet.shouldLogOutOfLink(result: result.paymentSheetResult, elementsSession: elementsSession) {
                        linkAccount?.logout()
                    }
                    await confirmationChallenge?.complete()
                    completion(result, nil)
                }
            }

            // Called when Link produces an existing/shared payment method, including Link web and passthrough share success.
            func confirmWithPaymentMethod(
                paymentMethod: STPPaymentMethod,
                linkAccount: PaymentSheetLinkAccount?,
                saveForFutureUseCheckboxState: IntentConfirmParams.SaveForFutureUseCheckboxState,
                linkClientAttributionMetadata: STPClientAttributionMetadata?
            ) {
                Task { @MainActor in
                    let radarOptions = await confirmationChallenge?.makeRadarOptions(for: paymentMethod.type)
                    let result = await Self.handleCheckoutSessionConfirmation(
                        checkoutSession: checkoutSession,
                        confirmType: .saved(
                            paymentMethod,
                            paymentOptions: nil,
                            clientAttributionMetadata: linkClientAttributionMetadata,
                            radarOptions: radarOptions
                        ),
                        configuration: configuration,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        elementsSession: elementsSession
                    )
                    if PaymentSheet.shouldLogOutOfLink(result: result.paymentSheetResult, elementsSession: elementsSession) {
                        linkAccount?.logout()
                    }
                    await confirmationChallenge?.complete()
                    completion(result, nil)
                }
            }

            // Called when Link UI returns a payment option that Checkout should confirm recursively.
            func confirmHandler(
                linkAuthenticationContext: STPAuthenticationContext,
                intent: Intent,
                elementsSession: STPElementsSession,
                linkPaymentOption: PaymentOption,
                linkCompletion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
            ) {
                Task { @MainActor in
                    let linkConfirmationContext = Checkout.ConfirmationContext(
                        paymentOption: linkPaymentOption,
                        configuration: configuration,
                        integrationShape: confirmationContext.integrationShape,
                        confirmationChallenge: confirmationChallenge,
                        analyticsHelper: confirmationContext.analyticsHelper
                    )
                    let result = await Self.confirmPaymentOption(
                        checkout: checkout,
                        confirmationContext: linkConfirmationContext,
                        authenticationContext: linkAuthenticationContext,
                        intentConfirmParamsForDeferredIntent: nil,
                        paymentHandler: paymentHandler
                    )
                    linkCompletionResult = result
                    linkCompletion(result.paymentSheetResult, nil)
                }
            }

            PaymentSheet.confirmLinkPaymentOption(
                confirmOption: confirmOption,
                configuration: configuration,
                authenticationContext: authenticationContext,
                intent: .checkout(checkoutSession),
                elementsSession: elementsSession,
                analyticsHelper: confirmationContext.analyticsHelper,
                confirmationChallenge: confirmationChallenge,
                clientAttributionMetadata: clientAttributionMetadata,
                isSettingUp: isSettingUp,
                setAllowRedisplay: setAllowRedisplay,
                confirmWithPaymentMethodParams: confirmWithPaymentMethodParams(paymentMethodParams:linkAccount:saveForFutureUseCheckboxState:),
                confirmWithPaymentMethod: confirmWithPaymentMethod(paymentMethod:linkAccount:saveForFutureUseCheckboxState:linkClientAttributionMetadata:),
                confirmHandler: confirmHandler(linkAuthenticationContext:intent:elementsSession:linkPaymentOption:linkCompletion:),
                paymentHandlerCompletion: { status, error in
                    completion(.init(paymentSheetResult: PaymentSheet.makePaymentSheetResult(for: status, error: error)), nil)
                },
                completion: { result, confirmationType in
                    if let internalResult = linkCompletionResult {
                        completion(internalResult, confirmationType)
                    } else {
                        completion(.init(paymentSheetResult: result), confirmationType)
                    }
                }
            )
        }
    }

}
