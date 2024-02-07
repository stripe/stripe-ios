//
//  STPAPIClient+Link.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 4/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

extension STPAPIClient {
    func lookupConsumerSession(
        for email: String?,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/lookup"
        var parameters: [String: Any] = [
            "request_surface": "ios_payment_element",
        ]
        if let email = email {
            parameters["email_address"] = email.lowercased()
        }

        guard parameters.keys.contains("email_address") || parameters.keys.contains("cookies") else {
            // no request to make if we don't have an email or cookies
            DispatchQueue.main.async {
                completion(.success(
                    ConsumerSession.LookupResponse(.noAvailableLookupParams)
                ))
            }
            return
        }

        post(
            resource: endpoint,
            parameters: parameters,
            ephemeralKeySecret: publishableKey
        ) { (result: Result<ConsumerSession.LookupResponse, Error>) in
            completion(result)
        }
    }

    func createConsumer(
        for email: String,
        with phoneNumber: String,
        locale: Locale,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        completion: @escaping (Result<ConsumerSession.SessionWithPublishableKey, Error>) -> Void
    ) {
        let endpoint: String = "consumers/accounts/sign_up"

        var parameters: [String: Any] = [
            "request_surface": "ios_payment_element",
            "email_address": email.lowercased(),
            "phone_number": phoneNumber,
            "locale": locale.toLanguageTag(),
            "country_inferring_method": "PHONE_NUMBER",
        ]

        if let legalName = legalName {
            parameters["legal_name"] = legalName
        }

        if let countryCode = countryCode {
            parameters["country"] = countryCode
        }

        if let consentAction = consentAction {
            parameters["consent_action"] = consentAction
        }

        post(
            resource: endpoint,
            parameters: parameters
        ) { (result: Result<ConsumerSession.SessionWithPublishableKey, Error>) in
            completion(result)
        }
    }

    private func makePaymentDetailsRequest(
        endpoint: String,
        parameters: [String: Any],
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        post(
            resource: endpoint,
            parameters: parameters,
            ephemeralKeySecret: consumerAccountPublishableKey
        ) { (result: Result<DetailsResponse, Error>) in
            completion(result.map { $0.redactedPaymentDetails })
        }
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        cardParams: STPPaymentMethodCardParams,
        billingEmailAddress: String,
        billingDetails: STPPaymentMethodBillingDetails,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"

        let billingParams = billingDetails.consumersAPIParams

        var card = STPFormEncoder.dictionary(forObject: cardParams)["card"] as? [AnyHashable: Any]
        card?["cvc"] = nil // payment_details doesn't store cvc

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "type": "card",
            "card": card as Any,
            "billing_email_address": billingEmailAddress,
            "billing_address": billingParams,
            "active": true, // card details are created with active true so they can be shared for passthrough mode
        ]

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion
        )
    }

    private func makeConsumerSessionRequest(
        endpoint: String,
        parameters: [String: Any],
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        post(
            resource: endpoint,
            parameters: parameters,
            ephemeralKeySecret: consumerAccountPublishableKey
        ) { (result: Result<SessionResponse, Error>) in
            completion(result.map { $0.consumerSession })
        }
    }

    func generatedLinkAccountSessionManifest(
        with clientSecret: String,
        emailAddress: String?,
        completion: @escaping (Result<Manifest, Error>) -> Void
    ) {
        var params: [String: AnyHashable] = [
            "client_secret": clientSecret,
            "fullscreen": true,
            "hide_close_button": true,
        ]
        if let emailAddress = emailAddress, !emailAddress.isEmpty {
            params["account_holder_email"] = emailAddress
        }
        let future: Future<Manifest> = self.post(
            resource: "link_account_sessions/generate_hosted_url",
            parameters: params
        )
        future.observe { result in
            switch result {
            case .success(let manifest):
                completion(.success(manifest))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createLinkAccountSession(
        for consumerSessionClientSecret: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<LinkAccountSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/link_account_sessions"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "request_surface": "ios_payment_element",
        ]

        APIRequest<LinkAccountSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters,
            completion: completion
        )
    }

    func sharePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        consumerAccountPublishableKey: String?,
        cvc: String?,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/share"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "id": id,
        ]

        if let cvc = cvc {
            parameters["payment_method_options"] = ["card": ["cvc": cvc]]
        }

        post(
            resource: endpoint,
            parameters: parameters,
            ephemeralKeySecret: nil,
            completion: completion
        )
    }

    func logout(
        consumerSessionClientSecret: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/log_out"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "request_surface": "ios_payment_element",
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion
        )
    }
}

// TODO(ramont): Remove this after switching to modern bindings.
private extension APIRequest {

    class func post(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping (Result<ResponseType, Error>) -> Void
    ) {
        post(
            with: apiClient,
            endpoint: endpoint,
            additionalHeaders: additionalHeaders,
            parameters: parameters
        ) { (responseObject, _, error) in
            if let responseObject = responseObject {
                completion(.success(responseObject))
            } else {
                completion(.failure(
                    error ?? NSError.stp_genericFailedToParseResponseError()
                ))
            }
        }
    }

    class func delete(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping (Result<ResponseType, Error>) -> Void
    ) {
        delete(
            with: apiClient,
            endpoint: endpoint,
            additionalHeaders: additionalHeaders,
            parameters: parameters
        ) { (responseObject, _, error) in
            if let responseObject = responseObject {
                completion(.success(responseObject))
            } else {
                completion(.failure(
                    error ?? NSError.stp_genericFailedToParseResponseError()
                ))
            }
        }
    }

}

// MARK: - Decodable helper wrappers
private extension STPAPIClient {
    struct DetailsResponse: Decodable {
        let redactedPaymentDetails: ConsumerPaymentDetails
    }

    struct DetailsListResponse: Decodable {
        let redactedPaymentDetails: [ConsumerPaymentDetails]
    }

    struct SessionResponse: Decodable {
        let authSessionClientSecret: String?
        let consumerSession: ConsumerSession
    }
}

// MARK: - /v1/consumers Support
extension STPPaymentMethodBillingDetails {

    var consumersAPIParams: [String: Any] {
        var params = STPFormEncoder.dictionary(forObject: self)
        // Consumers API doesn't support email or phone.
        params["email"] = nil
        params["phone"] = nil
        if let addressParams = address?.consumersAPIParams {
            params["address"] = nil
            params.merge(addressParams) { (_, new)  in new }
        }
        return params
    }

}

// MARK: - /v1/consumers Support
extension STPPaymentMethodAddress {
    // The param naming for consumers API is different so we need to map them.
    static let consumerKeyMap = [
      "line1": "line_1",
      "line2": "line_2",
      "city": "locality",
      "state": "administrative_area",
      "country": "country_code",
    ]

    var consumersAPIParams: [String: Any] {
        let tupleArray = STPFormEncoder.dictionary(forObject: self).compactMap { key, value -> (String, Any)? in
            guard let value = value as? String, !value.isEmpty else {
                return nil
            }

            let newKey = Self.consumerKeyMap[key] ?? key
            return (newKey, value)
        }
        return .init(uniqueKeysWithValues: tupleArray)
    }
}
