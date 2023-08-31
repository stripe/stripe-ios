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
        cookieStore: LinkCookieStore,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/lookup"
        var parameters: [String: Any] = [
            "request_surface": "ios_payment_element",
        ]
        if let email = email {
            parameters["email_address"] = email.lowercased()
        }

        let cookies = cookieStore.formattedSessionCookies()
        if let cookies = cookies {
            parameters["cookies"] = cookies
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
            if case let .success(lookupResponse) = result {
                switch lookupResponse.responseType {
                case .found(let consumerSession):
                    cookieStore.updateSessionCookie(with: consumerSession.authSessionClientSecret)
                case .notFound where cookies != nil:
                    // Delete invalid cookie, if any
                    cookieStore.delete(key: .session)
                default:
                    break
                }
            }

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
        cookieStore: LinkCookieStore,
        completion: @escaping (Result<ConsumerSession.SessionWithPublishableKey, Error>) -> Void
    ) {
        let endpoint: String = "consumers/accounts/sign_up"

        var parameters: [String: Any] = [
            "request_surface": "ios_payment_element",
            "email_address": email.lowercased(),
            "phone_number": phoneNumber,
            "locale": locale.toLanguageTag(),
        ]

        if let legalName = legalName {
            parameters["legal_name"] = legalName
        }

        if let countryCode = countryCode {
            parameters["country"] = countryCode
        }

        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
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
            "active": false, // card details are created with active false so we don't save them until the intent confirmation succeeds
        ]

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion
        )
    }

    func generatedLinkAccountSessionManifest(
        with clientSecret: String,
        completion: @escaping (Result<Manifest, Error>) -> Void
    ) {
        let future: Future<Manifest> = self.post(
            resource: "link_account_sessions/generate_hosted_url",
            parameters: [
                "client_secret": clientSecret,
                "fullscreen": true,
                "hide_close_button": true,
            ]
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


}

// MARK: - Decodable helper wrappers
private extension STPAPIClient {
    struct DetailsResponse: Decodable {
        let redactedPaymentDetails: ConsumerPaymentDetails
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
