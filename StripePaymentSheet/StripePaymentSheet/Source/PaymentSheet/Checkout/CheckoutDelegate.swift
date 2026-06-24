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
    /// Tells the delegate that a mutation or refresh of the Checkout Session is in progress.
    /// - Parameters:
    ///   - checkout: The instance that began loading.
    func checkoutDidBeginLoading(_ checkout: Checkout)

    /// Tells the delegate that all mutations or refreshes of the Checkout Session have completed.
    /// - Parameters:
    ///   - checkout: The instance that finished loading.
    func checkoutDidFinishLoading(_ checkout: Checkout)

    /// Tells the delegate that the Checkout Session has updated.
    /// - Parameters:
    ///   - checkout: The instance that received new Checkout Session data.
    ///   - session: The updated Checkout Session from Stripe.
    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session)
}

/// Default no-op implementations.
@_spi(STP)
@_spi(ReactNativeSDK)
public extension CheckoutDelegate {
    func checkoutDidBeginLoading(_ checkout: Checkout) {
        // Default empty implementation
    }
    func checkoutDidFinishLoading(_ checkout: Checkout) {
        // Default empty implementation
    }
    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session) {
        // Default empty implementation
    }
}
