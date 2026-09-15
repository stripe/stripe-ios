//
//  SeededDocumentsNetworkedIdentityAPIClient.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

// #TODO - Networked Identity [NI-Contract]: remove once test-mode accounts with saved documents exist.

/// Debug-only: returns sample saved documents, because test-mode Link accounts can't have any.
/// Every other call goes to `delegate`.
final class SeededDocumentsNetworkedIdentityAPIClient: NetworkedIdentityAPIClient {
    static let seededIDPrefix = "seeded_iddoc_"
    static let seededTokenPrefix = "seeded_token_"
    private static let secondsUntilExpiration = 365 * 24 * 60 * 60

    private let delegate: NetworkedIdentityAPIClient
    private let currentTime: () -> Int

    init(
        delegate: NetworkedIdentityAPIClient,
        currentTime: @escaping () -> Int = { Int(Date().timeIntervalSince1970) }
    ) {
        self.delegate = delegate
        self.currentTime = currentTime
    }

    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse> {
        let now = currentTime()
        let expiration = now + Self.secondsUntilExpiration
        return Promise(
            value: NetworkedIdentityDocumentListResponse(
                data: [
                    seededDocument(name: "passport", type: .passport, created: now, expiration: expiration),
                    seededDocument(name: "driving_license", type: .drivingLicense, created: now, expiration: expiration),
                ]
            )
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        guard identityDocumentID.hasPrefix(Self.seededIDPrefix) else {
            return delegate.createAssociationToken(
                identityDocumentID: identityDocumentID,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        }
        return Promise(value: NetworkedIdentityAssociationTokenResponse(associationToken: Self.seededTokenPrefix + identityDocumentID))
    }

    func createSaveAssociationToken(
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        delegate.createSaveAssociationToken(
            verificationSessionID: verificationSessionID,
            consumerSessionClientSecret: consumerSessionClientSecret,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    func lookupConsumer(
        emailAddress: String,
        verificationSessionClientSecrets: [String]?
    ) -> Promise<NetworkedIdentityLookupResponse> {
        delegate.lookupConsumer(
            emailAddress: emailAddress,
            verificationSessionClientSecrets: verificationSessionClientSecrets
        )
    }

    func signUp(request: NetworkedIdentitySignUpRequest) -> Promise<NetworkedIdentitySignUpResponse> {
        delegate.signUp(request: request)
    }

    func startVerification(
        request: NetworkedIdentityStartVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.startVerification(request: request, consumerPublishableKey: consumerPublishableKey)
    }

    func confirmVerification(
        request: NetworkedIdentityConfirmVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.confirmVerification(request: request, consumerPublishableKey: consumerPublishableKey)
    }

    func logOut(
        consumerSessionClientSecret: String,
        verificationSessionClientSecrets: [String]?,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.logOut(
            consumerSessionClientSecret: consumerSessionClientSecret,
            verificationSessionClientSecrets: verificationSessionClientSecrets,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    func extendSession(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityExtendSessionResponse> {
        delegate.extendSession(
            consumerSessionClientSecret: consumerSessionClientSecret,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    private func seededDocument(
        name: String,
        type: NetworkedIdentityDocumentType,
        created: Int,
        expiration: Int
    ) -> NetworkedIdentityDocument {
        NetworkedIdentityDocument(
            id: Self.seededIDPrefix + name,
            documentType: type,
            created: created,
            country: "US",
            region: nil,
            redactedDocumentNumber: "••••1234",
            expirationDate: expiration,
            liveCaptured: true
        )
    }
}

/// Debug-only: seeded documents have no real association token, so attaching one succeeds without a
/// request and reports no requirements; the next verification response still lists the document.
/// Every other call goes to `delegate`.
final class SeededDocumentsNetworkedIdentityActions: NetworkedIdentityActions {
    private let delegate: NetworkedIdentityActions

    init(delegate: NetworkedIdentityActions) {
        self.delegate = delegate
    }

    var verificationSessionID: String {
        delegate.verificationSessionID
    }

    func attachDocument(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        guard associationToken.hasPrefix(SeededDocumentsNetworkedIdentityAPIClient.seededTokenPrefix) else {
            return try await delegate.attachDocument(associationToken: associationToken)
        }
        return StripeAPI.VerificationPageData(
            id: verificationSessionID,
            requirements: .init(errors: [], missing: []),
            status: .requiresInput,
            submitted: false,
            closed: false
        )
    }

    func prepareDocumentSave(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await delegate.prepareDocumentSave(associationToken: associationToken)
    }

    func skip() async throws -> StripeAPI.VerificationPageData {
        try await delegate.skip()
    }
}
