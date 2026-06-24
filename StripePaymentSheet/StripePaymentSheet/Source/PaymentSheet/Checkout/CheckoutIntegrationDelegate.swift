//
//  CheckoutIntegrationDelegate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/11/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

/// Internal delegate for payment integrations (PaymentSheet, FlowController, EmbeddedPaymentElement)
/// to communicate with a ``Checkout`` instance.
@MainActor
protocol CheckoutIntegrationDelegate: AnyObject {
    /// Whether the integration is currently presenting a payment sheet or form.
    var isSheetPresented: Bool { get }

    /// Called by ``Checkout`` whenever its underlying session changes.
    /// Implementors should re-render their UI to reflect the updated session
    /// and throw if the re-render fails (e.g. zero supported payment methods).
    func checkoutDidUpdate(_ checkout: Checkout) async throws
}
