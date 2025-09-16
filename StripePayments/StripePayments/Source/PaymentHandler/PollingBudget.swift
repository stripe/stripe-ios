//
//  PollingBudget.swift
//  StripePayments
//
//  Created by Nick Porter on 9/11/25.
//

import Foundation

/// Manages polling budgets for payment method transactions that require status polling.
final class PollingBudget {
    /// The timestamp when polling started (set when start() is called)
    private var startDate: Date
    /// The polling duration in seconds
    private let duration: TimeInterval
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
        let remainingTime = duration - elapsedTime
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
            self.duration = 5.0
        case .card:
            self.duration = 15.0
        default:
            return nil
        }
    }

    /// Creates a polling budget with the specified duration.
    /// - Parameter startDate: Date of the first poll
    /// - Parameter duration: The maximum duration for polling in seconds. Must be positive.
    init(startDate: Date, duration: TimeInterval) {
        assert(duration > 0, "Duration must be positive")
        self.startDate = startDate
        self.duration = duration
    }

    /// Records a polling attempt and updates the budget status if needed.
    func recordPollAttempt() {
        lastPollAttempt = Date()
        if elapsedTime > duration {
            canPoll = false
        }
    }

    /// Calculates the recommended delay before the next poll
    /// - Parameter targetInterval: The desired time interval between poll starts (default: 1.0 second)
    /// - Returns: The time to wait before the next poll, optimized based on the last poll timing
    func recommendedDelay(targetInterval: TimeInterval = 1.0) -> TimeInterval {
        let timeSinceLastPoll = Date().timeIntervalSince(lastPollAttempt ?? startDate)
        // If enough time has passed, poll immediately. Otherwise, wait for the remaining time.
        return max(0, targetInterval - timeSinceLastPoll)
    }

    /// Executes a block after the recommended delay and automatically records the poll attempt
    /// - Parameter block: Block to execute after the delay
    func pollAfter(block: @escaping () -> Void) {
        let optimizedDelay = recommendedDelay(targetInterval: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + optimizedDelay) {
            self.recordPollAttempt()
            block()
        }
    }
}
