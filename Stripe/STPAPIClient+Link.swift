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

        if let cookies = cookieStore.formattedSessionCookies() {
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
            parameters: parameters
        ) { lookupResponse, _, error in
            if case .found(let consumerSession) = lookupResponse?.responseType {
                consumerSession.updateCookie(withStore: cookieStore)
            }

            completion(lookupResponse, error)
        }
    }

    func createConsumer(
        for email: String,
        with phoneNumber: String,
        countryCode: String?,
        cookieStore: LinkCookieStore,
        completion: @escaping (ConsumerSession?, Error?) -> Void
    ) {
        let endpoint: String = "consumers/accounts/sign_up"
        var parameters: [String: Any] = ["email_address": email.lowercased(), "phone_number": phoneNumber]
        if let countryCode = countryCode {
            parameters["country"] = countryCode
        }
        if let cookies = cookieStore.formattedSessionCookies() {
            parameters["cookies"] = cookies
        }

        APIRequest<ConsumerSession>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }
    
    func createPaymentDetails(for consumerSessionClientSecret: String,
                              cardParams: STPPaymentMethodCardParams,
                              billingDetails: STPPaymentMethodBillingDetails,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
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
            parameters: parameters
        ) { paymentDetails, _, error in
            completion(paymentDetails, error)
        }
    }

    func createPaymentDetails(for consumerSessionClientSecret: String,
                              linkedAccountId: String,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
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
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }
    
    func createLinkAccountSession(for consumerSessionClientSecret: String,
                                  successURL: String,
                                  cancelURL: String,
                                  completion: @escaping (LinkAccountSession?, Error?) -> Void) {
        let endpoint: String = "consumers/link_account_sessions/create"
        let parameters: [String: Any] = ["success_url": successURL, "cancel_url": cancelURL]
        
        APIRequest<LinkAccountSession>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { linkAccountSession, _, error in
            completion(linkAccountSession, error)
        }
    }
    
    func attachAccountHolder(to linkAccountSessionClientSecret: String,
                             consumerSessionClientSecret: String,
                             completion: @escaping (LinkAccountSessionAttachResponse?, Error?) -> Void) {
        let endpoint = "consumers/link_account_sessions/attach_account_holder"
        let parameters: [String: Any] = [
            "link_account_session": linkAccountSessionClientSecret,
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            ]
                
        // This actually has a response shape, but we don't use it, so just parse
        // as an STPEmptyStripeResponse to determine success or not
        APIRequest<LinkAccountSessionAttachResponse>.post(with: self,
                                            endpoint: endpoint,
                                            parameters: parameters) { linkAccountSessionAttachResponse, _, error in
            completion(linkAccountSessionAttachResponse, error)
        }
    }
    
    func listPaymentDetails(for consumerSessionClientSecret: String,
                            completion: @escaping ([ConsumerPaymentDetails]?, Error?) -> Void) {
        let endpoint: String = "consumers/payment_details"
        
        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "types": ["card", "bank_account"]
        ]
        
        APIRequest<ConsumerPaymentDetails.ListDeserializer>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters
        ) { listDeserializer, _, error in
            completion(listDeserializer?.paymentDetails, error)
        }
    }

    func deletePaymentDetails(for consumerSessionClientSecret: String,
                              id: String,
                              completion: @escaping (STPEmptyStripeResponse?, Error?) -> Void) {
        let endpoint: String = "consumers/payment_details/\(id)"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret]
        ]

        APIRequest<STPEmptyStripeResponse>.delete(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentMethod, _, error in
            completion(paymentMethod, error)
        }
    }

    func updatePaymentDetails(for consumerSessionClientSecret: String,
                              id: String,
                              updateParams: UpdatePaymentDetailsParams,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
        let endpoint: String = "consumers/payment_details/\(id)"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
        ]
        
        if let details = updateParams.details, case UpdatePaymentDetailsParams.DetailsType.card(let expiryMonth,
                                                                                                let expiryYear,
                                                                                                let billingDetails) = details {
            parameters["exp_month"] = expiryMonth
            parameters["exp_year"] = expiryYear
            parameters["billing_address"] = billingDetails.consumersAPIParams
        }
        
        if let isDefault = updateParams.isDefault {
            parameters["is_default"] = isDefault
        }

        APIRequest<ConsumerPaymentDetails>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentDetails, _, error in
            completion(paymentDetails, error)
        }
    }

    func logout(
        consumerSessionClientSecret: String,
        cookieStore: LinkCookieStore,
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
            parameters: parameters
        ) { consumerSession, _, error in
            consumerSession?.updateCookie(withStore: cookieStore)
            completion(consumerSession, error)
        }
    }
}
