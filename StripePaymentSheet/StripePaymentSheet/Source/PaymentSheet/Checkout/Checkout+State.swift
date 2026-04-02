//
//  Checkout+State.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// The loading state of the checkout session.
    public enum State {
        /// The session is loaded and ready.
        case loaded(Session)
        /// A mutation is in progress. The associated session is the
        /// most recently loaded value and may be stale.
        case loading(Session)
    }
}

@_spi(CheckoutSessionsPreview)
extension Checkout.State {
    /// The session, regardless of loading state.
    public var session: Checkout.Session {
        switch self {
        case .loaded(let session), .loading(let session):
            return session
        }
    }

    /// Whether a mutation is in progress.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
