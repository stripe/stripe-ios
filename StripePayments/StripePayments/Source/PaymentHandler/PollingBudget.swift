//
//  PollingBudget.swift
//  StripePayments
//
//  Created by Nick Porter on 9/11/25.
//

import Foundation

/// Represents a polling duration with automatic test environment adjustment
struct PollingDuration {
    private let rawValue: TimeInterval

    /// The duration value, automatically adjusted for test environments
    var value: TimeInterval {
        // Scale duration down for test mode to account for instant stub responses.
        // During tests where we record network traffic, if we are hitting stubs we can make more network requests
        // due to near-instant network responses, so we need to scale down the polling duration to account for this.
        return isInNetworkStubbedTest ? rawValue * 0.4 : rawValue
    }

    /// Detects if we're running in stub playback mode (HTTPStubs active but not recording)
    private var isInNetworkStubbedTest: Bool {
        // Only scale duration when we're using stubs (HTTPStubs present) but not recording (STP_RECORD_NETWORK absent)
        return NSClassFromString("HTTPStubs") != nil && ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] == nil
    }

    /// Creates a polling duration with the specified duration
    init(_ duration: TimeInterval) {
        assert(duration > 0, "Duration must be positive")
        self.rawValue = duration
    }

    /// Standard duration for card payments (15 seconds)
    static let card = PollingDuration(15.0)

    /// Standard duration for LPMs like Amazon Pay, Revolut Pay, Swish (5 seconds)
    static let lpm = PollingDuration(5.0)
}

/// Manages polling budgets for payment method transactions that require status polling.
/// Supports both duration-based and count-based budgets to control polling behavior.
final class PollingBudget {
    /// The timestamp when polling started (set when start() is called)
    private var startDate: Date?
    /// The polling duration with automatic test environment adjustment
    let duration: PollingDuration
    /// Whether polling is currently allowed (within budget)
    private(set) var canPoll: Bool = true

    /// The elapsed time since polling started, or nil if polling hasn't started
    private var elapsedTime: TimeInterval? {
        guard let startDate = startDate else { return nil }
        return Date().timeIntervalSince(startDate)
    }

    /// Creates a polling budget appropriate for the given payment method type.
    /// Returns nil if the payment method doesn't require polling.
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
    /// - Parameter duration: The maximum duration for polling in seconds. Must be positive.
    init(startDate: Date, duration: TimeInterval) {
        self.startDate = startDate
        self.duration = PollingDuration(duration)
    }

    /// Begins the polling session. Should be called when polling starts.
    func beginPolling() {
        if startDate == nil {
            startDate = Date()
        }
    }

    /// Records a polling attempt and updates the budget status.
    func recordPollAttempt() {
        guard let elapsed = elapsedTime else { return } // Not started yet
        if elapsed > duration.value {
            canPoll = false
        }
    }
}
