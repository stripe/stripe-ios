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
        completion: @escaping (ConsumerSession.LookupResponse?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/sessions/lookup"
        var parameters: [String: Any] = [:]
        if let email = email {
            parameters["email_address"] = email.lowercased()
        }

        let cookies = cookieStore.formattedSessionCookies()
        if let cookies = cookies {
            parameters["cookies"] = cookies
        }
        
        guard !parameters.isEmpty else {
            // no request to make if we don't have an email or cookies
            DispatchQueue.main.async {
                completion(ConsumerSession.LookupResponse(.noAvailableLookupParams, allResponseFields: [:]), nil)
            }
            return
        }

        APIRequest<ConsumerSession.LookupResponse>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: publishableKey),
            parameters: parameters
        ) { lookupResponse, _, error in
            switch lookupResponse?.responseType {
            case .found(let consumerSession, _):
                consumerSession.updateCookie(withStore: cookieStore)
            case .notFound(_) where cookies != nil:
                // Delete invalid cookie, if any
                cookieStore.delete(key: cookieStore.sessionCookieKey)
            default:
                break
            }

            completion(lookupResponse, error)
        }
    }

    func createConsumer(
        for email: String,
        with phoneNumber: String,
        countryCode: String?,
        cookieStore: LinkCookieStore,
        completion: @escaping (ConsumerSession.SignupResponse?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/accounts/sign_up"
        var parameters: [String: Any] = ["email_address": email.lowercased(), "phone_number": phoneNumber]
        if let countryCode = countryCode {
            parameters["country"] = countryCode
        }
        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }

        APIRequest<ConsumerSession.SignupResponse>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { signupResponse, _, error in
            signupResponse?.consumerSession.updateCookie(withStore: cookieStore)
            completion(signupResponse, error)
        }
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        cardParams: STPPaymentMethodCardParams,
        billingDetails: STPPaymentMethodBillingDetails,
        consumerAccountPublishableKey: String?,
        completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"
        let billingParams = billingDetails.consumersAPIParams

        var card = STPFormEncoder.dictionary(forObject: cardParams)["card"] as? [AnyHashable: Any]
        card?["cvc"] = nil // payment_details doesn't store cvc

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "card": card as Any,
            "type": "card",
            "billing_address": billingParams,
            "active": false, // card details are created with active false so we don't save them until the intent confirmation succeeds
        ]
        
        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { paymentDetails, _, error in
            completion(paymentDetails, error)
        }
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        linkedAccountId: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "bank_account": [
                "account": linkedAccountId,
            ],
            "type": "bank_account"
        ]

        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { paymentDetails, _, error in
            completion(paymentDetails, error)
        }
    }

    func startVerification(
        for consumerSessionClientSecret: String,
        type: ConsumerSession.VerificationSession.SessionType,
        locale: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (ConsumerSession?, Error?) -> Void
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
            "locale": locale
        ]
        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }
        
        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }
    
    func confirmSMSVerification(
        for consumerSessionClientSecret: String,
        with code: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion:  @escaping (ConsumerSession?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/sessions/confirm_verification"
        
        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": "SMS",
            "code": code,
            "client_type": "MOBILE_SDK",
        ]

        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }
        
        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }

    func createLinkAccountSession(
        for consumerSessionClientSecret: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (LinkAccountSession?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/link_account_sessions"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ]
        ]

        APIRequest<LinkAccountSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { linkAccountSession, _, error in
            completion(linkAccountSession, error)
        }
    }
    
    func listPaymentDetails(
        for consumerSessionClientSecret: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping ([ConsumerPaymentDetails]?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"
        
        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "types": ["card", "bank_account"]
        ]
        
        APIRequest<ConsumerPaymentDetails.ListDeserializer>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { listDeserializer, _, error in
            completion(listDeserializer?.paymentDetails, error)
        }
    }

    func deletePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (STPEmptyStripeResponse?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret]
        ]

        APIRequest<STPEmptyStripeResponse>.delete(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { paymentMethod, _, error in
            completion(paymentMethod, error)
        }
    }

    func updatePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        consumerAccountPublishableKey: String?,
        completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
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
            parameters: parameters
        ) { paymentDetails, _, error in
            completion(paymentDetails, error)
        }
    }

    func logout(
        consumerSessionClientSecret: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (ConsumerSession?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/sessions/log_out"

        var parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ]
        ]

        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }

        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: consumerAccountPublishableKey),
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }
}
