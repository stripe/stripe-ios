//
//  StripeIntent.swift
//  StripePayments
//
//  Created for STPPaymentHandler refactoring.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation

// MARK: - Unified Intent Status

/// A unified status enum that represents the status of both PaymentIntents and SetupIntents.
/// This enables generic handling of intent status in STPPaymentHandler.
enum StripeIntentStatus: Equatable {
    case unknown
    case requiresPaymentMethod
    case requiresConfirmation
    case requiresAction
    case processing
    case succeeded
    case canceled
    case requiresCapture  // PaymentIntent only

    /// Creates a unified status from a PaymentIntent status.
    init(from status: STPPaymentIntentStatus) {
        switch status {
        case .unknown: self = .unknown
        case .requiresPaymentMethod: self = .requiresPaymentMethod
        case .requiresConfirmation: self = .requiresConfirmation
        case .requiresAction: self = .requiresAction
        case .processing: self = .processing
        case .succeeded: self = .succeeded
        case .requiresCapture: self = .requiresCapture
        case .canceled: self = .canceled
        @unknown default: self = .unknown
        }
    }

    /// Creates a unified status from a SetupIntent status.
    init(from status: STPSetupIntentStatus) {
        switch status {
        case .unknown: self = .unknown
        case .requiresPaymentMethod: self = .requiresPaymentMethod
        case .requiresConfirmation: self = .requiresConfirmation
        case .requiresAction: self = .requiresAction
        case .processing: self = .processing
        case .succeeded: self = .succeeded
        case .canceled: self = .canceled
        @unknown default: self = .unknown
        }
    }
}

// MARK: - StripeIntent Protocol

/// A protocol that provides a unified interface for both `STPPaymentIntent` and `STPSetupIntent`.
/// This enables generic handling of intents throughout STPPaymentHandler, eliminating duplication.
protocol StripeIntent: AnyObject {
    /// The Stripe ID of the intent.
    var intentStripeID: String { get }

    /// The client secret used for client-side operations.
    var clientSecret: String { get }

    /// Whether the intent exists in live mode.
    var livemode: Bool { get }

    /// The unified status of this intent.
    var unifiedStatus: StripeIntentStatus { get }

    /// The next action required, if any.
    var nextAction: STPIntentAction? { get }

    /// The payment method associated with this intent, if any.
    var paymentMethod: STPPaymentMethod? { get }
}

// MARK: - STPPaymentIntent Conformance

extension STPPaymentIntent: StripeIntent {
    var intentStripeID: String {
        return stripeId  // Note: STPPaymentIntent uses lowercase 'd'
    }

    var unifiedStatus: StripeIntentStatus {
        return StripeIntentStatus(from: status)
    }
}

// MARK: - STPSetupIntent Conformance

extension STPSetupIntent: StripeIntent {
    var intentStripeID: String {
        return stripeID  // Note: STPSetupIntent uses uppercase 'D'
    }

    var unifiedStatus: StripeIntentStatus {
        return StripeIntentStatus(from: status)
    }
}

// MARK: - Intent Error Protocol

/// A protocol for intent-specific error types (last payment error, last setup error).
protocol StripeIntentError {
    /// The error code, if any.
    var code: String? { get }

    /// The error message, if any.
    var message: String? { get }

    /// Whether this is an authentication failure error.
    var isAuthenticationFailure: Bool { get }

    /// Whether this is a card error.
    var isCardError: Bool { get }
}

extension STPPaymentIntentLastPaymentError: StripeIntentError {
    var isAuthenticationFailure: Bool {
        return code == STPPaymentIntentLastPaymentError.ErrorCodeAuthenticationFailure
    }

    var isCardError: Bool {
        return type == .card
    }
}

extension STPSetupIntentLastSetupError: StripeIntentError {
    var isAuthenticationFailure: Bool {
        return code == STPSetupIntentLastSetupError.CodeAuthenticationFailure
    }

    var isCardError: Bool {
        return type == .card
    }
}

// MARK: - Unified Action Params Protocol

/// A protocol that provides unified access to intent data from action params.
/// This enables generic handling of both PaymentIntent and SetupIntent actions.
protocol UnifiedIntentActionParams: STPPaymentHandlerActionParams {
    /// The intent as a unified StripeIntent protocol.
    var intent: any StripeIntent { get }

    /// The last error from the intent, if any.
    var lastError: (any StripeIntentError)? { get }

    /// Whether the processing status should be treated as success for this intent type.
    /// For PaymentIntents, this depends on the payment method type (e.g., SEPA Debit returns true).
    /// For SetupIntents, this is always false.
    var isProcessingSuccess: Bool { get }
}

// MARK: - Action Params Extensions

/// Extension to provide unified intent access from action params.
extension STPPaymentHandlerPaymentIntentActionParams: UnifiedIntentActionParams {
    /// The intent as a unified StripeIntent protocol.
    var intent: any StripeIntent {
        return paymentIntent
    }

    /// The last error from the intent, if any.
    var lastError: (any StripeIntentError)? {
        return paymentIntent.lastPaymentError
    }

    /// Whether the processing status should be treated as success for this intent type.
    var isProcessingSuccess: Bool {
        guard let type = paymentIntent.paymentMethod?.type else {
            return false
        }
        return STPPaymentHandler._isProcessingIntentSuccess(for: type)
    }
}

extension STPPaymentHandlerSetupIntentActionParams: UnifiedIntentActionParams {
    /// The intent as a unified StripeIntent protocol.
    var intent: any StripeIntent {
        return setupIntent
    }

    /// The last error from the intent, if any.
    var lastError: (any StripeIntentError)? {
        return setupIntent.lastSetupError
    }

    /// SetupIntents don't have processing success states.
    var isProcessingSuccess: Bool {
        return false
    }
}
