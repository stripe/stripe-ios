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

    /// The checkout session has expired and can no longer be updated or confirmed.
    case sessionExpired

    /// The session is not in a valid state for this operation (e.g. not loaded or already completed).
    case sessionNotOpen

    /// The provided promotion code is invalid or not applicable.
    case invalidPromotionCode(code: String)

    /// The provided promotion code has expired.
    case promotionCodeExpired(code: String)

    /// The Stripe API returned an error with the given message.
    case apiError(message: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidClientSecret:
            return "Checkout was initialized with an empty client secret."
        case .sessionExpired:
            return "The checkout session has expired."
        case .sessionNotOpen:
            return "The session is no longer active."
        case .invalidPromotionCode(let code):
            return "The promotion code '\(code)' is invalid."
        case .promotionCodeExpired(let code):
            return "The promotion code '\(code)' has expired."
        case .apiError(let message):
            return message
        }
    }
}
