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

    /// Reads the session back after a redemption whose outcome is unknown: the verification if the write that
    /// leads to `route` took effect, nil otherwise.
    func verificationIfCommitted(_ route: NetworkedIdentityRoute) async throws -> StripeAPI.VerificationPageData?
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
        try await apiClient.attachNetworkedIdentityDocument(associationToken: associationToken).value
    }

    func prepareDocumentSave(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await apiClient.prepareNetworkedIdentityDocumentSave(associationToken: associationToken).value
    }

    func skip() async throws -> StripeAPI.VerificationPageData {
        try await apiClient.skipNetworkedIdentity().value
    }

    func verificationIfCommitted(_ route: NetworkedIdentityRoute) async throws -> StripeAPI.VerificationPageData? {
        let page = try await apiClient.getIdentityVerificationPage().value
        guard page.networkedIdentityRoute == route else {
            return nil
        }
        let missing = page.requirements.missing
        // A reuse took effect only once the shared document satisfies the document requirement.
        if route == .resumeReuse, missing.contains(.idDocumentFront) || missing.contains(.idDocumentBack) {
            return nil
        }
        return .init(
            id: page.id,
            requirements: .init(errors: [], missing: missing),
            status: page.status,
            submitted: page.submitted,
            // A submitted VerificationPage takes no more writes.
            closed: page.submitted
        )
    }
}

extension Future {
    var value: Value {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                observe { continuation.resume(with: $0) }
            }
        }
    }
}
