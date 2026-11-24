import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) @_spi(CheckoutSessionPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutSessionPollingAPIClientTests: APIStubbedTestCase {
    func testPollUsesCallerCredentialsAndTimeoutWithoutRetrying() async throws {
        // Given a rate-limited poll that explicitly asks the API client to retry
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        let clientSecret = "cs_test_123_secret_abc"
        var requestCount = 0
        stub { request in
            request.url?.path == "/v1/checkout_client/cs_test_123/poll"
        } response: { request in
            requestCount += 1
            XCTAssertEqual(request.httpMethod, "GET")
            let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
            XCTAssertEqual(query, [URLQueryItem(name: "client_secret", value: clientSecret)])
            XCTAssertEqual(request.timeoutInterval, 12.25)
            return HTTPStubsResponse(
                jsonObject: ["error": ["type": "invalid_request_error", "message": "Rate limited"]],
                statusCode: 429,
                headers: ["Stripe-Should-Retry": "true"]
            )
        }

        // When polling through the API binding
        do {
            _ = try await apiClient.pollCheckoutSession(
                checkoutSessionId: "cs_test_123",
                clientSecret: clientSecret,
                timeout: 12.25
            )
            XCTFail("Expected polling to fail")
        } catch {
            // Error contents are covered by CheckoutErrorHandlingTests.
        }

        // Then retry control stays with the poller
        XCTAssertEqual(requestCount, 1)
    }

    func testPollParsingFailureLogsPollParsingErrorCode() async throws {
        // Given a poll response missing required fields
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        stub { request in
            request.url?.path == "/v1/checkout_client/cs_test_123/poll"
        } response: { _ in
            HTTPStubsResponse(jsonObject: ["id": "cs_test_123"], statusCode: 200, headers: nil)
        }
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousHistory }
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true

        // When polling through the API binding
        do {
            _ = try await apiClient.pollCheckoutSession(
                checkoutSessionId: "cs_test_123",
                clientSecret: "cs_test_123_secret_abc",
                timeout: 5
            )
            XCTFail("Expected polling to fail")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }

        // Then the failure is logged once with the poll-specific code
        let events = analyticsClient._testLogHistory.filter { $0["event"] as? String == "unexpected_error.checkout_elements" }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?["error_code"] as? String, "checkout_client_poll_response_parsing_failed")
        XCTAssertFalse(STPAssertTestUtil.shouldSuppressNextSTPAlert)
    }
}
