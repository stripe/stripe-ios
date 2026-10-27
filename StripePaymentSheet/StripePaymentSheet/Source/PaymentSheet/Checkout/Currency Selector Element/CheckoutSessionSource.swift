//
//  CheckoutSessionSource.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/27/26.
//

import Combine

/// Provides Checkout Session state without exposing Checkout itself.
struct CheckoutSessionSource {
    let initialSession: CheckoutController.Session
    let sessionPublisher: Published<CheckoutController.Session>.Publisher
}
