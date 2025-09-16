//
//  PollingBudget.swift
//  StripePayments
//
//  Created by Nick Porter on 9/11/25.
//

import Foundation

/// Represents a polling duration with automatic test environment adjustment
struct PollingDuration {
    /// Standard duration for card payments (15 seconds)
    static let card = PollingDuration(15.0)
    /// Standard duration for LPMs like Amazon Pay, Revolut Pay, Swish (5 seconds)
    static let lpm = PollingDuration(5.0)

    private let rawValue: TimeInterval

    /// The duration value, automatically adjusted for test environments
    var value: TimeInterval {
        // Scale duration down for test mode to account for instant stub responses.
        // During tests where we record network traffic, if we are hitting stubs we can make more network requests
        // due to near-instant network responses, so we need to scale down the polling duration to account for this.
        return isUsingNetworkStubs ? rawValue * 0.4 : rawValue
    }

    /// Detects if we're running in stub playback mode (HTTPStubs active but not recording)
    private var isUsingNetworkStubs: Bool {
        // Only scale duration when we're using stubs (HTTPStubs present and not recording the network STP_RECORD_NETWORK)
        return NSClassFromString("HTTPStubs") != nil && ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] == nil
    }

    /// Creates a polling duration with the specified duration
    init(_ duration: TimeInterval) {
        assert(duration > 0, "Duration must be positive")
        self.rawValue = duration
    }
}

/// Manages polling budgets for payment method transactions that require status polling.
final class PollingBudget {
    /// The timestamp when polling started (set when start() is called)
    private var startDate: Date
    /// The polling duration with automatic test environment adjustment
    private let duration: PollingDuration
    /// Whether polling is currently allowed (within budget)
    private(set) var canPoll: Bool = true
    /// The timestamp of the last recorded poll attempt
    private var lastPollAttempt: Date?

    /// The elapsed time since polling started
    private var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startDate)
    }

    /// Dynamic network timeout for API requests based on remaining polling budget.
    ///
    /// This computed property optimizes network timeouts by adjusting them according to the remaining
    /// time in the polling budget. It ensures that individual network requests don't exceed the total
    /// time allocated for polling, while providing a timeout for final polls (60 seconds).
    /// - Returns: An NSNumber containing the timeout in seconds
    var networkTimeout: NSNumber {
        let remainingTime = duration.value - elapsedTime
        // If we have no remaining time, default to 60 seconds for the final poll network timeout
        return NSNumber(value: remainingTime > 0 ? remainingTime : 60)
    }

    /// Creates a polling budget appropriate for the given payment method type.
    /// Returns nil if the payment method doesn't require polling.
    /// - Parameter startDate: Date of the first poll
    /// - Parameter paymentMethodType: The payment method type being polled for
    init?(startDate: Date, paymentMethodType: STPPaymentMethodType) {
        self.startDate = startDate
        switch paymentMethodType {
        case .amazonPay, .revolutPay, .swish, .twint, .przelewy24:
            self.duration = .lpm
        case .card:
            self.duration = .card
        default:
            return nil
        }
    }

    /// Creates a polling budget with the specified duration.
    /// - Parameter startDate: Date of the first poll
    /// - Parameter duration: The maximum duration for polling in seconds. Must be positive.
    init(startDate: Date, duration: TimeInterval) {
        self.startDate = startDate
        self.duration = PollingDuration(duration)
    }

    /// Records a polling attempt and updates the budget status if needed.
    func recordPollAttempt() {
        lastPollAttempt = Date()
        if elapsedTime > duration.value {
            canPoll = false
        }
    }

    /// Calculates the recommended delay before the next poll
    /// - Parameter targetInterval: The desired time interval between poll starts (default: 1.0 second)
    /// - Returns: The time to wait before the next poll, optimized based on the last poll timing
    func recommendedDelay(targetInterval: TimeInterval = 1.0) -> TimeInterval {
        guard let lastPollAttempt = lastPollAttempt else {
            // First poll - return the full target interval
            return targetInterval
        }

        let timeSinceLastPoll = Date().timeIntervalSince(lastPollAttempt)
        // If enough time has passed, poll immediately. Otherwise, wait for the remaining time.
        return max(0, targetInterval - timeSinceLastPoll)
    }
}
