//
//  CheckoutErrorHandlingTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 10/12/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class CheckoutErrorHandlingTests: APIStubbedTestCase {

    func testConfirmationErrorMessages() async throws {
        for (response, expectedMessage) in Self.errorCases {
            // Given a loaded Checkout whose confirmation API returns an error
            let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(
                paymentElementConfiguration: nil,
                expressCheckoutElementConfiguration: nil
            ))
            stubError(path: "/v1/payment_pages/cs_test_123/confirm", response: response)
            let flow = try XCTUnwrap(checkout.makeConfirmationFlow(
                for: nil,
                presentingViewController: UIViewController()
            ))

            // When the merchant confirms Checkout
            let result = await checkout.confirm(flow)

            // Then the failed result exposes the server message or localized fallback
            guard case .failed(let error) = result else {
                XCTFail("Expected confirmation to fail, got \(result)")
                continue
            }
            XCTAssertEqual(error.localizedDescription, expectedMessage)
        }
    }

    func testRetrievalErrorMessageAndMetadata() async throws {
        // Given retrieval returns an API error with response metadata
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubError(
            path: "/v1/payment_pages/cs_test_123",
            response: ["type": "invalid_request_error", "code": "test_code", "message": "Server message"],
            statusCode: 429,
            headers: ["request-id": "req_test_123"]
        )

        // When Checkout retrieves the session
        do {
            _ = try await apiClient.retrieveCheckoutSession(checkoutSessionId: "cs_test_123")
            XCTFail("Expected retrieval to fail")
        } catch {
            // Then the server message is exposed while the original API metadata remains available
            guard let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError else {
                XCTFail("Expected StripeError")
                return
            }
            XCTAssertEqual(error.localizedDescription, "Server message")
            XCTAssertEqual(apiError.httpStatusCode, 429)
            XCTAssertEqual(apiError.requestID, "req_test_123")
            XCTAssertEqual(apiError.code, "test_code")
        }
    }

    func testPollingKeepsExistingErrorMessagesAndMetadata() async throws {
        // Given the poll endpoint returns an error used only for internal rate-limit handling
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubError(
            path: "/v1/payment_pages/cs_test_123/poll",
            response: ["type": "invalid_request_error", "code": "test_code", "message": "Server message"],
            statusCode: 429,
            headers: ["request-id": "req_test_poll"]
        )

        // When Checkout polls for confirmation status
        do {
            _ = try await apiClient.pollCheckoutSession(checkoutSessionId: "cs_test_123", timeout: 10)
            XCTFail("Expected polling to fail")
        } catch {
            // Then no presentation override is applied and the original metadata remains available
            guard let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError else {
                XCTFail("Expected StripeError")
                return
            }
            XCTAssertNil(apiError.localizedDescriptionOverride)
            XCTAssertEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
            XCTAssertEqual(apiError.httpStatusCode, 429)
            XCTAssertEqual(apiError.requestID, "req_test_poll")
        }
    }

    func testOtherAPIRequestsKeepExistingErrorMessages() async throws {
        // Given a non-Checkout endpoint returns a developer-facing API error
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubError(
            path: "/v1/payment_methods",
            response: [
                "type": "invalid_request_error",
                "message": "Developer-facing message",
                // API payloads cannot opt into the SDK's local description override.
                "localized_description_override": "Unexpected override",
            ]
        )

        // When the shared API client makes a request outside Checkout
        do {
            let _: EmptyResponse = try await withCheckedThrowingContinuation { continuation in
                apiClient.get(resource: "payment_methods", parameters: [:]) { (result: Result<EmptyResponse, Error>) in
                    continuation.resume(with: result)
                }
            }
            XCTFail("Expected the request to fail")
        } catch {
            // Then the shared error formatter still uses its existing generic message
            XCTAssertTrue(error is StripeError)
            XCTAssertEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
        }
    }

    private static var errorCases: [(response: [String: Any], expectedMessage: String)] {
        let serverMessage = "Ce code promotionnel n’est pas valide."
        let errorTypes = ["invalid_request_error", "api_error", "card_error", "idempotency_error", "future_error_type"]
        let messageCases: [(response: [String: Any], expectedMessage: String)] = errorTypes.map { type in
            (["type": type, "message": serverMessage, "code": "promotion_code_invalid"], serverMessage)
        }
        // A known card code must also use the generic fallback when the server omits its message.
        return messageCases + [
            (["type": "card_error", "code": "incorrect_number", "message": NSNull()], NSError.stp_unexpectedErrorMessage()),
            (["type": "invalid_request_error", "code": "incorrect_number"], NSError.stp_unexpectedErrorMessage()),
        ]
    }

    private func stubError(
        path: String,
        response: [String: Any],
        statusCode: Int32 = 400,
        headers: [String: String]? = nil
    ) {
        stub { request in
            request.url?.path == path
        } response: { _ in
            HTTPStubsResponse(jsonObject: ["error": response], statusCode: statusCode, headers: headers)
        }
    }
}
