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
    func listPaymentMethods(
        forCustomer customerID: String,
        using ephemeralKeySecret: String,
        types: [STPPaymentMethodType] = [.card],
        completion: @escaping STPPaymentMethodsCompletionBlock
    ) {
        let header = authorizationHeader(using: ephemeralKeySecret)
        // Unfortunately, this API only supports fetching saved pms for one type at a time
        var shared_allPaymentMethods = [STPPaymentMethod]()
        var shared_lastError: Error?
        let group = DispatchGroup()

        for type in types {
            group.enter()
            let params = [
                "customer": customerID,
                "type": STPPaymentMethod.string(from: type),
            ]
            APIRequest<STPPaymentMethodListDeserializer>.getWith(
                self,
                endpoint: APIEndpointPaymentMethods,
                additionalHeaders: header,
                parameters: params as [String: Any]
            ) { deserializer, _, error in
                DispatchQueue.global(qos: .userInteractive).async(flags: .barrier) {
                    // .barrier ensures we're the only thing writing to shared_ vars
                    if let error = error {
                        shared_lastError = error
                    }
                    if let paymentMethods = deserializer?.paymentMethods {
                        shared_allPaymentMethods.append(contentsOf: paymentMethods)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion(shared_allPaymentMethods, shared_lastError)
        }
    }

    internal func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKeySecret: String,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/detach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKeySecret),
            parameters: [:]
        ) { _, _, error in
            completion(error)
        }
    }

    /// Retrieve a customer
    /// - seealso: https://stripe.com/docs/api#retrieve_customer
    func retrieveCustomer(
        _ customerID: String,
        using ephemeralKey: String,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        let endpoint = "\(APIEndpointCustomers)/\(customerID)"
        APIRequest<STPCustomer>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [:]
        ) { object, _, error in
            completion(object, error)
        }
    }
}

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
        var parameters: [String: Any] = [:]
        parameters["key"] = publishableKey
        parameters["type"] = "deferred_intent" // TODO(porter) hardcoded to deferred for now
        parameters["locale"] = Locale.current.toLanguageTag()

        var deferredIntent = [String: Any]()
        deferredIntent["payment_method_types"] = intentConfig.paymentMethodTypes

        switch intentConfig.mode {
        case .payment(amount: let amount, currency: let currency, setupFutureUsage: let setupFutureUsage, captureMethod: let captureMethod):
            deferredIntent["mode"] = "payment"
            deferredIntent["amount"] = amount
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage?.rawValue
            deferredIntent["capture_method"] = captureMethod.rawValue
        case .setup(currency: let currency, setupFutureUsage: let setupFutureUsage):
            deferredIntent["mode"] = "setup"
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage.rawValue
        }

        parameters["deferred_intent"] = deferredIntent

        APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
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

private let APIEndpointIntentWithPreferences = "elements/sessions"
