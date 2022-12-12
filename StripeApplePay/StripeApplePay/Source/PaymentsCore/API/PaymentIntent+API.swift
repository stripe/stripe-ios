//
//  PaymentIntent+API.swift
//  StripeApplePay
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI.PaymentIntent {
    /// A callback to be run with a PaymentIntent response from the Stripe API.
    /// - Parameters:
    ///   - paymentIntent: The Stripe PaymentIntent from the response. Will be nil if an error occurs. - seealso: PaymentIntent
    ///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
    @_spi(STP) public typealias PaymentIntentCompletionBlock = (
        Result<StripeAPI.PaymentIntent, Error>
    ) -> Void

    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    @_spi(STP) public static func get(
        apiClient: STPAPIClient = .shared,
        clientSecret: String,
        completion: @escaping PaymentIntentCompletionBlock
    ) {
        assert(
            StripeAPI.PaymentIntentParams.isClientSecretValid(clientSecret),
            "`secret` format does not match expected client secret formatting."
        )
        guard let identifier = StripeAPI.PaymentIntent.id(fromClientSecret: clientSecret) else {
            completion(.failure(StripeError.invalidRequest))
            return
        }
        let endpoint = "\(Resource)/\(identifier)"
        let parameters: [String: String] = ["client_secret": clientSecret]

        apiClient.get(resource: endpoint, parameters: parameters, completion: completion)
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `PaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/payments/3d-secure
    /// - Parameters:
    ///   - paymentIntentParams:  The `PaymentIntentParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @_spi(STP) public static func confirm(
        apiClient: STPAPIClient = .shared,
        params: StripeAPI.PaymentIntentParams,
        completion: @escaping PaymentIntentCompletionBlock
    ) {
        assert(
            StripeAPI.PaymentIntentParams.isClientSecretValid(params.clientSecret),
            "`paymentIntentParams.clientSecret` format does not match expected client secret formatting."
        )

        guard let identifier = StripeAPI.PaymentIntent.id(fromClientSecret: params.clientSecret)
        else {
            completion(.failure(StripeError.invalidRequest))
            return
        }
        let endpoint = "\(Resource)/\(identifier)/confirm"

        let type = params.paymentMethodData?.type.rawValue
        STPAnalyticsClient.sharedClient.logPaymentIntentConfirmationAttempt(
            paymentMethodType: type
        )

        // Add telemetry
        var paramsWithTelemetry = params
        if let pmAdditionalParams = paramsWithTelemetry.paymentMethodData?.additionalParameters {
            paramsWithTelemetry.paymentMethodData?.additionalParameters = STPTelemetryClient.shared
                .paramsByAddingTelemetryFields(toParams: pmAdditionalParams)
        }

        apiClient.post(resource: endpoint, object: paramsWithTelemetry, completion: completion)
    }

    static let Resource = "payment_intents"
}
