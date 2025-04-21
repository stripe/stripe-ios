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

// Please do not attempt to modify the Stripe SDK or call private APIs directly.
// See the Stripe Services Agreement (https://stripe.com/legal/ssa) for more details.
extension STPAPIClient {
    func lookupConsumerSession(
        for email: String?,
        emailSource: EmailSource?,
        sessionID: String,
        cookieStore: LinkCookieStore,
        useMobileEndpoints: Bool,
        doNotLogConsumerFunnelEvent: Bool,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        Task {
            let legacyEndpoint = "consumers/sessions/lookup"
            let mobileEndpoint = "consumers/mobile/sessions/lookup"

            var parameters: [String: Any] = [
                "request_surface": "ios_payment_element",
                "session_id": sessionID,
            ]
            if doNotLogConsumerFunnelEvent {
                parameters["do_not_log_consumer_funnel_event"] = true
            }
            if let email, let emailSource {
                parameters["email_address"] = email.lowercased()
                parameters["email_source"] = emailSource.rawValue
            } else {
                // no request to make if we don't have an email
                DispatchQueue.main.async {
                    completion(.success(
                        ConsumerSession.LookupResponse(.noAvailableLookupParams)
                    ))
                }
                return
            }

            let requestAssertionHandle: StripeAttest.AssertionHandle? = await {
                if useMobileEndpoints {
                    do {
                        let assertionHandle = try await stripeAttest.assert()
                        parameters = parameters.merging(assertionHandle.assertion.requestFields) { (_, new) in new }
                        return assertionHandle
                    } catch {
                        // If we can't get an assertion, we'll try the request anyway. It may fail.
                    }
                }
                return nil
            }()

            post(
                resource: useMobileEndpoints ? mobileEndpoint : legacyEndpoint,
                parameters: parameters,
                ephemeralKeySecret: publishableKey
            ) { (result: Result<ConsumerSession.LookupResponse, Error>) in
                Task { @MainActor in
                    // If there's an assertion error, send it to StripeAttest
                    if useMobileEndpoints,
                       case .failure(let error) = result,
                       StripeAttest.isLinkAssertionError(error: error) {
                        await self.stripeAttest.receivedAssertionError(error)
                    }
                    // Mark the assertion handle as completed
                    requestAssertionHandle?.complete()
                    completion(result)
                }
            }
        }
    }

    func createConsumer(
        for email: String,
        with phoneNumber: String,
        locale: Locale,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        useMobileEndpoints: Bool,
        completion: @escaping (Result<ConsumerSession.SessionWithPublishableKey, Error>) -> Void
    ) {
        Task {
            let legacyEndpoint = "consumers/accounts/sign_up"
            let modernEndpoint = "consumers/mobile/sign_up"

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

            let requestAssertionHandle: StripeAttest.AssertionHandle? = await {
                if useMobileEndpoints {
                    do {
                        let assertionHandle = try await stripeAttest.assert()
                        parameters = parameters.merging(assertionHandle.assertion.requestFields) { (_, new) in new }
                        return assertionHandle
                    } catch {
                        // If we can't get an assertion, we'll try the request anyway. It may fail.
                    }
                }
                return nil
            }()

            post(
                resource: useMobileEndpoints ? modernEndpoint : legacyEndpoint,
                parameters: parameters
            ) { (result: Result<ConsumerSession.SessionWithPublishableKey, Error>) in
                Task { @MainActor in
                    // If there's an assertion error, send it to StripeAttest
                    if useMobileEndpoints,
                       case .failure(let error) = result,
                       StripeAttest.isLinkAssertionError(error: error) {
                        await self.stripeAttest.receivedAssertionError(error)
                    }
                    // Mark the assertion handle as completed
                    requestAssertionHandle?.complete()
                    completion(result)
                }
            }
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
            consumerPublishableKey: consumerAccountPublishableKey
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

        let card = cardParams.consumersAPIParams

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "type": "card",
            "card": card,
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
            "is_default": true,
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
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        post(
            resource: endpoint,
            parameters: parameters,
            consumerPublishableKey: consumerAccountPublishableKey
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
                "consumer_session_client_secret": consumerSessionClientSecret,
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
        allowRedisplay: STPPaymentMethodAllowRedisplay?,
        cvc: String?,
        expectedPaymentMethodType: String?,
        billingPhoneNumber: String?,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/share"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "expand": ["payment_method"],
            "id": id,
        ]

        if let cvc = cvc {
            parameters["payment_method_options"] = ["card": ["cvc": cvc]]
        }
        if let allowRedisplay {
            parameters["allow_redisplay"] = allowRedisplay.stringValue
        }
        if let expectedPaymentMethodType {
            parameters["expected_payment_method_type"] = expectedPaymentMethodType
        }
        if let billingPhoneNumber {
            parameters["billing_phone"] = billingPhoneNumber
        }

        APIRequest<PaymentDetailsShareResponse>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentDetailsShareResponse, _, error in
            guard let paymentDetailsShareResponse else {
                stpAssert(error != nil)
                completion(.failure(error ?? NSError.stp_genericConnectionError()))
                return
            }
            completion(.success(paymentDetailsShareResponse))
        }
    }

    func listPaymentDetails(
        for consumerSessionClientSecret: String,
        supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType],
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/list"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": "ios_payment_element",
            "types": supportedPaymentDetailsTypes.map(\.rawValue),
        ]

        post(
            resource: endpoint,
            parameters: parameters,
            consumerPublishableKey: consumerAccountPublishableKey
        ) { (result: Result<DetailsListResponse, Error>) in
            completion(result.map { $0.redactedPaymentDetails })
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

        if let details = updateParams.details, case .card(let expiryDate, let billingDetails, let preferredNetwork) = details {
            if let expiryDate {
                parameters["exp_month"] = expiryDate.month
                parameters["exp_year"] = expiryDate.year
            }

            if let billingDetails = billingDetails {
                parameters["billing_address"] = billingDetails.consumersAPIParams
            }

            if let billingEmailAddress = billingDetails?.email {
                // This email address needs to be lowercase or the API will reject it
                parameters["billing_email_address"] = billingEmailAddress.lowercased()
            }

            if let preferredNetwork {
                parameters["preferred_network"] = preferredNetwork
            }
        }

        if let isDefault = updateParams.isDefault {
            parameters["is_default"] = isDefault
        }

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
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

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": "ios_payment_element",
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
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
            case .unparsable, .signup, .email:
                assertionFailure("We don't support any verification except sms")
                return ""
            }
        }()
        let endpoint: String = "consumers/sessions/start_verification"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": typeString,
            "locale": locale.toLanguageTag(),
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion
        )
    }

    func confirmSMSVerification(
        for consumerSessionClientSecret: String,
        with code: String,
        cookieStore: LinkCookieStore,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/confirm_verification"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": "SMS",
            "code": code,
            "request_surface": "ios_payment_element",
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            cookieStore: cookieStore,
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

extension STPPaymentMethodCardParams {
    var consumersAPIParams: [String: Any] {
        // The consumer endpoint expects card details in a different format.
        // It doesn't accept CVC, expiration dates must be 4 digits, and the CBC
        // network choice is sent in the "preferred_network" field.
        var card: [String: AnyHashable] = [:]
        if let number {
            card["number"] = number
        }
        if let expMonth {
            card["exp_month"] = expMonth
        }
        if let expYear {
            // Consumer endpoint expects a 4-digit card year
            card["exp_year"] = CardExpiryDate.normalizeYear(expYear.intValue)
        }
        if let preferredNetwork = networks?.preferred {
            card["preferred_network"] = preferredNetwork
        }
        return card
    }
}

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

enum EmailSource: String {
    case prefilledEmail = "prefilled_email"
    case userAction = "user_action"
    case customerObject = "customer_object"
    case customerEmail = "customer_email"
}
