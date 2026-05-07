//
//  STPCheckoutSession+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

extension STPCheckoutSession: Checkout.Session {
    var id: String { stripeId }

    var billingAddress: Checkout.ContactAddress? {
        billingAddressOverride
    }

    var minorUnitsAmountDivisor: Int? {
        guard let currency else { return nil }
        let oneMajorUnit = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMajorUnit))
    }

    var shippingAddress: Checkout.ContactAddress? {
        shippingAddressOverride
    }
}

// MARK: - Mode parsing

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
