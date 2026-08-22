//
//  CheckoutSessionPoller.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

import Foundation
@_spi(STP) import StripeCore

protocol CheckoutSessionPollingAPIClient {
    func pollCheckoutSession(
        checkoutSessionId: String,
        timeout: TimeInterval
    ) async throws -> PaymentPagePollResponse

    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse
}

// Only exists for tests to override
class CheckoutSessionPollingClock {
    func now() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    func sleep(for duration: TimeInterval) async throws {
        try await Task.sleep(
            nanoseconds: UInt64(duration * 1_000_000_000)
        )
    }
}

struct CheckoutSessionPoller {
    enum Error: Swift.Error {
        case paymentFailed(session: PaymentPagesAPIResponse)
    }

    /// The maximum amount of time to poll before giving up and returning.
    private static let timeout: TimeInterval = 30

    /// The minimum elapsed time between the start of consecutive poll requests.
    private static let minimumTimeInterval: TimeInterval = 0.5
    private static let minimumRateLimitTimeInterval: TimeInterval = 2
    private static let maximumRateLimitTimeInterval: TimeInterval = 8

    private let apiClient: any CheckoutSessionPollingAPIClient
    private let clock: CheckoutSessionPollingClock

    init(
        apiClient: any CheckoutSessionPollingAPIClient,
        clock: CheckoutSessionPollingClock = CheckoutSessionPollingClock()
    ) {
        self.apiClient = apiClient
        self.clock = clock
    }

    /// Returns after polling terminates or times out.
    ///
    /// Throws `Error.paymentFailed` after observing `requires_payment_method`
    /// and retrieving the full Checkout Session. Cancellation and full-session
    /// retrieval errors are also propagated.
    func poll(checkoutSessionId: String) async throws {
        let startTime = clock.now()
        var lastPollStartTime: TimeInterval?
        var minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
        var consecutiveRateLimitCount = 0

        /// - Returns: Seconds since polling started.
        func elapsedTime() -> TimeInterval {
            clock.now() - startTime
        }

        // Keep polling until the overall timeout is reached.
        while elapsedTime() < Self.timeout {
            // 1. Ensure `minimumTimeIntervalBetweenPolls` has elapsed before kicking off another /poll, to avoid spamming.
            if let lastPollStartTime {
                //
                //  Poll 1 starts                   Response ends               Poll 2 starts           Timeout
                //  |-------------------------------|<---------- delay -------->|-----------------------X
                //  |< timeSinceLastPollStarted --->|
                //  |<---------- minimumTimeIntervalBetweenPolls -------------->|
                //                                  |<--------------- remainingTime ------------------->|
                //                                  👆 we are here in time
                let timeSinceLastPollStarted = clock.now() - lastPollStartTime
                let delay = max(0, minimumTimeIntervalBetweenPolls - timeSinceLastPollStarted)
                let remainingTime = max(0, Self.timeout - elapsedTime())

                // If we don't have time to /poll before we time out, give up polling.
                guard delay >= remainingTime else {
                    return
                }
                
                if delay > 0 {
                    try await clock.sleep(for: delay)
                }
            }

            // 2. Poll the Checkout Session. Retry request failures until the timeout is reached.
            let pollResponse: PaymentPagePollResponse
            do {
                let remainingTime = Self.timeout - elapsedTime()
                guard remainingTime > 0 else {
                    return
                }

                lastPollStartTime = clock.now()
                pollResponse = try await apiClient.pollCheckoutSession(
                    checkoutSessionId: checkoutSessionId,
                    timeout: remainingTime
                )
            } catch let error as CancellationError {
                throw error
            } catch {
                try Task.checkCancellation()

                if Self.isRateLimitError(error) {
                    minimumTimeIntervalBetweenPolls = Self.rateLimitTimeInterval(
                        retryCount: consecutiveRateLimitCount
                    )
                    consecutiveRateLimitCount += 1
                }
                continue
            }

            minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
            consecutiveRateLimitCount = 0

            if pollResponse.paymentObjectStatus == .requiresPaymentMethod {
                let session = try await apiClient.retrieveCheckoutSession(
                    checkoutSessionId: checkoutSessionId
                )
                throw Error.paymentFailed(session: session)
            }

            switch pollResponse.state {
            case .active,
                 .processingSyncPayment,
                 .processingSubscription:
                continue
            case .succeeded,
                 .processingAsyncPayment,
                 .pendingAsyncCustomerAction,
                 .invalid,
                 .expired:
                return
            }
        }
    }

    /// Returns an exponentially increasing minimum poll interval of 2, 4, then 8 seconds, capped at 8 seconds.
    private static func rateLimitTimeInterval(retryCount: Int) -> TimeInterval {
        let timeInterval = minimumRateLimitTimeInterval * pow(2, Double(retryCount))
        return min(timeInterval, maximumRateLimitTimeInterval)
    }

    private static func isRateLimitError(_ error: Swift.Error) -> Bool {
        if let stripeError = error as? StripeError,
           case .apiError(let apiError) = stripeError {
            return apiError.httpStatusCode == 429
        }

        return ((error as NSError).userInfo[STPError.httpStatusCodeKey] as? NSNumber)?.intValue == 429
    }
}
