//
//  STPCheckoutSession+Session.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

// MARK: - Convenience

extension STPCheckoutSession {
    /// The factor used to convert between minor and major currency units. For USD this
    /// is `100`; for JPY this is `1`. `nil` when the session has no currency (e.g. setup mode).
    var minorUnitsAmountDivisor: Int? {
        guard let currency else { return nil }
        let oneMinorUnitInMajor = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMinorUnitInMajor))
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
