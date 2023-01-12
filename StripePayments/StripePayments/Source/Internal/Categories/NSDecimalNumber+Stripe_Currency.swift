//
//  NSDecimalNumber+Stripe_Currency.swift
//  StripePayments
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSDecimalNumber {

    @objc @_spi(STP) public class func stp_decimalNumber(
        withAmount amount: Int,
        currency: String?
    ) -> NSDecimalNumber {
        let number = self.init(mantissa: UInt64(amount), exponent: 0, isNegative: false)
        let decimalCount = decimalCount(for: currency)
        return number.multiplying(byPowerOf10: -Int16(decimalCount))
    }

    @objc @_spi(STP) public func stp_amount(withCurrency currency: String?) -> Int {
        var ourNumber = self
        let decimalCount = NSDecimalNumber.decimalCount(for: currency)
        ourNumber = multiplying(byPowerOf10: Int16(decimalCount))
        return Int(ourNumber.doubleValue)
    }

    private class func decimalCount(for currency: String?) -> Int {
        let currencyLocaleIdentifier = Locale.availableIdentifiers.first(where: {
            let locale = Locale(identifier: $0)
            return locale.currencyCode?.lowercased() == currency?.lowercased()
        })

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: currencyLocaleIdentifier ?? "")

        return currencyFormatter.maximumFractionDigits
    }
}
