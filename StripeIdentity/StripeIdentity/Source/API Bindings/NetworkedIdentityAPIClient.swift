//
//  NetworkedIdentityAPIClient.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkedIdentityAPIClient: AnyObject {
    func lookupConsumer(
        emailAddress: String,
        verificationSessionClientSecrets: [String]?
    ) -> Promise<NetworkedIdentityLookupResponse>

    func signUp(
        request: NetworkedIdentitySignUpRequest
    ) -> Promise<NetworkedIdentitySignUpResponse>

    func startVerification(
        request: NetworkedIdentityStartVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse>

    func confirmVerification(
        request: NetworkedIdentityConfirmVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse>

    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse>

    func createAssociationToken(
        identityDocumentID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse>

    func logOut(
        consumerSessionClientSecret: String,
        verificationSessionClientSecrets: [String]?,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse>

    func extendSession(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityExtendSessionResponse>
}

final class NetworkedIdentityAPIClientImpl: NetworkedIdentityAPIClient {
    typealias RetryScheduler = (TimeInterval, @escaping () -> Void) -> Void

    private enum Authorization {
        case merchant
        case consumer(String)
    }

    private static let requestSurfaceParameter = "request_surface"
    private static let requestSurface = "web_identity_product"
    private static let signUpConsentAction = "entered_phone_number_email_clicked_save_with_link_identity"
    private static let identityClientVersionHeader = "X-Stripe-Identity-Client-Version"

    private static let requestedWithHeader = "X-Requested-With"
    private static let documentListRetryDelay: TimeInterval = 0.25
    private static let maximumDocumentListAttempts = 2

    private let apiClient: STPAPIClient
    private let merchantPublishableKey: String
    private let clientVersion: String
    private let retryScheduler: RetryScheduler

    init(
        apiClient: STPAPIClient,
        merchantPublishableKey: String,
        clientVersion: String,
        retryScheduler: @escaping RetryScheduler = { delay, action in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                action()
            }
        }
    ) {
        self.apiClient = apiClient
        self.merchantPublishableKey = merchantPublishableKey
        self.clientVersion = clientVersion
        self.retryScheduler = retryScheduler
    }

    func lookupConsumer(
        emailAddress: String,
        verificationSessionClientSecrets: [String]? = nil
    ) -> Promise<NetworkedIdentityLookupResponse> {
        var parameters: [String: Any] = [
            "email_address": emailAddress,
            Self.requestSurfaceParameter: Self.requestSurface,
        ]
        addCookies(verificationSessionClientSecrets, to: &parameters)

        return post(
            pathComponents: ["consumers", "sessions", "lookup"],
            parameters: parameters,
            authorization: .merchant
        )
    }

    func signUp(
        request: NetworkedIdentitySignUpRequest
    ) -> Promise<NetworkedIdentitySignUpResponse> {
        var parameters: [String: Any] = [
            "email_address": request.emailAddress,
            "phone_number": request.phoneNumber,
            "country": request.country,
            "country_inferring_method": request.countryInferringMethod.rawValue,
            "locale": request.locale,
            "consent_action": Self.signUpConsentAction,
            Self.requestSurfaceParameter: Self.requestSurface,
        ]
        parameters["default_opt_in_enabled"] = request.defaultOptInEnabled
        parameters["changed_phone_number"] = request.changedPhoneNumber
        parameters["checked_opt_in_box"] = request.checkedOptInBox
        parameters["legal_name"] = request.legalName
        parameters["hcaptcha_response"] = request.hcaptchaResponse
        parameters["hcaptcha_key"] = request.hcaptchaKey
        parameters["session_id"] = request.sessionID
        addCookies(request.verificationSessionClientSecrets, to: &parameters)

        return post(
            pathComponents: ["consumers", "accounts", "sign_up"],
            parameters: parameters,
            authorization: .merchant
        )
    }

    func startVerification(
        request: NetworkedIdentityStartVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        var parameters = consumerSessionParameters(
            consumerSessionClientSecret: request.consumerSessionClientSecret
        )
        parameters["type"] = request.type.rawValue
        parameters["locale"] = request.locale
        parameters["account_phone_number"] = request.accountPhoneNumber
        addCookies(request.verificationSessionClientSecrets, to: &parameters)

        return post(
            pathComponents: ["consumers", "sessions", "start_verification"],
            parameters: parameters,
            authorization: .consumer(consumerPublishableKey)
        )
    }

    func confirmVerification(
        request: NetworkedIdentityConfirmVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        var parameters = consumerSessionParameters(
            consumerSessionClientSecret: request.consumerSessionClientSecret
        )
        parameters["type"] = request.type.rawValue
        parameters["code"] = request.code
        addCookies(request.verificationSessionClientSecrets, to: &parameters)

        return post(
            pathComponents: ["consumers", "sessions", "confirm_verification"],
            parameters: parameters,
            authorization: .consumer(consumerPublishableKey)
        )
    }

    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse> {
        return post(
            pathComponents: ["consumers", "identity_documents", "list"],
            parameters: consumerSessionParameters(
                consumerSessionClientSecret: consumerSessionClientSecret
            ),
            authorization: .consumer(consumerPublishableKey),
            maximumAttempts: Self.maximumDocumentListAttempts
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        return post(
            pathComponents: [
                "consumers",
                "identity_documents",
                identityDocumentID,
                "association_token",
            ],
            parameters: consumerSessionParameters(
                consumerSessionClientSecret: consumerSessionClientSecret
            ),
            authorization: .consumer(consumerPublishableKey)
        )
    }

    func logOut(
        consumerSessionClientSecret: String,
        verificationSessionClientSecrets: [String]? = nil,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        var parameters = consumerSessionParameters(
            consumerSessionClientSecret: consumerSessionClientSecret
        )
        addCookies(verificationSessionClientSecrets, to: &parameters)

        return post(
            pathComponents: ["consumers", "sessions", "log_out"],
            parameters: parameters,
            authorization: .consumer(consumerPublishableKey)
        )
    }

    func extendSession(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityExtendSessionResponse> {
        return post(
            pathComponents: ["consumers", "sessions", "extend"],
            parameters: consumerSessionParameters(
                consumerSessionClientSecret: consumerSessionClientSecret
            ),
            authorization: .consumer(consumerPublishableKey)
        )
    }

    private func consumerSessionParameters(
        consumerSessionClientSecret: String
    ) -> [String: Any] {
        return [
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            Self.requestSurfaceParameter: Self.requestSurface,
        ]
    }

    private func addCookies(
        _ verificationSessionClientSecrets: [String]?,
        to parameters: inout [String: Any]
    ) {
        guard let verificationSessionClientSecrets else {
            return
        }
        parameters["cookies"] = [
            "verification_session_client_secrets": verificationSessionClientSecrets,
        ]
    }

    private func post<Response: Decodable>(
        pathComponents: [String],
        parameters: [String: Any],
        authorization: Authorization,
        maximumAttempts: Int = 1
    ) -> Promise<Response> {
        let promise = Promise<Response>()
        performPost(
            pathComponents: pathComponents,
            parameters: parameters,
            authorization: authorization,
            attempt: 1,
            maximumAttempts: maximumAttempts,
            promise: promise
        )
        return promise
    }

    private func performPost<Response: Decodable>(
        pathComponents: [String],
        parameters: [String: Any],
        authorization: Authorization,
        attempt: Int,
        maximumAttempts: Int,
        promise: Promise<Response>
    ) {
        let url = pathComponents.reduce(apiClient.apiURL!) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
        let authorizationKey: String
        switch authorization {
        case .merchant:
            authorizationKey = merchantPublishableKey
        case .consumer(let consumerPublishableKey):
            authorizationKey = consumerPublishableKey
        }

        let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
        var request = apiClient.configuredRequest(
            for: url,
            using: authorizationKey,
            additionalHeaders: [
                Self.identityClientVersionHeader: clientVersion,
                Self.requestedWithHeader: "fetch",
                "Content-Length": String(formData?.count ?? 0),
                "Content-Type": "application/x-www-form-urlencoded",
            ]
        )
        if case .consumer = authorization {
            request.setValue(nil, forHTTPHeaderField: "Stripe-Account")
        }
        request.httpMethod = "POST"
        request.httpBody = formData

        let task = apiClient.urlSession.dataTask(with: request) { data, response, error in
            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               (500...599).contains(httpResponse.statusCode),
               attempt < maximumAttempts {
                self.retryScheduler(Self.documentListRetryDelay) {
                    self.performPost(
                        pathComponents: pathComponents,
                        parameters: parameters,
                        authorization: authorization,
                        attempt: attempt + 1,
                        maximumAttempts: maximumAttempts,
                        promise: promise
                    )
                }
                return
            }

            let result: Result<Response, Error> = STPAPIClient.decodeResponse(
                data: data,
                error: error,
                response: response,
                // Avoid DEBUG request logging because the URL can contain an identity document ID.
                request: nil
            )
            DispatchQueue.main.async {
                promise.fullfill(with: result)
            }
        }
        task.resume()
    }
}
