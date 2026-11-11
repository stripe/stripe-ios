//
//  NetworkedIdentityAPIClientTestMock.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) @testable import StripeCore

@testable import StripeIdentity

final class NetworkedIdentityAPIClientTestMock: NetworkedIdentityAPIClient {
    struct DocumentListRequest: Equatable {
        let linkSessionKey: String
    }

    struct AssociationTokenRequest: Equatable {
        let identityDocumentID: String
        let verificationSessionID: String
        let linkSessionKey: String
    }

    struct SaveAssociationTokenRequest: Equatable {
        let verificationSessionID: String
        let linkSessionKey: String
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
        linkSessionKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse> {
        documentList.makeRequest(
            with: .init(
                linkSessionKey: linkSessionKey
            )
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        verificationSessionID: String,
        linkSessionKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        associationToken.makeRequest(
            with: .init(
                identityDocumentID: identityDocumentID,
                verificationSessionID: verificationSessionID,
                linkSessionKey: linkSessionKey
            )
        )
    }

    func createSaveAssociationToken(
        verificationSessionID: String,
        linkSessionKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        saveAssociationToken.makeRequest(
            with: .init(
                verificationSessionID: verificationSessionID,
                linkSessionKey: linkSessionKey
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
        // Fulfilling, reporting and calling back each take a hop on that queue. Waiting them out queues the main-queue
        // callbacks now, so a test's settle() sees the response however slow the machine is.
        for _ in 0..<3 {
            promise.propertyAccessQueue.sync {}
        }
    }
}
