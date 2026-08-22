//
//  CheckoutSessionPollerTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class CheckoutSessionPollerTests: XCTestCase {
    private let checkoutSessionId = "cs_test_123"

    func testPollStatesControlWhetherPollingContinues() async throws {
        let continuingStates: [PaymentPagePollResponse.State] = [
            .active,
            .processingSyncPayment,
            .processingSubscription,
        ]
        for state in continuingStates {
            // Given a state that requires more polling, followed by success
            let clock = TestClock()
            let apiClient = MockAPIClient(clock: clock)
            apiClient.pollResults = [
                .success(pollResponse(state: state)),
                .success(pollResponse(state: .succeeded)),
            ]

            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )

            // Then another request is made
            XCTAssertEqual(apiClient.pollRequests.count, 2, String(describing: state))
        }

        let stoppingStates: [PaymentPagePollResponse.State] = [
            .succeeded,
            .processingAsyncPayment,
            .pendingAsyncCustomerAction,
        ]
        for state in stoppingStates {
            // Given a state that stops polling
            let clock = TestClock()
            let apiClient = MockAPIClient(clock: clock)
            apiClient.pollResults = [.success(pollResponse(state: state))]

            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )

            // Then no further request is made
            XCTAssertEqual(apiClient.pollRequests.count, 1, String(describing: state))
        }
    }

    func testInvalidAndExpiredRetrieveSessionAndThrowBadCheckoutSessionState() async throws {
        for state in [PaymentPagePollResponse.State.invalid, .expired] {
            // Given an unexpected terminal poll state
            let clock = TestClock()
            let apiClient = MockAPIClient(clock: clock)
            apiClient.pollResults = [.success(pollResponse(state: state))]
            let retrievedSession = CheckoutTestHelpers.makeOpenSession(customerEmail: "updated@example.com")
            apiClient.retrieveResult = .success(retrievedSession)

            do {
                // When polling
                try await makePoller(apiClient: apiClient, clock: clock).poll(
                    checkoutSessionId: checkoutSessionId
                )
                XCTFail("Expected polling to throw")
            } catch CheckoutSessionPoller.Error.badCheckoutSessionState(let errorState, let session) {
                // Then the retrieved Session and unexpected state are carried in the error
                XCTAssertEqual(errorState, state)
                XCTAssertEqual(apiClient.retrieveCheckoutSessionIds, [checkoutSessionId])
                XCTAssertEqual(session.customerEmail, "updated@example.com")
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRequiresPaymentMethodRetrievesSessionAndThrowsPaymentFailed() async throws {
        // Given a terminal poll response that reports a failed payment
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .success(pollResponse(state: .succeeded, paymentObjectStatus: .requiresPaymentMethod)),
        ]
        let retrievedSession = CheckoutTestHelpers.makeOpenSession(customerEmail: "updated@example.com")
        apiClient.retrieveResult = .success(retrievedSession)

        do {
            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )
            XCTFail("Expected polling to throw")
        } catch CheckoutSessionPoller.Error.paymentFailed(let session) {
            // Then the retrieved Session is carried in the payment failure
            XCTAssertEqual(apiClient.retrieveCheckoutSessionIds, [checkoutSessionId])
            XCTAssertEqual(session.customerEmail, "updated@example.com")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRetrieveErrorPropagates() async throws {
        // Given a failed payment whose full Session cannot be retrieved
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .success(pollResponse(state: .active, paymentObjectStatus: .requiresPaymentMethod)),
        ]
        apiClient.retrieveResult = .failure(PollerTestError.retrieveFailed)

        do {
            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )
            XCTFail("Expected polling to throw")
        } catch let error as PollerTestError {
            // Then the retrieve error is propagated
            XCTAssertEqual(error, .retrieveFailed)
        }
    }

    func testOrdinaryRequestErrorRetries() async throws {
        // Given an ordinary request failure followed by success
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .failure(PollerTestError.requestFailed),
            .success(pollResponse(state: .succeeded)),
        ]

        // When polling
        try await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId
        )

        // Then the failure is retried using the normal cadence
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 0.5])
    }

    func testRequestCancellationPropagates() async throws {
        // Given a canceled poll request
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [.failure(CancellationError())]

        do {
            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )
            XCTFail("Expected polling to throw")
        } catch is CancellationError {
            // Then cancellation is propagated
        }
    }

    func testSleepCancellationPropagates() async throws {
        // Given a continuing response and a canceled delay before the next request
        let clock = TestClock()
        clock.sleepError = CancellationError()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [.success(pollResponse(state: .active))]

        do {
            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )
            XCTFail("Expected polling to throw")
        } catch is CancellationError {
            // Then cancellation is propagated without another request
            XCTAssertEqual(apiClient.pollRequests.count, 1)
        }
    }

    func testRequestsUseStartToStartSpacingAndRemainingTimeout() async throws {
        // Given a fast request followed by a request slower than the minimum interval
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .success(pollResponse(state: .active), duration: 0.1),
            .success(pollResponse(state: .active), duration: 0.7),
            .success(pollResponse(state: .succeeded)),
        ]

        // When polling
        try await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId
        )

        // Then the fast request is followed by a delay, while the slow request is not
        XCTAssertEqual(apiClient.pollRequests.map(\.checkoutSessionId), [
            checkoutSessionId,
            checkoutSessionId,
            checkoutSessionId,
        ])
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 0.5, 1.2])
        XCTAssertEqual(apiClient.pollRequests.map(\.timeout), [30, 29.5, 28.8])
        XCTAssertEqual(clock.sleepDurations, [0.4])
    }

    func testRateLimitsUseExponentialBackoffAndStopAtTimeout() async throws {
        // Given repeated rate limits
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = Array(
            repeating: .failure(legacyRateLimitError()),
            count: 5
        )

        // When polling
        try await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId
        )

        // Then requests back off by 2, 4, 8, and 8 seconds, and no request starts at timeout
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2, 6, 14, 22])
        XCTAssertEqual(clock.sleepDurations, [2, 4, 8, 8])
    }

    func testRecognizesModernAndLegacyRateLimitErrors() async throws {
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
                .success(pollResponse(state: .succeeded)),
            ]

            // When polling
            try await makePoller(apiClient: apiClient, clock: clock).poll(
                checkoutSessionId: checkoutSessionId
            )

            // Then the retry uses the rate-limit interval
            XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2])
        }
    }

    func testOnlySuccessfulPollResetsRateLimitBackoff() async throws {
        // Given a rate limit, an ordinary failure, and then a successful continuing response
        let clock = TestClock()
        let apiClient = MockAPIClient(clock: clock)
        apiClient.pollResults = [
            .failure(legacyRateLimitError()),
            .failure(PollerTestError.requestFailed),
            .success(pollResponse(state: .active)),
            .success(pollResponse(state: .succeeded)),
        ]

        // When polling
        try await makePoller(apiClient: apiClient, clock: clock).poll(
            checkoutSessionId: checkoutSessionId
        )

        // Then the ordinary failure retains the backoff and success resets the normal cadence
        XCTAssertEqual(apiClient.pollRequests.map(\.startTime), [0, 2, 4, 4.5])
    }

    private func makePoller(
        apiClient: MockAPIClient,
        clock: TestClock
    ) -> CheckoutSessionPoller {
        CheckoutSessionPoller(apiClient: apiClient, clock: clock)
    }

    private func pollResponse(
        state: PaymentPagePollResponse.State,
        paymentObjectStatus: PaymentPagePollResponse.PaymentObjectStatus? = nil
    ) -> PaymentPagePollResponse {
        PaymentPagePollResponse(
            sessionId: checkoutSessionId,
            state: state,
            paymentObjectStatus: paymentObjectStatus
        )
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
    var sleepError: Swift.Error?

    override func now() -> TimeInterval {
        currentTime
    }

    override func sleep(for duration: TimeInterval) async throws {
        sleepDurations.append(duration)
        if let sleepError {
            throw sleepError
        }
        currentTime += duration
    }

    func advance(by duration: TimeInterval) {
        currentTime += duration
    }
}

private final class MockAPIClient: CheckoutSessionPollingAPIClient {
    struct PollRequest {
        let checkoutSessionId: String
        let timeout: TimeInterval
        let startTime: TimeInterval
    }

    enum PollResult {
        case success(PaymentPagePollResponse, duration: TimeInterval = 0)
        case failure(Swift.Error, duration: TimeInterval = 0)
    }

    private let clock: TestClock
    var pollResults: [PollResult] = []
    var retrieveResult: Result<PaymentPagesAPIResponse, Swift.Error> = .failure(PollerTestError.missingResult)
    private(set) var pollRequests: [PollRequest] = []
    private(set) var retrieveCheckoutSessionIds: [String] = []

    init(clock: TestClock) {
        self.clock = clock
    }

    func pollCheckoutSession(
        checkoutSessionId: String,
        timeout: TimeInterval
    ) async throws -> PaymentPagePollResponse {
        pollRequests.append(PollRequest(
            checkoutSessionId: checkoutSessionId,
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

    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse {
        retrieveCheckoutSessionIds.append(checkoutSessionId)
        return try retrieveResult.get()
    }
}

private enum PollerTestError: Swift.Error, Equatable {
    case missingResult
    case requestFailed
    case retrieveFailed
}
