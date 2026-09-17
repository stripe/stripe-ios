//
//  LinkAccountServiceRestoreConsumerSessionTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class LinkAccountServiceRestoreConsumerSessionTests: APIStubbedTestCase {

    func testRestoreConsumerSession_returnsVerifiedAccountFromRefreshedSession() {
        // Given a refresh endpoint that returns a verified session
        stubRefresh(consumerSession: makeSessionJSON(currentAuthenticationLevel: "2FA"))

        // When restoring the session
        let result = restore(consumerPublishableKey: "pk_consumer_123")

        // Then the account is built from the refreshed session and the given publishable key
        guard case .success(let account) = result else {
            return XCTFail("Expected success, got \(String(describing: result))")
        }
        XCTAssertEqual(account.email, "user@example.com")
        XCTAssertEqual(account.consumerSessionClientSecret, "pscs_restored")
        XCTAssertEqual(account.consumerPublishableKey, "pk_consumer_123")
        XCTAssertEqual(account.sessionState, .verified)
    }

    func testRestoreConsumerSession_returnsAccountRequiringVerification_whenSessionIsNotVerified() {
        // Given a refresh endpoint that returns a session below the required authentication level
        stubRefresh(consumerSession: makeSessionJSON(currentAuthenticationLevel: "NOT_AUTHENTICATED"))

        // When restoring the session
        let result = restore(consumerPublishableKey: nil)

        // Then the account still requires verification
        guard case .success(let account) = result else {
            return XCTFail("Expected success, got \(String(describing: result))")
        }
        XCTAssertEqual(account.sessionState, .requiresVerification)
        XCTAssertNil(account.consumerPublishableKey)
    }

    func testRestoreConsumerSession_fails_whenRefreshFails() {
        // Given a refresh endpoint that rejects the session
        stub { urlRequest in
            urlRequest.url?.absoluteString.contains("consumers/sessions/refresh") ?? false
        } response: { _ in
            let errorResponse = [
                "error": [
                    "message": "Consumer session expired.",
                    "code": "consumer_session_expired",
                    "type": "invalid_request_error",
                ],
            ]
            return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 401, headers: nil)
        }

        // When restoring the session
        let result = restore(consumerPublishableKey: "pk_consumer_123")

        // Then the restore fails
        guard case .failure = result else {
            return XCTFail("Expected failure, got \(String(describing: result))")
        }
    }
}

private extension LinkAccountServiceRestoreConsumerSessionTests {
    func makeSUT() -> LinkAccountService {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_merchant"
        return LinkAccountService(
            apiClient: apiClient,
            useMobileEndpoints: false,
            canSyncAttestationState: false,
            sessionID: "elements_session_123",
            customerID: nil,
            shouldPassCustomerIdToLookup: false,
            merchantLogoUrl: nil
        )
    }

    func makeSessionJSON(currentAuthenticationLevel: String) -> [String: Any] {
        [
            "client_secret": "pscs_restored",
            "email_address": "user@example.com",
            "redacted_formatted_phone_number": "(***) *** **55",
            "verification_sessions": [],
            "current_authentication_level": currentAuthenticationLevel,
            "minimum_authentication_level": "2FA",
        ]
    }

    func stubRefresh(consumerSession: [String: Any]) {
        stub { urlRequest in
            urlRequest.url?.absoluteString.contains("consumers/sessions/refresh") ?? false
        } response: { urlRequest in
            // The restored secret and the request surface are sent to the refresh endpoint
            let body = String(data: urlRequest.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains("pscs_restored"))
            XCTAssertTrue(body.contains("ios_identity_product"))
            return HTTPStubsResponse(jsonObject: ["consumer_session": consumerSession], statusCode: 200, headers: nil)
        }
    }

    func restore(consumerPublishableKey: String?) -> Result<PaymentSheetLinkAccount, Error>? {
        let sut = makeSUT()
        let expectation = expectation(description: "Restores consumer session")
        var result: Result<PaymentSheetLinkAccount, Error>?
        sut.restoreConsumerSession(
            consumerSessionClientSecret: "pscs_restored",
            consumerPublishableKey: consumerPublishableKey,
            requestSurface: .identity
        ) {
            result = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }
}
