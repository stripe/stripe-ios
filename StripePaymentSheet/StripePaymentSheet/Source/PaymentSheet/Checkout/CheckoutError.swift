//
//  CheckoutError.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An error returned by ``Checkout``.
@_spi(CheckoutSessionsPreview) public enum CheckoutError: Error, LocalizedError, Sendable {
    /// The client secret provided to ``Checkout`` is empty.
    case invalidClientSecret

    /// The session could not be resolved. This should not occur after a successful ``Checkout`` init.
    case sessionNotLoaded

    /// The session is no longer open (e.g. it has been completed or expired).
    case sessionNotOpen

    /// A payment sheet or form is currently presented. Dismiss it before making changes.
    case sheetCurrentlyPresented

    /// The Stripe API returned an error with the given message.
    case apiError(message: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidClientSecret:
            return "Checkout was initialized with an empty client secret."
        case .sessionNotLoaded:
            return "The session could not be resolved."
        case .sessionNotOpen:
            return "The session is no longer active."
        case .sheetCurrentlyPresented:
            return "A payment sheet or form is currently presented. Dismiss it before making changes."
        case .apiError(let message):
            return message
        }
    }
}
