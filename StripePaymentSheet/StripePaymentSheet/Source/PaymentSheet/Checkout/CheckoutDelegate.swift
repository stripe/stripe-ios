//
//  CheckoutDelegate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Receives updates when a ``Checkout`` session changes.
@_spi(CheckoutSessionsPreview)
@MainActor
public protocol CheckoutDelegate: AnyObject {
    /// Tells the delegate that the session was updated.
    /// - Parameters:
    ///   - checkout: The instance that loaded or refreshed the session.
    ///   - session: The updated session.
    func checkout(_ checkout: Checkout, didUpdate session: Checkout.Session)
}

/// Default no-op implementations.
@_spi(CheckoutSessionsPreview)
public extension CheckoutDelegate {
    func checkout(_ checkout: Checkout, didUpdate session: Checkout.Session) {
        // Default empty implementation
    }
}
