//
//  PollingCoordinator.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Coordinates polling behavior for intent status updates.
///
/// This class manages the polling lifecycle including:
/// - Creating appropriate polling budgets based on payment method type
/// - Scheduling poll attempts with appropriate delays
/// - Handling network timeouts and retries
/// - Determining when polling should stop
final class PollingCoordinator {

    // MARK: - Properties

    private var pollingBudget: PollingBudget?
    private let startDate: Date

    // MARK: - Initialization

    init(startDate: Date = Date()) {
        self.startDate = startDate
    }

    // MARK: - Polling Budget Management

    /// Creates or returns an existing polling budget for the given payment method type.
    /// - Parameter paymentMethodType: The payment method type to create a budget for
    /// - Returns: A polling budget, or nil if the payment method doesn't require polling
    func getOrCreateBudget(for paymentMethodType: STPPaymentMethodType) -> PollingBudget? {
        if let existing = pollingBudget {
            return existing
        }
        let budget = PollingBudget(startDate: startDate, paymentMethodType: paymentMethodType)
        self.pollingBudget = budget
        return budget
    }

    /// Creates a minimal polling budget for error recovery (allows one retry).
    /// - Returns: A polling budget with minimal duration
    func createMinimalBudget() -> PollingBudget {
        let budget = PollingBudget(startDate: Date(), duration: 1)
        self.pollingBudget = budget
        return budget
    }

    /// Creates a polling budget for processing state (30 seconds).
    /// - Returns: A polling budget for processing status polling
    func createProcessingBudget() -> PollingBudget {
        let budget = PollingBudget(startDate: startDate, duration: 30)
        self.pollingBudget = budget
        return budget
    }

    /// Returns the current polling budget if one exists.
    var currentBudget: PollingBudget? {
        return pollingBudget
    }

    /// Returns whether polling is currently allowed.
    var canPoll: Bool {
        return pollingBudget?.canPoll ?? true
    }

    /// The network timeout to use for API requests based on remaining polling budget.
    var networkTimeout: NSNumber? {
        return pollingBudget?.networkTimeout
    }

    // MARK: - Polling Execution

    /// Schedules a poll attempt after the appropriate delay.
    /// - Parameter block: The block to execute for the poll attempt
    func pollAfter(block: @escaping () -> Void) {
        if let budget = pollingBudget {
            budget.pollAfter(block: block)
        } else {
            // If no budget exists, execute immediately
            DispatchQueue.main.async(execute: block)
        }
    }

    /// Resets the polling coordinator state.
    func reset() {
        pollingBudget = nil
    }
}

// MARK: - Payment Method Type Helpers

extension PollingCoordinator {

    /// Determines if the given payment method type requires polling for status updates.
    /// - Parameter type: The payment method type
    /// - Returns: `true` if the payment method type benefits from polling
    static func shouldPoll(for type: STPPaymentMethodType) -> Bool {
        switch type {
        case .amazonPay, .revolutPay, .swish, .twint, .przelewy24, .payPay, .card:
            return true
        default:
            return false
        }
    }

    /// Returns the recommended polling duration for the given payment method type.
    /// - Parameter type: The payment method type
    /// - Returns: The polling duration in seconds, or nil if no polling is needed
    static func pollingDuration(for type: STPPaymentMethodType) -> TimeInterval? {
        switch type {
        case .amazonPay, .revolutPay, .swish, .twint, .przelewy24, .payPay:
            return 5.0
        case .card:
            return 15.0
        default:
            return nil
        }
    }
}
