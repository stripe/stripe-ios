//
//  CheckoutSessionPoller.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

// MARK: - Dependencies
protocol CheckoutSessionPollingAPIClient {
    func pollCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        timeout: TimeInterval
    ) async throws -> CheckoutClientPollResponse
}

class CheckoutSessionPollingClock {
    func now() -> TimeInterval {
        Date().timeIntervalSinceReferenceDate
    }

    func sleep(for duration: TimeInterval) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
                continuation.resume()
            }
        }
    }
}

/// Polls a Checkout Session until confirmation can continue or polling times out.
struct CheckoutSessionPoller {
    enum Outcome: Equatable {
        /// Confirmation succeeded, with the latest server-reported Session fields.
        case succeeded(CheckoutClientPollResponse)

        /// Confirmation failed, with the latest server-reported Session fields.
        case failed(CheckoutClientPollResponse)

        /// No confirmation was recorded after an accepted /confirm. The caller must report an unexpected error.
        case notStarted(CheckoutClientPollResponse)

        /// Polling timed out. Preserve the last decoded response, or the /confirm fields if no poll succeeded.
        case timedOut(lastResponse: CheckoutClientPollResponse?)
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

    /// Polls while `confirmationStatus` is pending, up to the polling timeout.
    /// - Returns: The outcome and response that stopped polling. On timeout, includes the last successfully
    ///   decoded response, or nil if none succeeded.
    /// - Note: Request failures are retried until timeout without discarding the last successful response.
    func poll(checkoutSessionId: String, clientSecret: String) async -> Outcome {
        let startTime = clock.now()
        var lastPollStartElapsedTime: TimeInterval?
        var minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
        var consecutiveRateLimitCount = 0
        var lastResponse: CheckoutClientPollResponse?

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
                    return .timedOut(lastResponse: lastResponse)
                }

                if delay > 0 {
                    await clock.sleep(for: delay)
                }
            }

            // 2. Poll the Checkout Session. Retry request failures until the timeout is reached.
            let pollResponse: CheckoutClientPollResponse
            do {
                let remainingTime = Self.timeout - elapsedTime()
                guard remainingTime > 0 else {
                    return .timedOut(lastResponse: lastResponse)
                }

                lastPollStartElapsedTime = elapsedTime()
                pollResponse = try await apiClient.pollCheckoutSession(
                    checkoutSessionId: checkoutSessionId,
                    clientSecret: clientSecret,
                    timeout: remainingTime
                )
            } catch {
                if Self.isRateLimitError(error) {
                    // Increase minimum interval between polls to try to stop being rate limited
                    minimumTimeIntervalBetweenPolls = Self.rateLimitTimeInterval(
                        retryCount: consecutiveRateLimitCount
                    )
                    consecutiveRateLimitCount += 1
                }
                continue
            }

            lastResponse = pollResponse

            // At this point, `/poll` succeeded. Reset the interval and consecutive rate-limit count.
            minimumTimeIntervalBetweenPolls = Self.minimumTimeInterval
            consecutiveRateLimitCount = 0

            // 3. Determine whether we are done polling
            switch pollResponse.confirmationStatus {
            case .pending:
                continue
            case .succeeded:
                return .succeeded(pollResponse)
            case .failed:
                return .failed(pollResponse)
            case .notStarted:
                return .notStarted(pollResponse)
            }
        }

        return .timedOut(lastResponse: lastResponse)
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
