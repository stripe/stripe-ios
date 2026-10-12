//
//  NetworkedIdentityAPIClientTestMock.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) @testable import StripeCore

@testable import StripeIdentity

final class NetworkedIdentityAPIClientTestMock: NetworkedIdentityAPIClient {
    struct DocumentListRequest: Equatable {
        let consumerSessionClientSecret: String
        let consumerPublishableKey: String
    }

    struct AssociationTokenRequest: Equatable {
        let identityDocumentID: String
        let verificationSessionID: String
        let consumerSessionClientSecret: String
        let consumerPublishableKey: String
    }

    struct SaveAssociationTokenRequest: Equatable {
        let verificationSessionID: String
        let consumerSessionClientSecret: String
        let consumerPublishableKey: String
    }

    let documentList = NetworkedIdentityMockAPIRequests<
        DocumentListRequest, NetworkedIdentityDocumentListResponse
    >()
    let associationToken = NetworkedIdentityMockAPIRequests<
        AssociationTokenRequest, NetworkedIdentityAssociationTokenResponse
    >()
    let saveAssociationToken = NetworkedIdentityMockAPIRequests<
        SaveAssociationTokenRequest, NetworkedIdentityAssociationTokenResponse
    >()

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
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        associationToken.makeRequest(
            with: .init(
                identityDocumentID: identityDocumentID,
                verificationSessionID: verificationSessionID,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }

    func createSaveAssociationToken(
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        saveAssociationToken.makeRequest(
            with: .init(
                verificationSessionID: verificationSessionID,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        )
    }
}

final class NetworkedIdentityMockAPIRequests<Parameters, Response> {
    private var pendingRequests: [Promise<Response>] = []
    private(set) var requestHistory: [Parameters] = []

    func makeRequest(with parameters: Parameters) -> Promise<Response> {
        requestHistory.append(parameters)
        let promise = Promise<Response>()
        pendingRequests.append(promise)
        return promise
    }

    func respondToNext(with result: Result<Response, Error>) {
        precondition(!pendingRequests.isEmpty, "No pending Networked Identity request")
        let promise = pendingRequests.removeFirst()
        // Future reads its result on this queue, but does not serialize fulfillment itself.
        // Keep immediate mock responses from racing observation and corrupting the test result.
        promise.propertyAccessQueue.async {
            promise.fullfill(with: result)
        }
    }
}
