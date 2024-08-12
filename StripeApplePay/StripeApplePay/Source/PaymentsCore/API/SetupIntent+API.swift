//
//  SetupIntent+API.swift
//  StripeApplePay
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI.SetupIntent {
    /// A callback to be run with a SetupIntent response from the Stripe API.
    /// - Parameters:
    ///   - setupIntent: The Stripe SetupIntent from the response. Will be nil if an error occurs. - seealso: SetupIntent
    ///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
    @_spi(STP) public typealias SetupIntentCompletionBlock = @Sendable (Result<StripeAPI.SetupIntent, Error>)
        -> Void

    /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
    /// - Parameters:
    ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
    @MainActor @_spi(STP) public static func get(
        apiClient: STPAPIClient = .shared,
        clientSecret: String,
        completion: @escaping SetupIntentCompletionBlock
    ) {
        assert(
            StripeAPI.SetupIntentConfirmParams.isClientSecretValid(clientSecret),
            "`secret` format does not match expected client secret formatting."
        )
        guard let identifier = StripeAPI.SetupIntent.id(fromClientSecret: clientSecret) else {
            completion(.failure(StripeError.invalidRequest))
            return
        }
        let endpoint = "\(Resource)/\(identifier)"
        let parameters: [String: String] = ["client_secret": clientSecret]

        apiClient.get(resource: endpoint, parameters: parameters, completion: completion)
    }
    
    @MainActor @_spi(STP) public static func get(
        apiClient: STPAPIClient = .shared,
        clientSecret: String) async throws -> StripeAPI.SetupIntent {
            return try await withCheckedThrowingContinuation({ continuation in
                get(apiClient: apiClient, clientSecret: clientSecret) { result in
                    switch result {
                    case .success(let setupIntent):
                        continuation.resume(returning: setupIntent)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        }

    /// Confirms the SetupIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
    /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `PaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/payments/3d-secure
    /// - Parameters:
    ///   - setupIntentParams:    The `SetupIntentConfirmParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @MainActor @_spi(STP) public static func confirm(
        apiClient: STPAPIClient = .shared,
        params: StripeAPI.SetupIntentConfirmParams,
        completion: @escaping SetupIntentCompletionBlock
    ) {
        assert(
            StripeAPI.SetupIntentConfirmParams.isClientSecretValid(params.clientSecret),
            "`setupIntentConfirmParams.clientSecret` format does not match expected client secret formatting."
        )

        guard let identifier = StripeAPI.SetupIntent.id(fromClientSecret: params.clientSecret)
        else {
            completion(.failure(StripeError.invalidRequest))
            return
        }
        let endpoint = "\(Resource)/\(identifier)/confirm"

        let type = params.paymentMethodData?.type.rawValue
        STPAnalyticsClient.sharedClient.logSetupIntentConfirmationAttempt(
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
    
    @MainActor @_spi(STP) public static func confirm(
        apiClient: STPAPIClient = .shared,
        params: StripeAPI.SetupIntentConfirmParams) async throws -> StripeAPI.SetupIntent {
            return try await withCheckedThrowingContinuation({ continuation in
                confirm(apiClient: apiClient, params: params) { result in
                    switch result {
                    case .success(let setupIntent):
                        continuation.resume(returning: setupIntent)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        }

    static let Resource = "setup_intents"
}
