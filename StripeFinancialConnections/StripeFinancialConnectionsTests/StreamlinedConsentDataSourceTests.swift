//
//  StreamlinedConsentDataSourceTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation
@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

final class StreamlinedConsentDataSourceTests: XCTestCase {

    func testAcceptConsentCreatesOAuthAuthSessionWhenNextPaneIsPartnerAuth() throws {
        // Given consent leads to partner auth for an OAuth institution
        let apiClient = StreamlinedConsentAPIClient(
            consentResult: .success(try makeManifest(nextPane: "partner_auth")),
            authSessionResult: .success(makeAuthSession(isOauth: true))
        )
        let dataSource = try makeDataSource(apiClient: apiClient)

        // When the user accepts consent
        let result = try acceptConsent(dataSource)

        // Then the auth session is created for the selected institution
        XCTAssertEqual(apiClient.createAuthSessionInstitutionIds, ["fcinst_123"])
        guard case .partnerAuth(let manifest, let authSession) = result else {
            return XCTFail("Expected partner auth, got \(result)")
        }
        XCTAssertEqual(manifest.nextPane, .partnerAuth)
        XCTAssertTrue(authSession.isOauthNonOptional)
    }

    func testAcceptConsentCreatesNonOAuthAuthSessionWhenNextPaneIsPartnerAuth() throws {
        // Given consent leads to partner auth for a non-OAuth institution
        let apiClient = StreamlinedConsentAPIClient(
            consentResult: .success(try makeManifest(nextPane: "partner_auth")),
            authSessionResult: .success(makeAuthSession(isOauth: false))
        )
        let dataSource = try makeDataSource(apiClient: apiClient)

        // When the user accepts consent
        let result = try acceptConsent(dataSource)

        // Then the auth session is returned so partner auth can open full screen
        guard case .partnerAuth(_, let authSession) = result else {
            return XCTFail("Expected partner auth, got \(result)")
        }
        XCTAssertFalse(authSession.isOauthNonOptional)
    }

    func testAcceptConsentReportsAuthSessionCreationFailure() throws {
        // Given consent succeeds, but creating the auth session fails
        let apiClient = StreamlinedConsentAPIClient(
            consentResult: .success(try makeManifest(nextPane: "partner_auth")),
            authSessionResult: .failure(TestError.authSessionFailed)
        )
        let dataSource = try makeDataSource(apiClient: apiClient)

        // When the user accepts consent
        let result = try acceptConsent(dataSource)

        // Then the failure is reported along with the updated manifest
        guard case .authSessionCreationFailed(let manifest, let error) = result else {
            return XCTFail("Expected an auth session failure, got \(result)")
        }
        XCTAssertEqual(manifest.nextPane, .partnerAuth)
        XCTAssertEqual(error as? TestError, .authSessionFailed)
    }

    func testAcceptConsentDoesNotCreateAuthSessionForOtherNextPanes() throws {
        // Given consent leads to the networking warmup pane
        let apiClient = StreamlinedConsentAPIClient(
            consentResult: .success(try makeManifest(nextPane: "networking_link_login_warmup")),
            authSessionResult: .success(makeAuthSession(isOauth: true))
        )
        let dataSource = try makeDataSource(apiClient: apiClient)

        // When the user accepts consent
        let result = try acceptConsent(dataSource)

        // Then no auth session is created and the flow continues to the next pane
        XCTAssertTrue(apiClient.createAuthSessionInstitutionIds.isEmpty)
        guard case .nextPane(let manifest) = result else {
            return XCTFail("Expected the next pane, got \(result)")
        }
        XCTAssertEqual(manifest.nextPane, .networkingLinkLoginWarmup)
    }

    func testAcceptConsentFailsWhenMarkingConsentFails() throws {
        // Given marking consent fails
        let apiClient = StreamlinedConsentAPIClient(
            consentResult: .failure(TestError.consentFailed),
            authSessionResult: .success(makeAuthSession(isOauth: true))
        )
        let dataSource = try makeDataSource(apiClient: apiClient)

        // When the user accepts consent
        let expectation = expectation(description: "acceptConsent")
        var receivedError: Error?
        dataSource.acceptConsent().observe { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)

        // Then the error is returned and no auth session is created
        XCTAssertEqual(receivedError as? TestError, .consentFailed)
        XCTAssertTrue(apiClient.createAuthSessionInstitutionIds.isEmpty)
    }

    // MARK: - Helpers

    private enum TestError: Error, Equatable {
        case consentFailed
        case authSessionFailed
    }

    private func acceptConsent(_ dataSource: StreamlinedConsentDataSource) throws -> StreamlinedConsentResult {
        let expectation = expectation(description: "acceptConsent")
        var receivedResult: Result<StreamlinedConsentResult, Error>?
        dataSource.acceptConsent().observe { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        return try XCTUnwrap(receivedResult).get()
    }

    private func makeDataSource(apiClient: StreamlinedConsentAPIClient) throws -> StreamlinedConsentDataSource {
        let payload = try FinancialConnectionsSelectInstitutionMock.streamlinedConsent.make()
        return StreamlinedConsentDataSourceImplementation(
            manifest: payload.manifest,
            streamlinedConsentPane: try XCTUnwrap(payload.text?.streamlinedConsentPane),
            institution: FinancialConnectionsInstitution(
                id: "fcinst_123",
                name: "Test Institution",
                url: nil,
                icon: nil,
                logo: nil
            ),
            consentPaneDataAccessNotice: nil,
            apiClient: apiClient,
            clientSecret: "las_client_secret_123",
            analyticsClient: FinancialConnectionsAnalyticsClient(analyticsClient: MockAnalyticsClientV2())
        )
    }

    private func makeManifest(nextPane: String) throws -> FinancialConnectionsSessionManifest {
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: FinancialConnectionsSelectInstitutionMock.streamlinedConsent.data()) as? [String: Any]
        )
        var manifest = try XCTUnwrap(payload["manifest"] as? [String: Any])
        manifest["next_pane"] = nextPane
        payload["manifest"] = manifest

        let response = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/link_account_sessions/consent_acquired")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["request-id": "req_123"]
        )
        let result: Result<FinancialConnectionsSelectInstitution, Error> = STPAPIClient.decodeResponse(
            data: try JSONSerialization.data(withJSONObject: payload),
            error: nil,
            response: response
        )
        return try result.get().manifest
    }

    private func makeAuthSession(isOauth: Bool) -> FinancialConnectionsAuthSession {
        return FinancialConnectionsAuthSession(
            id: "fcauthsess_123",
            flow: nil,
            institutionSkipAccountSelection: nil,
            nextPane: .partnerAuth,
            showPartnerDisclosure: nil,
            skipAccountSelection: nil,
            url: nil,
            isOauth: isOauth,
            display: nil
        )
    }
}

private final class StreamlinedConsentAPIClient: EmptyFinancialConnectionsAPIClient {
    private let consentResult: Result<FinancialConnectionsSessionManifest, Error>
    private let authSessionResult: Result<FinancialConnectionsAuthSession, Error>
    private(set) var createAuthSessionInstitutionIds: [String] = []

    init(
        consentResult: Result<FinancialConnectionsSessionManifest, Error>,
        authSessionResult: Result<FinancialConnectionsAuthSession, Error>
    ) {
        self.consentResult = consentResult
        self.authSessionResult = authSessionResult
    }

    override func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let promise = Promise<FinancialConnectionsSessionManifest>()
        promise.fullfill(with: consentResult)
        return promise
    }

    override func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession> {
        createAuthSessionInstitutionIds.append(institutionId)
        let promise = Promise<FinancialConnectionsAuthSession>()
        promise.fullfill(with: authSessionResult)
        return promise
    }
}
