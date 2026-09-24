//
//  NetworkedIdentityActions.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

/// Networked Identity actions on the verification session. They use the session's ephemeral key,
/// never Link session credentials, and return the updated verification.
protocol NetworkedIdentityActions: AnyObject {
    var verificationSessionID: String { get }

    /// Reuse: attaches a saved document with a single-use association token.
    func attachDocument(associationToken: String) async throws -> StripeAPI.VerificationPageData

    /// Save: records consent to save this session's document with a single-use save token.
    func prepareDocumentSave(associationToken: String) async throws -> StripeAPI.VerificationPageData

    /// Records that the user chose to verify without Link.
    func skip() async throws -> StripeAPI.VerificationPageData
}

/// `NetworkedIdentityActions` through the Identity API client, which needs the v8 VerificationPages API.
final class IdentityAPIClientNetworkedIdentityActions: NetworkedIdentityActions {
    private let apiClient: IdentityAPIClient

    init(apiClient: IdentityAPIClient) {
        self.apiClient = apiClient
    }

    var verificationSessionID: String {
        apiClient.verificationSessionId
    }

    func attachDocument(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await Self.value(of: apiClient.attachNetworkedIdentityDocument(associationToken: associationToken))
    }

    func prepareDocumentSave(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await Self.value(of: apiClient.prepareNetworkedIdentityDocumentSave(associationToken: associationToken))
    }

    func skip() async throws -> StripeAPI.VerificationPageData {
        try await Self.value(of: apiClient.skipNetworkedIdentity())
    }

    private static func value<Value>(of future: Future<Value>) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            future.observe(on: .main) { result in
                continuation.resume(with: result)
            }
        }
    }
}
