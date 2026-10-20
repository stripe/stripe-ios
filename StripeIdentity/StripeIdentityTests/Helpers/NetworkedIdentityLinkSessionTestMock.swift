//
//  NetworkedIdentityLinkSessionTestMock.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import UIKit

@testable import StripeIdentity

/// Records every call and suspends it until the test responds, so tests control ordering.
@MainActor
final class NetworkedIdentityLinkSessionTestMock: NetworkedIdentityLinkSession {
    struct AuthenticationRequest: Equatable {
        let email: String?
        let phoneNumber: String?
    }

    let configure = NetworkedIdentityAsyncRequests<String, Void>()
    let authenticateWithLinkUI = NetworkedIdentityAsyncRequests<AuthenticationRequest, NetworkedIdentityLinkAccount?>()

    func configure(merchantPublishableKey: String) async throws {
        try await configure.makeRequest(with: merchantPublishableKey)
    }

    func authenticateWithLinkUI(
        email: String?,
        phoneNumber: String?,
        mode: NetworkedIdentityMode,
        from viewController: UIViewController
    ) async throws -> NetworkedIdentityLinkAccount? {
        try await authenticateWithLinkUI.makeRequest(with: .init(email: email, phoneNumber: phoneNumber))
    }
}

@MainActor
final class NetworkedIdentityActionsTestMock: NetworkedIdentityActions {
    let verificationSessionID = "vs_target"
    let attachDocument = NetworkedIdentityAsyncRequests<String, StripeAPI.VerificationPageData>()
    let prepareDocumentSave = NetworkedIdentityAsyncRequests<String, StripeAPI.VerificationPageData>()
    private(set) var skipCount = 0
    var skipResult: Result<StripeAPI.VerificationPageData, Error> = .success(niActionPageData())

    func attachDocument(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await attachDocument.makeRequest(with: associationToken)
    }

    func prepareDocumentSave(associationToken: String) async throws -> StripeAPI.VerificationPageData {
        try await prepareDocumentSave.makeRequest(with: associationToken)
    }

    func skip() async throws -> StripeAPI.VerificationPageData {
        skipCount += 1
        return try skipResult.get()
    }

    /// What reading the session back returns; nil means the write did not take effect.
    var committedVerification: Result<StripeAPI.VerificationPageData?, Error> = .success(nil)
    private(set) var committedChecks: [NetworkedIdentityRoute] = []

    func verificationIfCommitted(_ route: NetworkedIdentityRoute) async throws -> StripeAPI.VerificationPageData? {
        committedChecks.append(route)
        return try committedVerification.get()
    }
}

func niActionPageData(id: String = "vs_target") -> StripeAPI.VerificationPageData {
    .init(
        id: id,
        requirements: .init(errors: [], missing: [.face]),
        status: .requiresInput,
        submitted: false,
        closed: false
    )
}

/// Holds suspended async calls until the test responds to them, in order.
@MainActor
final class NetworkedIdentityAsyncRequests<Parameters, Response> {
    private var pending: [CheckedContinuation<Response, Error>] = []
    private(set) var requestHistory: [Parameters] = []

    var pendingRequestCount: Int {
        pending.count
    }

    func makeRequest(with parameters: Parameters) async throws -> Response {
        requestHistory.append(parameters)
        return try await withCheckedThrowingContinuation { continuation in
            pending.append(continuation)
        }
    }

    func respondToNext(with result: Result<Response, Error>) {
        precondition(!pending.isEmpty, "No pending Networked Identity request")
        pending.removeFirst().resume(with: result)
    }
}

func niAccount(
    isVerified: Bool = false,
    credentials: NetworkedIdentityConsumerCredentials? = .init(linkSessionKey: "lsk_session")
) -> NetworkedIdentityLinkAccount {
    .init(
        email: "person@example.com",
        isVerified: isVerified,
        credentials: credentials
    )
}

func niDocument(
    id: String = "doc_1",
    documentType: NetworkedIdentityDocumentType = .passport,
    redactedDocumentNumber: String? = "•••• 1234",
    liveCaptured: Bool = true
) -> NetworkedIdentityDocument {
    .init(
        id: id,
        documentType: documentType,
        redactedDocumentNumber: redactedDocumentNumber,
        expirationDate: 1_900_000_000,
        liveCaptured: liveCaptured
    )
}

/// Lets suspended mock requests and their completions run on the main actor.
@MainActor
func settle() async {
    for _ in 0..<20 {
        await Task.yield()
    }
    try? await Task.sleep(nanoseconds: 5_000_000)
    for _ in 0..<20 {
        await Task.yield()
    }
}
