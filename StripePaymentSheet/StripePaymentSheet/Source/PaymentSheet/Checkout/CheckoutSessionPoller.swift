//
//  CheckoutSessionPoller.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - Dependencies
protocol CheckoutSessionPollingAPIClient {
    func pollCheckoutSession(
        checkoutSessionId: String,
        timeout: TimeInterval
    ) async throws -> PaymentPagePollResponse

    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse
}

class CheckoutSessionPollingClock {
    func now() -> TimeInterval {
        Date().timeIntervalSinceReferenceDate
    }

    func sleep(for duration: TimeInterval) async throws {
        try await Task.sleep(
            nanoseconds: UInt64(duration * 1_000_000_000)
        )
    }
}

/// Polls a Checkout Session until confirmation can continue or polling times out.
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
        var lastPollStartElapsedTime: TimeInterval?
        var minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
        var consecutiveRateLimitCount = 0

        /// - Returns: Seconds since polling started.
        func elapsedTime() -> TimeInterval {
            clock.now() - startTime
        }

        // Keep polling until the overall timeout is reached.
        while elapsedTime() < Self.timeout {
            // 1. Ensure `minimumTimeIntervalBetweenPolls` has elapsed before kicking off another /poll, to avoid spamming.
            if let lastPollStartElapsedTime {
                //
                //  Poll 1 starts                   Response ends               Poll 2 starts           Timeout
                //  |-------------------------------|<---------- delay -------->|-----------------------X
                //  |< timeSinceLastPollStarted --->|
                //  |<---------- minimumTimeIntervalBetweenPolls -------------->|
                //                                  |<--------------- remainingTime ------------------->|
                //                                  👆 we are here in time
                let timeSinceLastPollStarted = elapsedTime() - lastPollStartElapsedTime
                let delay = max(0, minimumTimeIntervalBetweenPolls - timeSinceLastPollStarted)
                let remainingTime = max(0, Self.timeout - elapsedTime())

                // If another `/poll` cannot start before we time out, give up polling.
                guard delay < remainingTime else {
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

                lastPollStartElapsedTime = elapsedTime()
                pollResponse = try await apiClient.pollCheckoutSession(
                    checkoutSessionId: checkoutSessionId,
                    timeout: remainingTime
                )
            } catch let error as CancellationError {
                throw error
            } catch {
                try Task.checkCancellation()

                if Self.isRateLimitError(error) {
                    // Increase minimum interval between polls to try to stop being rate limited
                    minimumTimeIntervalBetweenPolls = Self.rateLimitTimeInterval(
                        retryCount: consecutiveRateLimitCount
                    )
                    consecutiveRateLimitCount += 1
                }
                continue
            }

            // At this point, `/poll` succeeded. Reset the interval and consecutive rate-limit count.
            minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
            consecutiveRateLimitCount = 0

            // 3. Check the /poll status
            if pollResponse.paymentObjectStatus == .requiresPaymentMethod {
                // 3a. Payment failed, do a full retrieve so we can update the Session
                let session = try await apiClient.retrieveCheckoutSession(
                    checkoutSessionId: checkoutSessionId
                )
                throw Error.paymentFailed(session: session)
            }

            switch pollResponse.state {
            case .active,
                 .processingSyncPayment,
                 .processingSubscription:
                // 3b. Checkout Session is still processing, continue polling
                continue
            case .succeeded,
                 .processingAsyncPayment,
                 .pendingAsyncCustomerAction,
                 .invalid,
                 .expired:
                // 3b. Checkout Session is client-complete, we're done!
                return
            }
        }
    }

    /// Returns an exponentially increasing minimum poll interval of 2, 4, then 8 seconds,
    /// capped at 8 seconds. This matches the defaults used by EwCS's
    /// `calculateExponentialBackoff`.
    /// https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/stripe-js-v3/src/checkout/shared/helpers/exponentialBackoff.ts?L18-25
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
