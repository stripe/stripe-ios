//
//  Checkout+Confirm+Link.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/30/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension CheckoutController {
    static func confirmLink(
        checkoutSession: Session,
        parameters: LinkConfirmationParameters
    ) async -> InternalConfirmResult {
        let elementsSession = checkoutSession.elementsSession
        let configuration = parameters.configuration
        let confirmationChallenge = parameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: elementsSession
        )
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
            // TODO: Have the Link confirmation callback return InternalConfirmResult for Checkout so the
            // confirmed session doesn't need to be passed through this side channel.
            var linkCompletionResult: InternalConfirmResult?

            func resultWithoutSessionResponse(_ result: PaymentSheetResult) -> InternalConfirmResult {
                switch result {
                case .completed:
                    let error = CheckoutError.unknown(
                        debugDescription: "Link completed Checkout confirmation without returning the confirmed session."
                    )
                    stpAssertionFailure(error.nonGenericDescription)
                    return .failed(error)
                case .canceled:
                    return .canceled()
                case .failed(let error):
                    return .failed(error)
                }
            }

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
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler,
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
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler,
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
                    let option: PaymentMethodConfirmationParameters.Option
                    switch linkPaymentOption {
                    case .new(let confirmParams):
                        option = .new(confirmParams)
                    case .saved(let paymentMethod, let confirmParams):
                        option = .saved(paymentMethod, confirmParams)
                    case .link(let nestedConfirmOption):
                        // Link's own UI can recursively resolve to another Link confirm option
                        // (e.g. wallet -> withPaymentDetails); confirm it the same way as the
                        // original Link selection.
                        let nestedParameters = LinkConfirmationParameters(
                            confirmOption: nestedConfirmOption,
                            configuration: configuration,
                            confirmationChallenge: confirmationChallenge,
                            analyticsHelper: parameters.analyticsHelper,
                            authenticationContext: linkAuthenticationContext,
                            paymentHandler: parameters.paymentHandler
                        )
                        let result = await Self.confirmLink(checkoutSession: checkoutSession, parameters: nestedParameters)
                        linkCompletionResult = result
                        linkCompletion(result.paymentSheetResult, nil)
                        return
                    case .applePay, .external:
                        let error = PaymentSheetError.confirmingWithInvalidPaymentOption
                        stpAssertionFailure("Link returned an unsupported Checkout confirmation option.")
                        linkCompletion(.failed(error: error), nil)
                        return
                    }
                    let paymentMethodParameters = CheckoutController.PaymentMethodConfirmationParameters(
                        option: option,
                        configuration: configuration,
                        confirmationChallenge: confirmationChallenge,
                        authenticationContext: linkAuthenticationContext,
                        paymentHandler: parameters.paymentHandler
                    )
                    // Link has already completed its own UI; recurse only into the conventional PM engine.
                    let result = await Self.confirmPaymentMethodOption(
                        checkoutSession: checkoutSession,
                        parameters: paymentMethodParameters,
                        intentConfirmParamsForDeferredIntent: nil
                    )
                    linkCompletionResult = result
                    linkCompletion(result.paymentSheetResult, nil)
                }
            }

            PaymentSheet.confirmLinkPaymentOption(
                confirmOption: parameters.confirmOption,
                configuration: configuration,
                authenticationContext: parameters.authenticationContext,
                intent: .checkout(checkoutSession),
                elementsSession: elementsSession,
                // Link controllers still require PaymentSheet analytics; keep that coupling on this typed path.
                analyticsHelper: parameters.analyticsHelper,
                confirmationChallenge: confirmationChallenge,
                clientAttributionMetadata: clientAttributionMetadata,
                isSettingUp: isSettingUp,
                setAllowRedisplay: setAllowRedisplay,
                confirmWithPaymentMethodParams: confirmWithPaymentMethodParams(paymentMethodParams:linkAccount:saveForFutureUseCheckboxState:),
                confirmWithPaymentMethod: confirmWithPaymentMethod(paymentMethod:linkAccount:saveForFutureUseCheckboxState:linkClientAttributionMetadata:),
                confirmHandler: confirmHandler(linkAuthenticationContext:intent:elementsSession:linkPaymentOption:linkCompletion:),
                paymentHandlerCompletion: { status, error in
                    completion(resultWithoutSessionResponse(PaymentSheet.makePaymentSheetResult(for: status, error: error)), nil)
                },
                completion: { result, confirmationType in
                    if let internalResult = linkCompletionResult {
                        completion(internalResult, confirmationType)
                    } else {
                        completion(resultWithoutSessionResponse(result), confirmationType)
                    }
                }
            )
        }
    }

}
