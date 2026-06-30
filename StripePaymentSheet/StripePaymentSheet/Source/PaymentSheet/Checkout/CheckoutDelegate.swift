//
//  CheckoutDelegate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Receives updates when the ``Checkout`` loading state or session data changes.
///
/// Note if multiple updates are called on the ``Checkout`` in rapid succession,
/// ``checkoutDidBeginLoading`` and ``checkoutDidFinishLoading``
/// may only be called once. Accordingly, use these only to track whether the ``Checkout``
/// is in a loading state or not and listen to ``checkoutDidUpdateSession`` to
/// be notified of every update completion and the resulting session data.
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
