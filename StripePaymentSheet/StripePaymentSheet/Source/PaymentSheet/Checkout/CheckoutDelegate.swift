//
//  CheckoutDelegate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Receives updates when the underlying ``Checkout`` session data changes.
///
/// This delegate is not called for every loading-state transition. A callback may
/// receive `.loading` when fresh session data arrives while another operation is
/// still queued, and no matching `.loaded` callback is guaranteed when the queue
/// drains. Observe ``Checkout/state`` directly for every loading/loaded transition.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public protocol CheckoutDelegate: AnyObject {
    /// Tells the delegate that the checkout session data changed.
    /// - Parameters:
    ///   - checkout: The instance whose state changed.
    ///   - state: The new state.
    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State)
}

/// Default no-op implementations.
@_spi(STP)
@_spi(ReactNativeSDK)
public extension CheckoutDelegate {
    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State) {
        // Default empty implementation
    }
}
