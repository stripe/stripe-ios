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
        customerID: String?,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        doNotLogConsumerFunnelEvent: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        Task {
            var parameters: [String: Any] = [
                "request_surface": requestSurface.rawValue,
                "session_id": sessionID,
            ]
            parameters["customer_id"] = customerID
            if doNotLogConsumerFunnelEvent {
                parameters["do_not_log_consumer_funnel_event"] = true
            }
            if let email, !email.isEmpty, let emailSource {
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

            await performConsumerLookup(
                parameters: parameters,
                useMobileEndpoints: useMobileEndpoints,
                canSyncAttestationState: canSyncAttestationState,
                completion: completion
            )
        }
    }

    func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        sessionID: String,
        customerID: String?,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        Task {
            var parameters: [String: Any] = [
                "request_surface": requestSurface.rawValue,
                "session_id": sessionID,
                "link_auth_token_client_secret": linkAuthTokenClientSecret,
            ]

            parameters["customer_id"] = customerID

            await performConsumerLookup(
                parameters: parameters,
                useMobileEndpoints: useMobileEndpoints,
                canSyncAttestationState: canSyncAttestationState,
                completion: completion
            )
        }
    }

    func lookupLinkAuthIntent(
        linkAuthIntentID: String,
        sessionID: String,
        customerID: String?,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        Task {
            var parameters: [String: Any] = [
                "request_surface": requestSurface.rawValue,
                "session_id": sessionID,
                "link_auth_intent_id": linkAuthIntentID,
            ]
            parameters["customer_id"] = customerID

            await performConsumerLookup(
                parameters: parameters,
                useMobileEndpoints: useMobileEndpoints,
                canSyncAttestationState: canSyncAttestationState,
                completion: completion
            )
        }
    }

    private func performConsumerLookup(
        parameters: [String: Any],
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) async {
        let legacyEndpoint = "consumers/sessions/lookup"
        let mobileEndpoint = "consumers/mobile/sessions/lookup"

        var mutableParameters = parameters

        if useMobileEndpoints {
            mutableParameters["supported_verification_types"] = SupportedVerificationType.allCases.map(\.rawValue)
        }

        let requestAssertionHandle: StripeAttest.AssertionHandle? = await {
            if useMobileEndpoints {
                do {
                    let assertionHandle = try await stripeAttest.assert(canSyncState: canSyncAttestationState)
                    mutableParameters = mutableParameters.merging(assertionHandle.assertion.requestFields) { (_, new) in new }
                    return assertionHandle
                } catch {
                    // If we can't get an assertion, we'll try the request anyway. It may fail.
                }
            }
            return nil
        }()

        post(
            resource: useMobileEndpoints ? mobileEndpoint : legacyEndpoint,
            parameters: mutableParameters,
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

    func createConsumer(
        for email: String,
        with phoneNumber: String?,
        locale: Locale,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.SessionWithPublishableKey, Error>) -> Void
    ) {
        Task {
            let legacyEndpoint = "consumers/accounts/sign_up"
            let modernEndpoint = "consumers/mobile/sign_up"

            var parameters: [String: Any] = [
                "request_surface": requestSurface.rawValue,
                "email_address": email.lowercased(),
                "locale": locale.toLanguageTag(),
            ]

            if let phoneNumber {
                parameters["phone_number"] = phoneNumber
                parameters["country_inferring_method"] = "PHONE_NUMBER"
            } else {
                parameters["country_inferring_method"] = "BILLING_ADDRESS"
            }

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
                        let assertionHandle = try await stripeAttest.assert(canSyncState: canSyncAttestationState)
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
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        post(
            resource: endpoint,
            parameters: parameters
        ) { (result: Result<DetailsResponse, Error>) in
            completion(result.map { $0.redactedPaymentDetails })
        }
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        cardParams: STPPaymentMethodCardParams,
        billingEmailAddress: String,
        billingDetails: STPPaymentMethodBillingDetails,
        isDefault: Bool,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        createPaymentDetails(
            for: consumerSessionClientSecret,
            rawCardParams: cardParams.consumersAPIParams,
            billingEmailAddress: billingEmailAddress,
            billingDetails: billingDetails,
            isDefault: isDefault,
            clientAttributionMetadata: clientAttributionMetadata,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        rawCardParams: [String: Any],
        billingEmailAddress: String,
        billingDetails: STPPaymentMethodBillingDetails,
        isDefault: Bool,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"

        let billingParams = billingDetails.consumersAPIParams

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
            "type": "card",
            "card": rawCardParams,
            "billing_email_address": billingEmailAddress,
            "billing_address": billingParams,
            "active": true, // card details are created with active true so they can be shared for passthrough mode
            "is_default": isDefault,
        ]

        if let clientAttributionMetadata {
            parameters = STPAPIClient.paramsAddingClientAttributionMetadata(parameters, clientAttributionMetadata: clientAttributionMetadata)
        }

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func createPaymentDetails(
        for consumerSessionClientSecret: String,
        linkedAccountId: String,
        isDefault: Bool,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
            "bank_account": [
                "account": linkedAccountId,
            ],
            "type": "bank_account",
            "is_default": isDefault,
        ]

        if let clientAttributionMetadata {
            parameters = STPAPIClient.paramsAddingClientAttributionMetadata(parameters, clientAttributionMetadata: clientAttributionMetadata)
        }

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    private func makeConsumerSessionRequest(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        post(
            resource: endpoint,
            parameters: parameters
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
        linkMode: LinkMode? = nil,
        intentToken: String? = nil,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<LinkAccountSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/link_account_sessions"

        var parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": requestSurface.rawValue,
        ]
        parameters["link_mode"] = linkMode?.rawValue
        parameters["intent_token"] = intentToken

        APIRequest<LinkAccountSession>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(),
            parameters: parameters,
            completion: completion
        )
    }

    func sharePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        overridePublishableKey: String? = nil,
        allowRedisplay: STPPaymentMethodAllowRedisplay?,
        cvc: String?,
        expectedPaymentMethodType: String?,
        billingPhoneNumber: String?,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/share"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
            "expand": ["payment_method"],
            "id": id,
        ]

        var paymentMethodOptionsDict: [String: Any] = [:]
        if let cvc = cvc {
            paymentMethodOptionsDict["card"] = ["cvc": cvc]
        }
        if let clientAttributionMetadata {
            // Send CAM at the top-level of all requests in scope for consistency
            // Also send under payment_method_options because there are existing dependencies
            paymentMethodOptionsDict = Self.paramsAddingClientAttributionMetadata(paymentMethodOptionsDict, clientAttributionMetadata: clientAttributionMetadata)
            parameters = Self.paramsAddingClientAttributionMetadata(parameters, clientAttributionMetadata: clientAttributionMetadata)
        }
        parameters["payment_method_options"] = paymentMethodOptionsDict

        if let allowRedisplay {
            parameters["allow_redisplay"] = allowRedisplay.stringValue
        }
        if let expectedPaymentMethodType {
            parameters["expected_payment_method_type"] = expectedPaymentMethodType
        }
        if let billingPhoneNumber {
            parameters["billing_phone"] = billingPhoneNumber
        }

        let additionalHeaders = overridePublishableKey != nil
            ? authorizationHeader(using: overridePublishableKey)
            : [:]

        APIRequest<PaymentDetailsShareResponse>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: additionalHeaders,
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
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/list"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
            "types": supportedPaymentDetailsTypes.map(\.rawValue),
        ]

        post(
            resource: endpoint,
            parameters: parameters
        ) { (result: Result<DetailsListResponse, Error>) in
            completion(result.map { $0.redactedPaymentDetails })
        }
    }

    func listShippingAddress(
        for consumerSessionClientSecret: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ShippingAddressesResponse, Error>) -> Void
    ) {
        let endPoint = "consumers/shipping_addresses/list"
        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
        ]
        post(
            resource: endPoint,
            parameters: parameters
        ) { (result: Result<ShippingAddressesResponse, Error>) in
            completion(result)
        }
    }

    func deletePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
        ]

        APIRequest<STPEmptyStripeResponse>.delete(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(),
            parameters: parameters
        ) { result in
            completion(result.map { _ in () } )
        }
    }

    func updatePaymentDetails(
        for consumerSessionClientSecret: String,
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        let endpoint: String = "consumers/payment_details/\(id)"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "request_surface": requestSurface.rawValue,
        ]

        if let details = updateParams.details, case .card(let expiryDate, let billingDetails, let preferredNetwork) = details {
            if let expiryDate {
                parameters["exp_month"] = expiryDate.month
                parameters["exp_year"] = expiryDate.year
            }

            if let billingDetails = billingDetails {
                parameters["billing_address"] = billingDetails.consumersAPIParams
            }

            if let billingEmailAddress = billingDetails?.email, !billingEmailAddress.isEmpty {
                // This email address needs to be lowercase or the API will reject it
                parameters["billing_email_address"] = billingEmailAddress.lowercased()
            }

            if let preferredNetwork {
                parameters["preferred_network"] = preferredNetwork
            }
        }

        if let details = updateParams.details, case .bankAccount(let billingDetails) = details {
            parameters["billing_address"] = billingDetails.consumersAPIParams

            if let billingEmailAddress = billingDetails.email {
                // This email address needs to be lowercase or the API will reject it
                parameters["billing_email_address"] = billingEmailAddress.lowercased()
            }
        }

        if let isDefault = updateParams.isDefault {
            parameters["is_default"] = isDefault
        }

        if let clientAttributionMetadata {
            parameters = Self.paramsAddingClientAttributionMetadata(parameters, clientAttributionMetadata: clientAttributionMetadata)
        }

        makePaymentDetailsRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func updatePhoneNumber(
        consumerSessionClientSecret: String,
        phoneNumber: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint = "consumers/accounts/update_phone"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "phone_number": phoneNumber,
            "request_surface": requestSurface.rawValue,
        ]

        post(
            resource: endpoint,
            parameters: parameters
        ) { (result: Result<UpdatePhoneNumberResponse, Error>) in
            completion(result.map { $0.consumerSession })
        }
    }

    func logout(
        consumerSessionClientSecret: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/log_out"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": requestSurface.rawValue,
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func refreshSession(
        consumerSessionClientSecret: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/refresh"

        let parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": requestSurface.rawValue,
            "supported_verification_types": SupportedVerificationType.allCases.map(\.rawValue),
        ]

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func startVerification(
        for consumerSessionClientSecret: String,
        type: ConsumerSession.VerificationSession.SessionType,
        locale: Locale,
        isResendingSmsCode: Bool = false,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {

        let typeString: String = {
            switch type {
            case .sms:
                return "SMS"
            case .unparsable, .signup, .email, .linkAuthToken:
                assertionFailure("We don't support any verification except sms")
                return ""
            }
        }()
        let endpoint: String = "consumers/sessions/start_verification"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": typeString,
            "locale": locale.toLanguageTag(),
            "request_surface": requestSurface.rawValue,
        ]

        // This parameter is specifically when resending SMS codes.
        if isResendingSmsCode {
            parameters["is_resend_sms_code"] = true
        }

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func confirmSMSVerification(
        for consumerSessionClientSecret: String,
        with code: String,
        requestSurface: LinkRequestSurface = .default,
        consentGranted: Bool? = nil,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/confirm_verification"

        var parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "type": "SMS",
            "code": code,
            "request_surface": requestSurface.rawValue,
        ]

        if let consentGranted {
            parameters["consent_granted"] = consentGranted
        }

        makeConsumerSessionRequest(
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
    }

    func updateConsentStatus(
        consentGranted: Bool,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String?,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let endpoint: String = "consumers/sessions/consent_update"

        let parameters: [String: Any] = [
            "credentials": ["consumer_session_client_secret": consumerSessionClientSecret],
            "consent_granted": consentGranted,
        ]

        post(
            resource: endpoint,
            parameters: parameters,
            consumerPublishableKey: consumerPublishableKey,
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
        let consumerSession: ConsumerSession
    }

    struct UpdatePhoneNumberResponse: Decodable {
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
