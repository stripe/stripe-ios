//
//  CheckoutSessionExpressCheckoutUpdater.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/31/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

/// Session update interface for ExpressCheckoutElement.
///
/// ECE can update billing address, shipping address, and other session state
/// from within the sheet. This keeps ECE plumbing from depending on the full `Checkout` object or reading
/// `checkout.session` directly. Callers must use these sanctioned update methods to sync
/// billing tax changes or commit session updates.
@MainActor
protocol CheckoutSessionExpressCheckoutUpdater: AnyObject {
    // TODO: implement session updates
}

extension Checkout: CheckoutSessionExpressCheckoutUpdater {}
