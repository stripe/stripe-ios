//
//  STPAPIClient+PaymentSheet.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPAPIClient {
    typealias STPPaymentIntentWithPreferencesCompletionBlock = ((Result<STPPaymentIntent, Error>) -> Void)
    typealias STPSetupIntentWithPreferencesCompletionBlock = ((Result<STPSetupIntent, Error>) -> Void)
    
    func retrievePaymentIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        assert(STPPaymentIntentParams.isClientSecretValid(secret),
               "`secret` format does not match expected client secret formatting.")
        parameters["client_secret"] = secret
        parameters["type"] = "payment_intent"
        parameters["expand"] = ["payment_intent"]
        
        if let languageCode = Locale.current.languageCode,
           let regionCode = Locale.current.regionCode {
            parameters["locale"] = "\(languageCode)-\(regionCode)"
        }

        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: APIEndpointPaymentIntentWithPreferences,
            parameters: parameters) { paymentIntentWithPreferences, _, error in

            guard let paymentIntentWithPreferences = paymentIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(paymentIntentWithPreferences))
        }
    }
    
    func retrieveSetupIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        assert(STPSetupIntentConfirmParams.isClientSecretValid(secret),
               "`secret` format does not match expected client secret formatting.")
        parameters["client_secret"] = secret
        parameters["type"] = "setup_intent"
        parameters["expand"] = ["setup_intent"]
        
        if let languageCode = Locale.current.languageCode,
           let regionCode = Locale.current.regionCode {
            parameters["locale"] = "\(languageCode)-\(regionCode)"
        }

        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: APIEndpointPaymentIntentWithPreferences,
            parameters: parameters) { setupIntentWithPreferences, _, error in

            guard let setupIntentWithPreferences = setupIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(setupIntentWithPreferences))
        }
    }
}

private let APIEndpointPaymentIntentWithPreferences = "payment_method_preferences"
