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
    struct SignUpRequest: Equatable {
        let email: String
        let phoneNumber: String
        let country: String
        let name: String?
    }

    let configure = NetworkedIdentityAsyncRequests<String, Void>()
    let restore = NetworkedIdentityAsyncRequests<NetworkedIdentityConsumerCredentials, NetworkedIdentityLinkAccount>()
    let lookup = NetworkedIdentityAsyncRequests<String, NetworkedIdentityLinkAccount?>()
    let startVerification = NetworkedIdentityAsyncRequests<Bool, NetworkedIdentityLinkAccount>()
    let confirmVerification = NetworkedIdentityAsyncRequests<String, NetworkedIdentityLinkAccount>()
    let signUp = NetworkedIdentityAsyncRequests<SignUpRequest, NetworkedIdentityLinkAccount>()
    let authenticateWithLinkUI = NetworkedIdentityAsyncRequests<String?, NetworkedIdentityLinkAccount?>()
    private(set) var logOutCount = 0

    func configure(merchantPublishableKey: String) async throws {
        try await configure.makeRequest(with: merchantPublishableKey)
    }

    func restore(credentials: NetworkedIdentityConsumerCredentials) async throws -> NetworkedIdentityLinkAccount {
        try await restore.makeRequest(with: credentials)
    }

    func lookup(email: String) async throws -> NetworkedIdentityLinkAccount? {
        try await lookup.makeRequest(with: email)
    }

    func startVerification(isResend: Bool) async throws -> NetworkedIdentityLinkAccount {
        try await startVerification.makeRequest(with: isResend)
    }

    func confirmVerification(code: String) async throws -> NetworkedIdentityLinkAccount {
        try await confirmVerification.makeRequest(with: code)
    }

    func signUp(
        email: String,
        phoneNumber: String,
        country: String,
        name: String?
    ) async throws -> NetworkedIdentityLinkAccount {
        try await signUp.makeRequest(
            with: .init(email: email, phoneNumber: phoneNumber, country: country, name: name)
        )
    }

    func authenticateWithLinkUI(
        email: String?,
        mode: NetworkedIdentityMode,
        from viewController: UIViewController
    ) async throws -> NetworkedIdentityLinkAccount? {
        try await authenticateWithLinkUI.makeRequest(with: email)
    }

    func logOut() async throws {
        logOutCount += 1
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
    credentials: NetworkedIdentityConsumerCredentials? = .init(
        publishableKey: "pk_consumer",
        sessionClientSecret: "session_secret"
    )
) -> NetworkedIdentityLinkAccount {
    .init(
        email: "person@example.com",
        redactedPhoneNumber: "(***) ***-1234",
        isVerified: isVerified,
        credentials: credentials
    )
}
