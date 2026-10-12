//
//  NetworkedIdentityAPIClient.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkedIdentityAPIClient: AnyObject {
    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse>

    func createAssociationToken(
        identityDocumentID: String,
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse>

    func createSaveAssociationToken(
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse>
}

final class NetworkedIdentityAPIClientImpl: NetworkedIdentityAPIClient {
    typealias RetryScheduler = (TimeInterval, @escaping () -> Void) -> Void

    private static let requestSurfaceParameter = "request_surface"
    // #TODO - Networked Identity [NI-Contract]: send "ios_identity_product" once it's accepted.
    private static let requestSurface = "web_identity_product"
    private static let requestedWithHeader = "X-Requested-With"
    private static let documentListRetryDelay: TimeInterval = 0.25
    private static let maximumDocumentListAttempts = 2

    private let apiClient: STPAPIClient
    private let retryScheduler: RetryScheduler

    init(
        apiClient: STPAPIClient,
        retryScheduler: @escaping RetryScheduler = { delay, action in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                action()
            }
        }
    ) {
        self.apiClient = apiClient
        self.retryScheduler = retryScheduler
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
            consumerPublishableKey: consumerPublishableKey,
            maximumAttempts: Self.maximumDocumentListAttempts
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        var parameters = consumerSessionParameters(
            consumerSessionClientSecret: consumerSessionClientSecret
        )
        // The token can then only attach this document to this verification session.
        parameters["verification_session"] = verificationSessionID
        return post(
            pathComponents: [
                "consumers",
                "identity_documents",
                identityDocumentID,
                "association_token",
            ],
            parameters: parameters,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    func createSaveAssociationToken(
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        var parameters = consumerSessionParameters(
            consumerSessionClientSecret: consumerSessionClientSecret
        )
        parameters["verification_session"] = verificationSessionID
        // #TODO - Networked Identity: Confirm the draft save-token endpoint before rollout.
        // The short-lived token is distinct from a saved-document reuse token and must not be cached or replayed.
        return post(
            pathComponents: ["consumers", "identity_documents", "save_association_token"],
            parameters: parameters,
            consumerPublishableKey: consumerPublishableKey
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

    private func post<Response: Decodable>(
        pathComponents: [String],
        parameters: [String: Any],
        consumerPublishableKey: String,
        maximumAttempts: Int = 1
    ) -> Promise<Response> {
        let promise = Promise<Response>()
        performPost(
            pathComponents: pathComponents,
            parameters: parameters,
            consumerPublishableKey: consumerPublishableKey,
            attempt: 1,
            maximumAttempts: maximumAttempts,
            promise: promise
        )
        return promise
    }

    private func performPost<Response: Decodable>(
        pathComponents: [String],
        parameters: [String: Any],
        consumerPublishableKey: String,
        attempt: Int,
        maximumAttempts: Int,
        promise: Promise<Response>
    ) {
        let url = pathComponents.reduce(apiClient.apiURL!) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
        let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
        var request = apiClient.configuredRequest(
            for: url,
            using: consumerPublishableKey,
            additionalHeaders: [
                Self.requestedWithHeader: "fetch",
                "Content-Length": String(formData?.count ?? 0),
                "Content-Type": "application/x-www-form-urlencoded",
            ]
        )
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
                        consumerPublishableKey: consumerPublishableKey,
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
