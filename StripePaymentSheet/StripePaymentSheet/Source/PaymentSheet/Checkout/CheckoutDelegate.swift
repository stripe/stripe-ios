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
    /// Tells the delegate that the checkout state changed.
    /// - Parameters:
    ///   - checkout: The instance whose state changed.
    ///   - state: The new state.
    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State)
}

/// Default no-op implementations.
@_spi(CheckoutSessionsPreview)
public extension CheckoutDelegate {
    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State) {
        // Default empty implementation
    }
}
