//
//  STPCheckoutSession+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation

extension STPCheckoutSession: Checkout.Session {
    var id: String { stripeId }

    var selectedShippingOption: Checkout.ShippingOption? {
        guard let id = selectedShippingOptionId else { return nil }
        return shippingOptions.first(where: { $0.id == id })
    }

    var billingAddress: Checkout.AddressUpdate? {
        billingAddressOverride
    }

    var shippingAddress: Checkout.AddressUpdate? {
        shippingAddressOverride
    }
}

// MARK: - Parsing Helpers

extension Checkout.Mode {
    static func mode(from string: String) -> Checkout.Mode {
        switch string.lowercased() {
        case "payment": return .payment
        case "setup": return .setup
        case "subscription": return .subscription
        default: return .unknown
        }
    }
}

extension Checkout.Status {
    static func status(from string: String) -> Checkout.Status {
        switch string.lowercased() {
        case "open": return .open
        case "complete": return .complete
        case "expired": return .expired
        default: return .unknown
        }
    }
}

extension Checkout.PaymentStatus {
    static func paymentStatus(from string: String) -> Checkout.PaymentStatus {
        switch string.lowercased() {
        case "paid": return .paid
        case "unpaid": return .unpaid
        case "no_payment_required": return .noPaymentRequired
        default: return .unknown
        }
    }
}
