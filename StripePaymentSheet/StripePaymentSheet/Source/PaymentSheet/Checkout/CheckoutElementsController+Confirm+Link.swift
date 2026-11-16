//
//  CheckoutElementsController+Confirm+Link.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/30/26.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

extension CheckoutElementsController {
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
        parameters: LinkConfirmationParameters,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater? = nil,
        currentSession: (@MainActor () -> Session?)? = nil
    ) async -> InternalConfirmResult {
        // Native Link can update its total while it's open, so it may change the session's tax region.
        // Read the latest session when confirming so the expected amount matches what the customer saw.
        let latestSession: () -> Session = {
            currentSession?() ?? checkoutSession
        }
        let linkTotalUpdater = makeLinkTotalUpdater(
            checkoutSession: checkoutSession,
            parameters: parameters,
            checkoutWalletUpdater: checkoutWalletUpdater,
            latestSession: latestSession
        )
        let initialTaxRegion = checkoutWalletUpdater?.currentTaxRegion
        let result = await confirmLink(
            checkoutSession: checkoutSession,
            parameters: parameters,
            checkoutWalletUpdater: checkoutWalletUpdater,
            latestSession: latestSession,
            linkTotalUpdater: linkTotalUpdater
        )
        if let linkTotalUpdater, let checkoutWalletUpdater, case .canceled = result {
            // Mirror Apple Pay: if the customer leaves Link, restore the tax region they started with.
            await linkTotalUpdater.waitUntilIdle()
            if checkoutWalletUpdater.currentTaxRegion != initialTaxRegion {
                _ = try? await checkoutWalletUpdater.updateTaxRegionWithoutEnqueueing(
                    address: initialTaxRegion,
                    canUpdateWhileSheetPresented: true,
                    confirmationSource: parameters.attribution.confirmingElement
                )
            }
        }
        return result
    }

    /// Creates an updater that recalculates tax while native Link is open, if the session's tax depends on the billing address.
    @MainActor
    private static func makeLinkTotalUpdater(
        checkoutSession: Session,
        parameters: LinkConfirmationParameters,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater?,
        latestSession: @escaping () -> Session
    ) -> LinkTotalUpdater? {
        guard let checkoutWalletUpdater,
              case .wallet = parameters.confirmOption,
              checkoutSession.collectsTaxFromBillingAddress,
              deviceCanUseNativeLink(elementsSession: checkoutSession.elementsSession, configuration: parameters.configuration) else {
            return nil
        }
        let confirmationSource = parameters.attribution.confirmingElement
        return LinkTotalUpdater(amount: checkoutSession.amount) { [weak checkoutWalletUpdater] billingAddress in
            guard let checkoutWalletUpdater else {
                throw CheckoutError.unknown(debugDescription: "Checkout was deallocated while Link was open.")
            }
            guard let country = billingAddress?.countryCode?.nonEmpty else {
                // Without a country there's nothing to calculate tax from.
                return latestSession().amount
            }
            let address = Address(
                country: country,
                line1: billingAddress?.line1?.nonEmpty,
                line2: billingAddress?.line2?.nonEmpty,
                city: billingAddress?.city?.nonEmpty,
                state: billingAddress?.state?.nonEmpty,
                postalCode: billingAddress?.postalCode?.nonEmpty
            )
            guard address != checkoutWalletUpdater.currentTaxRegion else {
                return latestSession().amount
            }
            let session = try await checkoutWalletUpdater.updateTaxRegionWithoutEnqueueing(
                address: address,
                canUpdateWhileSheetPresented: true,
                confirmationSource: confirmationSource
            )
            return session.amount
        }
    }

    private static func confirmLink(
        checkoutSession: Session,
        parameters: LinkConfirmationParameters,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater?,
        latestSession: @escaping () -> Session,
        linkTotalUpdater: LinkTotalUpdater?
    ) async -> InternalConfirmResult {
        let elementsSession = checkoutSession.elementsSession
        let configuration = parameters.configuration
        let confirmationChallenge = parameters.confirmationChallenge
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            checkoutSession: checkoutSession,
            attribution: parameters.attribution
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
            // An attempt can fail while the wallet stays open. Keep its session update, but let
            // the wallet's final result determine whether Checkout completed, canceled, or failed.
            var latestSessionResponse: CheckoutClientAPIResponse?

            func resultWithSessionResponse(_ result: PaymentSheetResult) -> InternalConfirmResult {
                switch result {
                case .completed:
                    if let latestSessionResponse {
                        return .completed(latestSessionResponse)
                    }
                    let error = CheckoutError.unknown(
                        debugDescription: "Link completed Checkout confirmation without returning the confirmed session."
                    )
                    stpAssertionFailure(error.nonGenericDescription)
                    return .failed(error)
                case .canceled:
                    return .canceled(sessionResponse: latestSessionResponse)
                case .failed(let error):
                    return .failed(error, sessionResponse: latestSessionResponse)
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
                        returnURL: parameters.returnURL,
                        nativeSheetPresentation: parameters.nativeSheetPresentation,
                        confirmationChallenge: confirmationChallenge,
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler,
                        attribution: parameters.attribution
                    )
                    let result = await Self.confirmLinkPaymentMethod(
                        checkoutSession: latestSession(),
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
                        returnURL: parameters.returnURL,
                        nativeSheetPresentation: parameters.nativeSheetPresentation,
                        confirmationChallenge: confirmationChallenge,
                        authenticationContext: parameters.authenticationContext,
                        paymentHandler: parameters.paymentHandler,
                        attribution: parameters.attribution
                    )
                    let result = await Self.confirmLinkPaymentMethod(
                        checkoutSession: latestSession(),
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
                        checkoutSession: latestSession(),
                        parameters: LinkConfirmationParameters(
                            confirmOption: confirmOption,
                            configuration: configuration,
                            returnURL: parameters.returnURL,
                            nativeSheetPresentation: parameters.nativeSheetPresentation,
                            confirmationChallenge: confirmationChallenge,
                            analyticsHelper: parameters.analyticsHelper,
                            authenticationContext: linkAuthenticationContext,
                            paymentHandler: parameters.paymentHandler,
                            attribution: parameters.attribution
                        ),
                        checkoutWalletUpdater: checkoutWalletUpdater,
                        currentSession: { latestSession() }
                    )
                    if let response = result.checkoutSessionResponse {
                        latestSessionResponse = response
                    }
                    linkCompletion(result.paymentSheetResult, nil)
                }
            }

            PaymentSheet.confirmLinkPaymentOption(
                confirmOption: parameters.confirmOption,
                configuration: configuration,
                paymentHandler: parameters.paymentHandler,
                nativeSheetPresentation: parameters.nativeSheetPresentation,
                authenticationContext: parameters.authenticationContext,
                intent: .checkout(checkoutSession),
                elementsSession: elementsSession,
                // Link controllers still require PaymentSheet analytics; keep that coupling on this typed path.
                analyticsHelper: parameters.analyticsHelper,
                confirmationChallenge: confirmationChallenge,
                clientAttributionMetadata: clientAttributionMetadata,
                linkTotalUpdater: linkTotalUpdater,
                isSettingUp: isSettingUp,
                setAllowRedisplay: setAllowRedisplay,
                confirmWithPaymentMethodParams: confirmWithPaymentMethodParams(paymentMethodParams:linkAccount:saveForFutureUseCheckboxState:),
                confirmWithPaymentMethod: confirmWithPaymentMethod(paymentMethod:linkAccount:saveForFutureUseCheckboxState:linkClientAttributionMetadata:),
                confirmHandler: confirmHandler(linkAuthenticationContext:intent:elementsSession:linkPaymentOption:linkCompletion:),
                paymentHandlerCompletion: { status, error in
                    completion(resultWithSessionResponse(PaymentSheet.makePaymentSheetResult(for: status, error: error)), nil)
                },
                completion: { result, confirmationType in
                    completion(resultWithSessionResponse(result), confirmationType)
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
        let requestParameters = await makeConfirmationRequestParameters(
            for: parameters,
            checkoutSession: checkoutSession,
            preconfirmedIntentParams: nil
        )
        return await confirmCheckoutSession(
            with: requestParameters,
            apiClient: parameters.configuration.apiClient,
            authenticationContext: parameters.authenticationContext,
            paymentHandler: parameters.paymentHandler,
            confirmationChallenge: requestParameters.paymentMethodData == nil ? nil : parameters.confirmationChallenge
        )
    }

}
