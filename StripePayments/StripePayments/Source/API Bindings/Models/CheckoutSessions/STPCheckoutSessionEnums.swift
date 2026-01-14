//
//  STPCheckoutSessionEnums.swift
//  StripePayments
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Status types for an STPCheckoutSession
@_spi(STP) @objc public enum STPCheckoutSessionStatus: Int {
    /// Unknown status
    case unknown
    /// The checkout session is still open and can accept payment
    case open
    /// The checkout session is complete. Payment processing may still be in progress
    case complete
    /// The checkout session has expired. No further processing will occur
    case expired

    /// Parse the string and return the correct `STPCheckoutSessionStatus`,
    /// or `STPCheckoutSessionStatus.unknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the string with the status value
    internal static func status(from string: String) -> STPCheckoutSessionStatus {
        let map: [String: STPCheckoutSessionStatus] = [
            "open": .open,
            "complete": .complete,
            "expired": .expired,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }

    /// Returns the string value for this status, or nil if unknown
    internal var stringValue: String? {
        switch self {
        case .open:
            return "open"
        case .complete:
            return "complete"
        case .expired:
            return "expired"
        case .unknown:
            return nil
        }
    }
}

/// Mode types for an STPCheckoutSession
@_spi(STP) @objc public enum STPCheckoutSessionMode: Int {
    /// Unknown mode
    case unknown
    /// Accept one-time payments for cards, iDEAL, and more
    case payment
    /// Save payment details to charge your customers later
    case setup
    /// Use Stripe Billing to set up fixed-price subscriptions
    case subscription

    /// Parse the string and return the correct `STPCheckoutSessionMode`,
    /// or `STPCheckoutSessionMode.unknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the string with the mode value
    internal static func mode(from string: String) -> STPCheckoutSessionMode {
        let map: [String: STPCheckoutSessionMode] = [
            "payment": .payment,
            "setup": .setup,
            "subscription": .subscription,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }

    /// Returns the string value for this mode, or nil if unknown
    internal var stringValue: String? {
        switch self {
        case .payment:
            return "payment"
        case .setup:
            return "setup"
        case .subscription:
            return "subscription"
        case .unknown:
            return nil
        }
    }
}

/// Payment status types for an STPCheckoutSession
@_spi(STP) @objc public enum STPCheckoutSessionPaymentStatus: Int {
    /// Unknown payment status
    case unknown
    /// The payment funds are available in your account
    case paid
    /// The payment funds are not yet available in your account
    case unpaid
    /// The payment is delayed to a future date, or the Checkout Session is in setup mode
    /// and doesn't require a payment at this time
    case noPaymentRequired

    /// Parse the string and return the correct `STPCheckoutSessionPaymentStatus`,
    /// or `STPCheckoutSessionPaymentStatus.unknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the string with the payment status value
    internal static func paymentStatus(from string: String) -> STPCheckoutSessionPaymentStatus {
        let map: [String: STPCheckoutSessionPaymentStatus] = [
            "paid": .paid,
            "unpaid": .unpaid,
            "no_payment_required": .noPaymentRequired,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }

    /// Returns the string value for this payment status, or nil if unknown
    internal var stringValue: String? {
        switch self {
        case .paid:
            return "paid"
        case .unpaid:
            return "unpaid"
        case .noPaymentRequired:
            return "no_payment_required"
        case .unknown:
            return nil
        }
    }
}
