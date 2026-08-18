//
//  ExpressCheckoutSessionUpdater.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

/// Narrow Checkout interface for Express Checkout (Apple Pay, Link) confirmation flows.
///
/// This keeps express checkout plumbing from depending on the full `Checkout` object or reading
/// `checkout.session` directly. Will grow to cover shipping address and promo code
/// updates as ECE's Apple Pay flow supports them.
@MainActor
protocol ExpressCheckoutSessionUpdater: AnyObject {
    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws
}

extension Checkout: ExpressCheckoutSessionUpdater {}
