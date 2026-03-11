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
}
