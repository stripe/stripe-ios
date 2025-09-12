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
    let duration: PollingDuration
    /// Whether polling is currently allowed (within budget)
    private(set) var canPoll: Bool = true

    /// The elapsed time since polling started, or nil if polling hasn't started
    private var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startDate)
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
        if elapsedTime > duration.value {
            canPoll = false
        }
    }
}
