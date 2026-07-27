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
        checkout: CheckoutSessionBillingAddressUpdater,
        checkoutSession: Checkout.Session,
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        elementsSession: STPElementsSession
    ) async -> PaymentSheetResult {
        do {
            let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                intent: .checkout(checkoutSession),
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
                // Ensure email is set on the payment method — fall back to the checkout session's customer email
                if params.billingDetails?.email == nil, let customerEmail = checkoutSession.email {
                    params.nonnil_billingDetails.email = customerEmail
                }
                paymentMethod = try await configuration.apiClient.createPaymentMethod(with: params)
            case let .saved(savedPaymentMethod, paymentOptions, _, _):
                paymentMethod = savedPaymentMethod
                paymentMethodType = paymentMethod.type
                paymentMethodOptions = paymentOptions
            }

            // 2. Get expected amount and save_payment_method from checkout session
            let expectedAmount = checkoutSession.expectedAmountForConfirm()
            let savePaymentMethod: Bool? = {
                // Setup-style sessions don't send the param.
                guard !checkoutSession.isSetupOnly else { return nil }
                // Payment-style sessions send the save checkbox state.
                return confirmType.savePaymentMethodForCheckoutSession
            }()

            // 3. Call confirm API
            let response = try await configuration.apiClient.confirmCheckoutSession(
                sessionId: checkoutSession.id,
                paymentMethod: paymentMethod.stripeId,
                expectedAmount: expectedAmount,
                expectedPaymentMethodType: paymentMethodType.identifier,
                savePaymentMethod: savePaymentMethod,
                returnURL: configuration.returnURL,
                shipping: makeCheckoutSessionShippingParams(configuration: configuration),
                paymentMethodOptions: paymentMethodOptions,
                clientAttributionMetadata: clientAttributionMetadata
            )

            // Update the Checkout instance with the confirmed session response
            try await checkout.commitSession(response)

            // 4. Handle response based on which intent is present
            return try await handleCheckoutSessionConfirmResponse(
                response: response,
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
        response: PaymentPagesAPIResponse,
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler
    ) async throws -> PaymentSheetResult {
        // Exactly one of setupIntent/paymentIntent is expected to be present; setupIntent is
        // checked first arbitrarily since the two are mutually exclusive in practice.
        if let setupIntent = response.setupIntent {
            // Setup path (setup mode or unified setup-only sessions)
            return await handleCheckoutSessionSetupIntentResponse(
                setupIntent: setupIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else if let paymentIntent = response.paymentIntent {
            // Payment path (payment/subscription mode or unified sessions with priced items)
            return await handleCheckoutSessionPaymentIntentResponse(
                paymentIntent: paymentIntent,
                configuration: configuration,
                authenticationContext: authenticationContext,
                paymentHandler: paymentHandler
            )
        } else {
            throw PaymentSheetError.unknown(
                debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent"
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
