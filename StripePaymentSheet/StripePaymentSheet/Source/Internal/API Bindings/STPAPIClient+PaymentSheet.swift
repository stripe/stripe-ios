//
//  STPAPIClient+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {
    typealias STPPaymentIntentWithPreferencesCompletionBlock = ((Result<STPPaymentIntent, Error>) -> Void)
    typealias STPSetupIntentWithPreferencesCompletionBlock = ((Result<STPSetupIntent, Error>) -> Void)
    typealias STPIntentCompletionBlock = ((Result<Intent, Error>) -> Void)
    typealias STPElementsSessionCompletionBlock = ((Result<STPElementsSession, Error>) -> Void)

    func retrievePaymentIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        guard STPPaymentIntentParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            completion(.failure(NSError.stp_clientSecretError()))
            return
        }

        parameters["client_secret"] = secret
        parameters["type"] = "payment_intent"
        parameters["expand"] = ["payment_method_preference.payment_intent.payment_method"]
        parameters["locale"] = Locale.current.toLanguageTag()

        APIRequest<STPPaymentIntent>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        ) { paymentIntentWithPreferences, _, error in
            guard let paymentIntentWithPreferences = paymentIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(paymentIntentWithPreferences))
        }
    }

    func retrieveElementsSession(
        withIntentConfig intentConfig: PaymentSheet.IntentConfiguration,
        completion: @escaping STPElementsSessionCompletionBlock
    ) {
        APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: intentConfig.elementsSessionPayload(publishableKey: publishableKey)
        ) { elementsSession, _, error in
            guard let elementsSession = elementsSession else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(elementsSession))
        }
    }

    func retrieveSetupIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        guard STPSetupIntentConfirmParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            completion(.failure(NSError.stp_clientSecretError()))
            return
        }

        parameters["client_secret"] = secret
        parameters["type"] = "setup_intent"
        parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]
        parameters["locale"] = Locale.current.toLanguageTag()

        APIRequest<STPSetupIntent>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        ) { setupIntentWithPreferences, _, error in

            guard let setupIntentWithPreferences = setupIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(setupIntentWithPreferences))
        }
    }

    /// Retrieves either the Payment or Setup intent for the intent configuration
    /// - Parameters:
    ///   - intentConfig: a `PaymentSheet.IntentConfiguration`
    ///   - secret: The client secret of the intent to be retreved
    ///   - completion: completion callback for when the request completes
    func retrieveIntent(
        for intentConfig: PaymentSheet.IntentConfiguration,
        withClientSecret secret: String
    ) async throws -> Intent {
        switch intentConfig.mode {
        case .payment:
            return try await withCheckedThrowingContinuation { continuation in
                retrievePaymentIntent(withClientSecret: secret) { paymentIntent, error in
                    guard let paymentIntent = paymentIntent else {
                        continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                        return
                    }

                    continuation.resume(returning: .paymentIntent(paymentIntent))
                }
            }
        case .setup:
            return try await withCheckedThrowingContinuation { continuation in
                retrieveSetupIntent(withClientSecret: secret) { setupIntent, error in
                    guard let setupIntent = setupIntent else {
                        continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                        return
                    }

                    continuation.resume(returning: .setupIntent(setupIntent))
                }
            }
        }
    }
}

extension PaymentSheet.IntentConfiguration {
    func elementsSessionPayload(publishableKey: String?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["key"] = publishableKey
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        var deferredIntent = [String: Any]()
        deferredIntent["payment_method_types"] = paymentMethodTypes
        deferredIntent["on_behalf_of"] = onBehalfOf

        switch mode {
        case .payment(let amount, let currency, let setupFutureUsage, let captureMethod):
            deferredIntent["mode"] = "payment"
            deferredIntent["amount"] = amount
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage?.rawValue
            deferredIntent["capture_method"] = captureMethod.rawValue
        case .setup(let currency, let setupFutureUsage):
            deferredIntent["mode"] = "setup"
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage.rawValue
        }

        parameters["deferred_intent"] = deferredIntent
        return parameters
    }
}

private let APIEndpointIntentWithPreferences = "elements/sessions"
