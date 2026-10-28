import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutSessionPollingAPIClientTests: APIStubbedTestCase {
    func testPollSendsClientSecretAndPreservesTimeout() async throws {
        // Given a CC poll response and a caller-supplied remaining timeout
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        let clientSecret = "cs_test_123_secret_abc"
        let requestReceived = expectation(description: "CC poll requested")
        stub { request in
            request.url?.path == "/v1/checkout_client/cs_test_123/poll"
        } response: { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
            XCTAssertEqual(query, [URLQueryItem(name: "client_secret", value: clientSecret)])
            XCTAssertEqual(request.timeoutInterval, 12.25)
            requestReceived.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "id": "cs_test_123",
                    "confirmation_status": "pending",
                    "status": "open",
                    "payment_status": "unpaid",
                ],
                statusCode: 200,
                headers: nil
            )
        }

        // When polling through the API binding
        let response = try await apiClient.pollCheckoutSession(
            checkoutSessionId: "cs_test_123",
            clientSecret: clientSecret,
            timeout: 12.25
        )

        // Then the CC response is decoded and the request uses the caller's credentials and timeout
        await fulfillment(of: [requestReceived], timeout: 1)
        XCTAssertEqual(response.sessionId, "cs_test_123")
        XCTAssertEqual(response.confirmationStatus, .pending)
        XCTAssertEqual(response.status, .open)
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testPollDoesNotAutomaticallyRetryRateLimits() async throws {
        // Given the server asks the API client to retry a rate-limited poll
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        var requestCount = 0
        stub { request in
            request.url?.path == "/v1/checkout_client/cs_test_123/poll"
        } response: { _ in
            requestCount += 1
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
                clientSecret: "cs_test_123_secret_abc",
                timeout: 10
            )
            XCTFail("Expected polling to fail")
        } catch {
            guard let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError else {
                return XCTFail("Expected an API error, got \(error)")
            }
            XCTAssertEqual(apiError.httpStatusCode, 429)
        }

        // Then the rate limit reaches the poller without consuming its retry budget inside the API client
        XCTAssertEqual(requestCount, 1)
    }
}
