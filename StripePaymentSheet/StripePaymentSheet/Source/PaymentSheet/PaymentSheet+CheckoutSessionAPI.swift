//
//  PaymentSheet+CheckoutSessionAPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/26/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension PaymentSheet {

    /// Confirms a checkout session with a new payment method
    @MainActor
    static func handleCheckoutSessionConfirmation(
        checkoutSession: STPCheckoutSession,
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        elementsSession: STPElementsSession
    ) async -> PaymentSheetResult {
        do {
            let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                intent: .checkoutSession(checkoutSession),
                elementsSession: elementsSession
            )

            // 1. Get or create payment method
            let paymentMethod: STPPaymentMethod
            let paymentMethodType: STPPaymentMethodType
            let paymentMethodOptions: STPConfirmPaymentMethodOptions?
            switch confirmType {
            case let .new(params, paymentOptions, newPaymentMethod, _, _):
                if let newPaymentMethod {
                    let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError,
                                                      error: PaymentSheetError.unexpectedNewPaymentMethod,
                                                      additionalNonPIIParams: ["payment_method_type": newPaymentMethod.type])
                    STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                }
                stpAssert(newPaymentMethod == nil, "newPaymentMethod should be nil when confirming with a new payment method; the payment method is created from params.")
                paymentMethodType = params.type
                paymentMethodOptions = paymentOptions
                params.clientAttributionMetadata = clientAttributionMetadata
                paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params)
            case let .saved(savedPaymentMethod, paymentOptions, _, _):
                paymentMethod = savedPaymentMethod
                paymentMethodType = paymentMethod.type
                paymentMethodOptions = paymentOptions
            }

            // 2. Get expected amount from checkout session
            guard let expectedAmount = checkoutSession.totalSummary?.total else {
                throw PaymentSheetError.unknown(debugDescription: "Missing expected amount from checkout session")
            }

            // 3. Call confirm API
            let response = try await configuration.apiClient.confirmCheckoutSession(
                sessionId: checkoutSession.stripeId,
                paymentMethod: paymentMethod.stripeId,
                expectedAmount: expectedAmount,
                expectedPaymentMethodType: paymentMethodType.identifier,
                returnURL: configuration.returnURL,
                shipping: makeCheckoutSessionShippingParams(configuration: configuration),
                paymentMethodOptions: paymentMethodOptions,
                clientAttributionMetadata: clientAttributionMetadata
            )

            // 4. Handle response based on checkout session mode
            return try await handleCheckoutSessionConfirmResponse(
                response: response,
                checkoutSession: checkoutSession,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } catch {
            return .failed(error: error)
        }
    }

    @MainActor
    private static func handleCheckoutSessionConfirmResponse(
        response: CheckoutSessionConfirmResponse,
        checkoutSession: STPCheckoutSession,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async throws -> PaymentSheetResult {
        if checkoutSession.mode == .setup {
            // Setup mode - handle SetupIntent
            guard let setupIntent = response.setupIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing setup intent in confirm response")
            }
            return await handleCheckoutSessionSetupIntentResponse(
                setupIntent: setupIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else {
            // Payment/Subscription mode - handle PaymentIntent
            guard let paymentIntent = response.paymentIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing payment intent in confirm response")
            }
            return await handleCheckoutSessionPaymentIntentResponse(
                paymentIntent: paymentIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        }
    }

    @MainActor
    private static func handleCheckoutSessionPaymentIntentResponse(
        paymentIntent: STPPaymentIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: paymentIntent,
                with: authenticationContext,
                returnURL: configuration.returnURL
            ) { status, _, error in
                continuation.resume(returning: makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    @MainActor
    private static func handleCheckoutSessionSetupIntentResponse(
        setupIntent: STPSetupIntent,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            paymentHandler.handleNextAction(
                for: setupIntent,
                with: authenticationContext,
                returnURL: configuration.returnURL
            ) { status, _, error in
                continuation.resume(returning: makePaymentSheetResult(for: status, error: error))
            }
        }
    }

    private static func makeCheckoutSessionShippingParams(configuration: PaymentElementConfiguration) -> STPPaymentIntentShippingDetailsParams? {
        return STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
    }
}
