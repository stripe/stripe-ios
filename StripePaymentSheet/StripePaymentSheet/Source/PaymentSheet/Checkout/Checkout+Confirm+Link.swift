//
//  Checkout+Confirm+Link.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/30/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension CheckoutController {
    // 😵😵😵 `LinkConfirmOption` represents both the beginning and the result of a Link wallet flow:
    //
    // | Option                | Link UI       | Meaning |
    // |-----------------------|---------------|---------|
    // | `.wallet`             | Native or web | Link is selected, but payment details have not been resolved. Open Link UI. |
    // | `.withPaymentDetails` | Native        | Native Link returned consumer payment details that still need conversion or sharing. |
    // | `.withPaymentMethod`  | Web           | Web Link returned a Stripe PaymentMethod. |
    // | `.signUp`             | Neither       | The customer entered a payment method in Payment Element and opted into Link inline. |
    //
    // Therefore, `.wallet` can begin a flow that later returns `.withPaymentDetails` or
    // `.withPaymentMethod`. A previously completed native selection can also enter confirmation
    // directly as `.withPaymentDetails`.
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
                    let confirmParams = IntentConfirmParams(
                        params: paymentMethodParams,
                        type: .stripe(paymentMethodParams.type)
                    )
                    confirmParams.saveForFutureUseCheckboxState = saveForFutureUseCheckboxState
                    let paymentMethodParameters = PaymentMethodConfirmationParameters(
                        option: .new(confirmParams),
                        configuration: configuration,
                        confirmationChallenge: confirmationChallenge,
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler
                    )
                    let result = await Self.confirmLinkPaymentMethod(
                        checkoutSession: checkoutSession,
                        parameters: paymentMethodParameters
                    )
                    if PaymentSheet.shouldLogOutOfLink(result: result.paymentSheetResult, elementsSession: elementsSession) {
                        linkAccount?.logout()
                    }
                    completion(result, nil)
                }
            }

            // Called when Link produces an existing/shared payment method, including Link web and passthrough share success.
            func confirmWithPaymentMethod(
                paymentMethod: STPPaymentMethod,
                linkAccount: PaymentSheetLinkAccount?,
                saveForFutureUseCheckboxState: IntentConfirmParams.SaveForFutureUseCheckboxState,
                linkClientAttributionMetadata _: STPClientAttributionMetadata?
            ) {
                Task { @MainActor in
                    let paymentMethodParameters = PaymentMethodConfirmationParameters(
                        option: .saved(paymentMethod, nil),
                        configuration: configuration,
                        confirmationChallenge: confirmationChallenge,
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler
                    )
                    let result = await Self.confirmLinkPaymentMethod(
                        checkoutSession: checkoutSession,
                        parameters: paymentMethodParameters
                    )
                    if PaymentSheet.shouldLogOutOfLink(result: result.paymentSheetResult, elementsSession: elementsSession) {
                        linkAccount?.logout()
                    }
                    await confirmationChallenge?.complete()
                    completion(result, nil)
                }
            }

            // Link wallet UI calls this with its result:
            // - native Link returns `.link(.withPaymentDetails)`
            // - web Link returns `.link(.withPaymentMethod)`.
            // Route the result back through Checkout confirmation.
            func confirmHandler(
                linkAuthenticationContext: STPAuthenticationContext,
                intent: Intent,
                elementsSession: STPElementsSession,
                linkPaymentOption: PaymentOption,
                linkCompletion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
            ) {
                Task { @MainActor in
                    guard case .link(let confirmOption) = linkPaymentOption else {
                        let error = PaymentSheetError.confirmingWithInvalidPaymentOption
                        stpAssertionFailure("Link returned an unsupported Checkout confirmation option.")
                        linkCompletion(.failed(error: error), nil)
                        return
                    }
                    let result = await Self.confirmLink(
                        checkoutSession: checkoutSession,
                        parameters: LinkConfirmationParameters(
                            confirmOption: confirmOption,
                            configuration: configuration,
                            confirmationChallenge: confirmationChallenge,
                            analyticsHelper: parameters.analyticsHelper,
                            authenticationContext: linkAuthenticationContext,
                            paymentHandler: parameters.paymentHandler
                        )
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

    /// Confirms a payment method produced by Link using the shared Checkout Session flow.
    @MainActor
    private static func confirmLinkPaymentMethod(
        checkoutSession: Session,
        parameters: PaymentMethodConfirmationParameters
    ) async -> InternalConfirmResult {
        do {
            let requestParameters = try await makeConfirmationRequestParameters(
                for: parameters,
                checkoutSession: checkoutSession,
                preconfirmedIntentParams: nil
            )
            return await confirmCheckoutSession(
                with: requestParameters,
                apiClient: parameters.configuration.apiClient,
                authenticationContext: parameters.authenticationContext,
                paymentHandler: parameters.paymentHandler
            )
        } catch {
            return .failed(error)
        }
    }

}
