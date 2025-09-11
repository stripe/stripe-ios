//
//  PollingBudget.swift
//  StripePayments
//
//  Created by Nick Porter on 9/11/25.
//

import Foundation

/// Manages polling budgets for payment method transactions that require status polling.
/// Supports both duration-based and count-based budgets to control polling behavior.
final class PollingBudget {
    /// The timestamp when polling started (set when start() is called)
    private var startDate: Date?
    /// The maximum duration allowed for polling (in seconds)
    let maxDuration: TimeInterval
    /// Whether a final poll has been executed
    private(set) var hasPolledFinal: Bool = false

    /// Detects if we're running in stub playback mode (HTTPStubs active but not recording)
    private var isTestMode: Bool {
        // Only scale duration when we're using stubs (HTTPStubs present) but not recording (STP_RECORD_NETWORK absent)
        return NSClassFromString("HTTPStubs") != nil && ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] == nil
    }

    /// Determines if there is remaining budget for additional polling attempts.
    /// Returns false if a final poll has already been executed or budget is exhausted.
    var hasBudgetRemaining: Bool {
        guard !hasPolledFinal else { return false }
        guard let startDate = startDate else { return true } // Not started yet
        
        let elapsed = Date().timeIntervalSince(startDate)
        // Scale duration down for test mode to account for instant stub responses
        let adjustedDuration = isTestMode ? maxDuration * 0.001 : maxDuration
        return elapsed < adjustedDuration
    }

    /// Creates a polling budget appropriate for the given payment method type.
    /// Returns nil if the payment method doesn't require polling.
    init?(paymentMethodType: STPPaymentMethodType) {
        switch paymentMethodType {
        case .amazonPay, .revolutPay, .swish, .twint, .przelewy24:
            self.maxDuration = 5.0
        case .card:
            self.maxDuration = 15.0
        default:
            return nil
        }
    }

    /// Creates a polling budget with the specified duration.
    /// - Parameter duration: The maximum duration for polling in seconds. Must be positive.
    init(duration: TimeInterval) {
        assert(duration > 0, "Duration must be positive")
        self.maxDuration = duration
    }

    /// Starts the polling timer. Should be called when polling begins.
    func start() {
        if startDate == nil {
            startDate = Date()
        }
    }

    /// Marks the polling as complete. No further attempts will be allowed after this.
    func invalidate() {
        hasPolledFinal = true
    }
}
