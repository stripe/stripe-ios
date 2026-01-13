//
//  PaymentSheet+CheckoutSessionConfirmation.swift
//  StripePaymentSheet
//
//  Created by Porter Hampson on 1/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension PaymentSheet {

    /// Handles checkout session confirmation using ConfirmationTokens.
    /// This follows a similar pattern to deferred intent confirmation but calls the checkout session confirm endpoint.
    @MainActor
    static func handleCheckoutSessionConfirmation(
        confirmType: ConfirmPaymentMethodType,
        checkoutSession: CheckoutSessionResponse,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        elementsSession: STPElementsSession,
        confirmationChallenge: ConfirmationChallenge?
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        do {
            // 1. Create ConfirmationToken params
            let confirmationTokenParams = createCheckoutSessionConfirmationTokenParams(
                confirmType: confirmType,
                checkoutSession: checkoutSession,
                configuration: configuration,
                elementsSession: elementsSession
            )

            // 2. Get ephemeral key if needed for saved payment methods
//            let ephemeralKeySecret = getEphemeralKeyIfNeeded(
//                confirmType: confirmType,
//                configuration: configuration,
//                elementsSession: elementsSession
//            )

            // 3. Create ConfirmationToken
            let confirmationToken = try await configuration.apiClient.createConfirmationToken(
                with: confirmationTokenParams,
                ephemeralKeySecret: nil,
                additionalPaymentUserAgentValues: ["checkout-session"]
            )

            // 4. Extract session ID
            guard let sessionId = checkoutSession.sessionId else {
                throw PaymentSheetError.unknown(debugDescription: "Missing session_id in checkout session response")
            }

            // 5. Create client attribution metadata
            let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                intent: .checkoutSession(checkoutSession),
                elementsSession: elementsSession
            )

            // 6. Get passive captcha token if available (for card testing prevention)
            let paymentMethodType = checkoutSessionPaymentMethodType(from: confirmType)
            var passiveCaptchaToken: String?
            if paymentMethodType == .card || paymentMethodType == .link {
                let challengeTokens = await confirmationChallenge?.fetchTokensWithTimeout()
                passiveCaptchaToken = challengeTokens?.hcaptchaToken
            }

            // 7. Call confirm endpoint
            let confirmResponse = try await configuration.apiClient.confirmCheckoutSession(
                sessionId: sessionId,
                confirmationToken: confirmationToken.stripeId,
                expectedAmount: checkoutSession.amount,
                expectedPaymentMethodType: paymentMethodTypeString(from: confirmType),
                returnURL: configuration.returnURL,
                shipping: configuration.shippingDetails()?.paymentIntentShippingDetailsParams,
                clientAttributionMetadata: clientAttributionMetadata,
                passiveCaptchaToken: passiveCaptchaToken
            )

            // 8. Complete the confirmation challenge
            await confirmationChallenge?.complete()

            // 9. Handle the response
            return await handleConfirmResponse(
                confirmResponse: confirmResponse,
                checkoutSession: checkoutSession,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } catch {
            return (.failed(error: error), nil)
        }
    }

    // MARK: - Private Helpers

    private static func handleConfirmResponse(
        confirmResponse: CheckoutSessionConfirmResponse,
        checkoutSession: CheckoutSessionResponse,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        // Check if session has expired
        guard confirmResponse.status != .expired else {
            return (.failed(error: PaymentSheetError.unknown(debugDescription: "Checkout session has expired")), nil)
        }

        // Handle payment mode with PaymentIntent
        if checkoutSession.mode == .payment, let paymentIntent = confirmResponse.paymentIntent {
            return await handlePaymentIntent(
                paymentIntent: paymentIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        }

        // Handle setup mode with SetupIntent
        if let setupIntent = confirmResponse.setupIntent {
            return await handleSetupIntent(
                setupIntent: setupIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        }

        // If status is complete with paid/no_payment_required, we're done
        if confirmResponse.status == .complete {
            return (.completed, nil)
        }

        return (.failed(error: PaymentSheetError.unknown(debugDescription: "Unable to determine checkout session confirmation result")), nil)
    }

    private static func handlePaymentIntent(
        paymentIntent: STPPaymentIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        // Check if next action is required (e.g., 3DS)
        if paymentIntent.status == .requiresAction {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: paymentIntent,
                    with: authenticationContext,
                    returnURL: configuration.returnURL
                ) { status, _, error in
                    continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), nil))
                }
            }
        } else if paymentIntent.status == .succeeded || paymentIntent.status == .requiresCapture {
            return (.completed, nil)
        } else {
            return (.failed(error: PaymentSheetError.unknown(debugDescription: "Unexpected PaymentIntent status: \(paymentIntent.status.rawValue)")), nil)
        }
    }

    private static func handleSetupIntent(
        setupIntent: STPSetupIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> (result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        // Check if next action is required (e.g., 3DS)
        if setupIntent.status == .requiresAction {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: setupIntent,
                    with: authenticationContext,
                    returnURL: configuration.returnURL
                ) { status, _, error in
                    continuation.resume(returning: (makePaymentSheetResult(for: status, error: error), nil))
                }
            }
        } else if setupIntent.status == .succeeded {
            return (.completed, nil)
        } else {
            return (.failed(error: PaymentSheetError.unknown(debugDescription: "Unexpected SetupIntent status: \(setupIntent.status.rawValue)")), nil)
        }
    }

    /// Creates confirmation token params for checkout session confirmation.
    static func createCheckoutSessionConfirmationTokenParams(
        confirmType: ConfirmPaymentMethodType,
        checkoutSession: CheckoutSessionResponse,
        configuration: PaymentElementConfiguration,
        elementsSession: STPElementsSession
    ) -> STPConfirmationTokenParams {
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.returnURL = configuration.returnURL
        confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams

        // Configure payment method details based on confirm type
        switch confirmType {
        case .saved(let paymentMethod, let paymentOptions, let clientAttributionMetadata, _):
            confirmationTokenParams.paymentMethod = paymentMethod.stripeId
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata

        case .new(let paymentMethodParams, let paymentOptions, _, let shouldSave, _):
            // Always attach email for test purposes
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.email = "customer@example.com"  // Required!
            paymentMethodParams.billingDetails = billingDetails

            confirmationTokenParams.paymentMethodData = paymentMethodParams
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            confirmationTokenParams.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata

            // Set setup future usage if saving
            if shouldSave {
                confirmationTokenParams.setupFutureUsage = .offSession
            } else if let setupFutureUsageString = checkoutSession.setupFutureUsage {
                // Map string value to enum
                switch setupFutureUsageString.lowercased() {
                case "on_session":
                    confirmationTokenParams.setupFutureUsage = .onSession
                case "off_session":
                    confirmationTokenParams.setupFutureUsage = .offSession
                default:
                    break
                }
            }
        }

        // Set mandate data if required for the payment method type
        let paymentMethodType = Self.checkoutSessionPaymentMethodType(from: confirmType)
        if STPPaymentMethodType.requiresMandateDataForPaymentIntent.contains(paymentMethodType) {
            confirmationTokenParams.mandateData = .makeWithInferredValues()
        } else {
            // Fallback to auto-add functionality
            confirmationTokenParams.mandateData = STPPaymentIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
        }

        return confirmationTokenParams
    }

    /// Gets the payment method type string for the confirm endpoint.
    private static func paymentMethodTypeString(from confirmType: ConfirmPaymentMethodType) -> String {
        switch confirmType {
        case .saved(let paymentMethod, _, _, _):
            return STPPaymentMethod.string(from: paymentMethod.type) ?? "card"
        case .new(let params, _, _, _, _):
            return params.rawTypeString ?? "card"
        }
    }

    /// Extracts the payment method type from confirmation details.
    private static func checkoutSessionPaymentMethodType(from confirmType: ConfirmPaymentMethodType) -> STPPaymentMethodType {
        switch confirmType {
        case .saved(let paymentMethod, _, _, _):
            return paymentMethod.type
        case .new(let params, _, _, _, _):
            return params.type
        }
    }

    /// Gets ephemeral key if needed for saved payment methods.
    private static func getEphemeralKeyIfNeeded(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        elementsSession: STPElementsSession
    ) -> String? {
        guard case .saved(let paymentMethod, _, _, _) = confirmType else { return nil }

        // Link saved payment methods don't require ephemeral keys
        guard paymentMethod.card?.wallet?.type != .link,
              !paymentMethod.isLinkPaymentMethod,
              !paymentMethod.isLinkPassthroughMode,
              paymentMethod.link == nil else { return nil }

        return configuration.customer?.ephemeralKeySecret(basedOn: elementsSession)
    }
}
