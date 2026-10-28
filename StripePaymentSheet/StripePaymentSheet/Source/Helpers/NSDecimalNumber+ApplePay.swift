//
//  NSDecimalNumber+ApplePay.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

extension NSDecimalNumber {
    func roundedForApplePay(currency: String?) -> NSDecimalNumber {
        // Apple Pay rejects fractional amounts for this list of currencies. Match Stripe.js by rounding them up.
        guard let currency, NSDecimalNumber.decimalCountSpecialCases[currency.uppercased()] != nil else {
            return self
        }
        return rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .up,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
    }
}
