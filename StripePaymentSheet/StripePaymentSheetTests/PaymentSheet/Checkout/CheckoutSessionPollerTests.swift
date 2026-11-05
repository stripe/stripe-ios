//
//  CheckoutSessionPollerTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

final class CheckoutSessionPollerTests: XCTestCase {
    private let checkoutSessionId = "cs_test_123"
    private let clientSecret = "cs_test_123_secret_abc"

    func testPendingContinuesUntilSucceededRegardlessOfSessionStatus() async {
        // Given pending confirmation with a complete Session, followed by success with an open/unpaid Session
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        let succeeded = pollResponse(confirmationStatus: .succeeded)
        apiClient.pollResults = [
            .success(pollResponse(confirmationStatus: .pending, status: "complete", paymentStatus: "paid")),
            .success(succeeded),
        ]

        // When polling
        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then only confirmation status determines when polling stops; the final response is preserved
        XCTAssertEqual(apiClient.pollRequests.count, 2)
        XCTAssertEqual(outcome, .succeeded(succeeded))
    }

    func testFailedStopsEvenWhenSessionIsComplete() async {
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        let response = pollResponse(confirmationStatus: .failed, status: "complete")
        apiClient.pollResults = [.success(response)]

        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        XCTAssertEqual(apiClient.pollRequests.count, 1)
        XCTAssertEqual(outcome, .failed(response))
    }

    func testNotStartedStopsWithDistinctOutcome() async {
        // Given the server unexpectedly reports no confirmation attempt
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        let response = pollResponse(confirmationStatus: .notStarted)
        apiClient.pollResults = [.success(response)]

        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then the caller can report an unexpected error, distinct from a payment failure
        XCTAssertEqual(apiClient.pollRequests.count, 1)
        XCTAssertEqual(outcome, .notStarted(response))
    }

    func testTimeoutPreservesLatestResponseDespiteRequestFailures() async {
        // Given newer Session fields followed by request errors until timeout
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        let latest = pollResponse(confirmationStatus: .pending, status: "complete", paymentStatus: "paid")
        apiClient.pollResults = [
            .success(pollResponse(confirmationStatus: .pending)),
            .success(latest),
            .failure(PollerTestError.requestFailed, duration: 29),
        ]

        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        XCTAssertEqual(apiClient.pollRequests.count, 3)
        XCTAssertEqual(outcome, .timedOut(lastResponse: latest))
    }

    func testRateLimitDelayTimeoutPreservesLastResponse() async {
        // Given a valid response followed by a rate limit too close to the deadline to retry
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        let response = pollResponse(confirmationStatus: .pending)
        apiClient.pollResults = [
            .success(response, duration: 28),
            .failure(legacyRateLimitError()),
        ]

        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 28])
        XCTAssertTrue(clock.sleepDurations.isEmpty)
        XCTAssertEqual(outcome, .timedOut(lastResponse: response))
    }

    func testSleepPastDeadlinePreservesLastResponseWithoutRequestingAgain() async {
        // Given the clock resumes after the deadline while waiting for the next request
        let clock = TestClock()
        clock.extraSleepDuration = 30
        let apiClient = MockAPIClient(clock: clock)
        let response = pollResponse(confirmationStatus: .pending)
        apiClient.pollResults = [.success(response)]

        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        XCTAssertEqual(apiClient.pollRequests.count, 1)
        XCTAssertEqual(outcome, .timedOut(lastResponse: response))
    }

    func testRequestErrorsRetry() async {
        // Given a request failure followed by success
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .failure(PollerTestError.requestFailed),
            .success(pollResponse(confirmationStatus: .succeeded)),
        ]

        // When polling
        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then the failure is retried using the normal cadence
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 0.5])
        XCTAssertEqual(outcome, .succeeded(pollResponse(confirmationStatus: .succeeded)))
    }

    func testRequestsUseStartToStartSpacingAndRemainingTimeout() async {
        // Given a fast request followed by a request slower than the minimum interval
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .success(pollResponse(confirmationStatus: .pending), duration: 0.1),
            .success(pollResponse(confirmationStatus: .pending), duration: 0.7),
            .success(pollResponse(confirmationStatus: .succeeded)),
        ]

        // When polling
        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then the fast request is followed by a delay, while the slow request is not
        XCTAssertEqual(apiClient.pollRequests.map(\.checkoutSessionId), [
            checkoutSessionId,
            checkoutSessionId,
            checkoutSessionId,
        ])
        XCTAssertEqual(apiClient.pollRequests.map(\.clientSecret), [clientSecret, clientSecret, clientSecret])
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 0.5, 1.2])
        XCTAssertEqual(apiClient.pollRequests.map(\.timeout), [30, 29.5, 28.8])
        XCTAssertEqual(clock.sleepDurations, [0.4])
        XCTAssertEqual(outcome, .succeeded(pollResponse(confirmationStatus: .succeeded)))
    }

    func testRateLimitsUseExponentialBackoffAndStopAtTimeout() async {
        // Given repeated rate limits
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = Array(
            repeating: .failure(legacyRateLimitError()),
            count: 5
        )

        // When polling
        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then requests back off by 2, 4, 8, and 8 seconds, and no request starts at timeout
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2, 6, 14, 22])
        XCTAssertEqual(clock.sleepDurations, [2, 4, 8, 8])
        XCTAssertEqual(outcome, .timedOut(lastResponse: nil))
    }

    func testRecognizesModernAndLegacyRateLimitErrors() async {
        let errors: [Swift.Error] = [
            modernRateLimitError(),
            legacyRateLimitError(),
        ]

        for error in errors {
            // Given either supported representation of a rate limit error
            let clock = TestClock()
            let apiClient = MockAPIClient(clock: clock)
            apiClient.pollResults = [
                .failure(error),
                .success(pollResponse(confirmationStatus: .succeeded)),
            ]

            // When polling
            let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId,
                clientSecret: clientSecret
            )

            // Then the retry uses the rate-limit interval
            XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2])
            XCTAssertEqual(outcome, .succeeded(pollResponse(confirmationStatus: .succeeded)))
        }
    }

    func testOnlySuccessfulPollResetsRateLimitBackoff() async {
        // Given a rate limit and an ordinary failure, then success before another rate limit
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .failure(legacyRateLimitError()),
            .failure(PollerTestError.requestFailed),
            .success(pollResponse(confirmationStatus: .pending)),
            .failure(legacyRateLimitError()),
            .success(pollResponse(confirmationStatus: .pending)),
            .success(pollResponse(confirmationStatus: .succeeded)),
        ]

        // When polling
        let outcome = await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret
        )

        // Then ordinary errors retain backoff, while successful responses reset both cadence and the retry count
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2, 4, 4.5, 6.5, 7])
        XCTAssertEqual(outcome, .succeeded(pollResponse(confirmationStatus: .succeeded)))
    }

    private func makePoller(
        apiClient: MockAPIClient,
        clock: TestClock
    ) -> CheckoutSessionPoller {
        CheckoutSessionPoller(apiClient: apiClient, clock: clock)
    }

    private func pollResponse(
        confirmationStatus: CheckoutClientPollResponse.ConfirmationStatus,
        status: String = "open",
        paymentStatus: String = "unpaid"
    ) -> CheckoutClientPollResponse {
        let data = try! JSONSerialization.data(withJSONObject: [
            "id": checkoutSessionId,
            "confirmation_status": confirmationStatus.rawValue,
            "status": status,
            "payment_status": paymentStatus,
        ])
        return try! StripeJSONDecoder().decode(CheckoutClientPollResponse.self, from: data)
    }

    private func legacyRateLimitError() -> Swift.Error {
        NSError(
            domain: "CheckoutSessionPollerTests",
            code: 1,
            userInfo: [STPError.httpStatusCodeKey: 429]
        )
    }

    private func modernRateLimitError() -> Swift.Error {
        var apiError = StripeAPIError(
            type: .apiError,
            code: nil,
            message: "Rate limited",
            param: nil
        )
        apiError.httpStatusCode = 429
        return StripeError.apiError(apiError)
    }
}

private final class TestClock: CheckoutSessionPollingClock {
    private(set) var currentTime: TimeInterval = 0
    private(set) var sleepDurations: [TimeInterval] = []
    var extraSleepDuration: TimeInterval = 0

    override func now() -> TimeInterval {
        currentTime
    }

    override func sleep(for duration: TimeInterval) async {
        sleepDurations.append(duration)
        currentTime += duration + extraSleepDuration
    }

    func advance(by duration: TimeInterval) {
        currentTime += duration
    }
}

private final class MockAPIClient: CheckoutSessionPollingAPIClient {
    struct PollRequest {
        let checkoutSessionId: String
        let clientSecret: String
        let timeout: TimeInterval
        let startTime: TimeInterval
    }

    enum PollResult {
        case success(CheckoutClientPollResponse, duration: TimeInterval = 0)
        case failure(Swift.Error, duration: TimeInterval = 0)
    }

    private let clock: TestClock
    var pollResults: [PollResult] = []
    private(set) var pollRequests: [PollRequest] = []

    init(clock: TestClock) {
        self.clock = clock
    }

    func pollCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        timeout: TimeInterval
    ) async throws -> CheckoutClientPollResponse {
        pollRequests.append(PollRequest(
            checkoutSessionId: checkoutSessionId,
            clientSecret: clientSecret,
            timeout: timeout,
            startTime: clock.now()
        ))

        guard !pollResults.isEmpty else {
            throw PollerTestError.missingResult
        }
        let result = pollResults.removeFirst()
        switch result {
        case .success(let response, let duration):
            clock.advance(by: duration)
            return response
        case .failure(let error, let duration):
            clock.advance(by: duration)
            throw error
        }
    }

}

private enum PollerTestError: Swift.Error, Equatable {
    case missingResult
    case requestFailed
}
