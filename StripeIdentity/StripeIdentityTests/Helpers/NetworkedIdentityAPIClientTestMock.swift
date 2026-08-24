//
//  NetworkedIdentityAPIClientTestMock.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) import StripeCore

@testable import StripeIdentity

final class NetworkedIdentityAPIClientTestMock: NetworkedIdentityAPIClient {
    struct LookupRequest: Equatable {
        let emailAddress: String
        let verificationSessionClientSecrets: [String]?
    }

    struct ConsumerRequest<Request: Equatable>: Equatable {
        let request: Request
        let consumerPublishableKey: String
    }

    struct DocumentListRequest: Equatable {
        let consumerSessionClientSecret: String
        let consumerPublishableKey: String
    }

    struct AssociationTokenRequest: Equatable {
        let identityDocumentID: String
        let consumerSessionClientSecret: String
        let consumerPublishableKey: String
    }

    struct LogOutRequest: Equatable {
        let consumerSessionClientSecret: String
        let verificationSessionClientSecrets: [String]?
        let consumerPublishableKey: String
    }

    let lookup = NetworkedIdentityMockAPIRequests<LookupRequest, NetworkedIdentityLookupResponse>()
    let signUp = NetworkedIdentityMockAPIRequests<
        NetworkedIdentitySignUpRequest, NetworkedIdentitySignUpResponse
    >()
    let startVerification = NetworkedIdentityMockAPIRequests<
        ConsumerRequest<NetworkedIdentityStartVerificationRequest>,
        NetworkedIdentityConsumerSessionResponse
    >()
    let confirmVerification = NetworkedIdentityMockAPIRequests<
        ConsumerRequest<NetworkedIdentityConfirmVerificationRequest>,
        NetworkedIdentityConsumerSessionResponse
    >()
    let documentList = NetworkedIdentityMockAPIRequests<
        DocumentListRequest, NetworkedIdentityDocumentListResponse
    >()
    let associationToken = NetworkedIdentityMockAPIRequests<
        AssociationTokenRequest, NetworkedIdentityAssociationTokenResponse
    >()
    let logOut = NetworkedIdentityMockAPIRequests<
        LogOutRequest, NetworkedIdentityConsumerSessionResponse
    >()
    let extendSession = NetworkedIdentityMockAPIRequests<
        DocumentListRequest, NetworkedIdentityExtendSessionResponse
    >()

    func lookupConsumer(
        emailAddress: String,
        verificationSessionClientSecrets: [String]?
    ) -> Promise<NetworkedIdentityLookupResponse> {
        lookup.makeRequest(
            with: .init(
                emailAddress: emailAddress,
                verificationSessionClientSecrets: verificationSessionClientSecrets
            )
        )
    }

    func signUp(
        request: NetworkedIdentitySignUpRequest
    ) -> Promise<NetworkedIdentitySignUpResponse> {
        signUp.makeRequest(with: request)
    }

    func startVerification(
        request: NetworkedIdentityStartVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        startVerification.makeRequest(
            with: .init(
                request: request,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func confirmVerification(
        request: NetworkedIdentityConfirmVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        confirmVerification.makeRequest(
            with: .init(
                request: request,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse> {
        documentList.makeRequest(
            with: .init(
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        associationToken.makeRequest(
            with: .init(
                identityDocumentID: identityDocumentID,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func logOut(
        consumerSessionClientSecret: String,
        verificationSessionClientSecrets: [String]?,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        logOut.makeRequest(
            with: .init(
                consumerSessionClientSecret: consumerSessionClientSecret,
                verificationSessionClientSecrets: verificationSessionClientSecrets,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func extendSession(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityExtendSessionResponse> {
        extendSession.makeRequest(
            with: .init(
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }
}

final class NetworkedIdentityMockAPIRequests<Parameters, Response> {
    private var pendingRequests: [Promise<Response>] = []
    private(set) var requestHistory: [Parameters] = []
    private var requestCallbacks: [() -> Void] = []

    var pendingRequestCount: Int {
        pendingRequests.count
    }

    func makeRequest(with parameters: Parameters) -> Promise<Response> {
        requestHistory.append(parameters)
        let promise = Promise<Response>()
        pendingRequests.append(promise)
        requestCallbacks.forEach { $0() }
        return promise
    }

    func callBackOnRequest(_ callback: @escaping () -> Void) {
        requestCallbacks.append(callback)
    }

    func respondToNext(with result: Result<Response, Error>) {
        precondition(!pendingRequests.isEmpty, "No pending Networked Identity request")
        pendingRequests.removeFirst().fullfill(with: result)
    }
}
