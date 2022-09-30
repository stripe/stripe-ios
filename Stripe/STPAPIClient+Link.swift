//
//  STPAPIClient+Link.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 4/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore

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
                    ConsumerSession.LookupResponse(.noAvailableLookupParams, allResponseFields: [:])
                ))
            }
            return
        }

        APIRequest<ConsumerSession.LookupResponse>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: publishableKey),
            parameters: parameters
        ) { result in
            if case let .success(lookupResponse) = result {
                switch lookupResponse.responseType {
                case .found(let consumerSession, _):
                    consumerSession.updateCookie(withStore: cookieStore)
                case .notFound(_) where cookies != nil:
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
        completion: @escaping (Result<ConsumerSession.SignupResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/accounts/sign_up"

        var parameters: [String: Any] = [
            "request_surface": "ios_payment_element",
            "email_address": email.lowercased(),
            "phone_number": phoneNumber,
            "locale": locale.toLanguageTag()
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

        APIRequest<ConsumerSession.SignupResponse>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { result in
            if case .success(let signupResponse) = result {
                signupResponse.consumerSession.updateCookie(withStore: cookieStore)
            }

            completion(result)
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
        
        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters,
            completion: completion
        )
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        linkedAccountId: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "bank_account": [
                "account": linkedAccountId,
            ],
            "type": "bank_account",
            "is_default": true
        ]

        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters,
            completion: completion
        )
    }

    func startVerification(
        for consumerSessionClientSecret: String,
        type: ConsumerSession.VerificationSession.SessionType,
        locale: Locale,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        
        let typeString: String = {
            switch type {
            case .sms:
                return "SMS"
            case .unknown, .signup, .email:
                assertionFailure("We don't support any verification except sms")
                return ""
            }
        }()
        let endpoint: String = "consumers/sessions/start_verification"
        
        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": typeString,
            "locale": locale.toLanguageTag()
        ]
        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }
        
        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { result in
            if case .success(let consumerSession) = result {
                consumerSession.updateCookie(withStore: cookieStore)
            }

            completion(result)
        }
    }
    
    func confirmSMSVerification(
        for consumerSessionClientSecret: String,
        with code: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion:  @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/confirm_verification"
        
        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": "SMS",
            "code": code,
            "request_surface": "ios_payment_element",
        ]

        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }
        
        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { result in
            if case .success(let consumerSession) = result {
                consumerSession.updateCookie(withStore: cookieStore)
            }

            completion(result)
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
    
    func listPaymentDetails(
        for consumerSessionClientSecret: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/list"
        
        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "types": ["card", "bank_account"]
        ]
        
        APIRequest<ConsumerPaymentDetails.ListDeserializer>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { result in
            completion(result.map { $0.paymentDetails })
        }
    }

    func deletePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
        ]

        APIRequest<STPEmptyStripeResponse>.delete(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { result in
            completion(result.map { _ in () } )
        }
    }

    func updatePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
        ]

        if let details = updateParams.details, case .card(let expiryDate, let billingDetails) = details {
            parameters["exp_month"] = expiryDate.month
            parameters["exp_year"] = expiryDate.year

            if let billingDetails = billingDetails {
                parameters["billing_address"] = billingDetails.consumersAPIParams
            }
        }
        
        if let isDefault = updateParams.isDefault {
            parameters["is_default"] = isDefault
        }

        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters,
            completion: completion
        )
    }

    func logout(
        consumerSessionClientSecret: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/log_out"

        var parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "request_surface": "ios_payment_element",
        ]

        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }

        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { result in
            if case .success(let consumerSession) = result {
                consumerSession.updateCookie(withStore: cookieStore)
            }

            completion(result)
        }
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
