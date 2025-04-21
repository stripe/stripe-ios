//
//  NSDecimalNumber+Stripe_Currency.swift
//  StripePayments
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension NSDecimalNumber {
    // The number of decimal places for some currencies varies between Stripe and NumberFormatter,
    // This maps the currency code to the number of decimal digits.
    static let decimalCountSpecialCases = [
        "COP": 2,
        "PKR": 2,
        "LAK": 2,
        "RSD": 2,
        "IDR": 2,
        "ISK": 2,
    ]

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
        if let currency = currency?.uppercased(),
           let specialCase = Self.decimalCountSpecialCases[currency]
        {
            return specialCase
        }

        let currencyLocaleIdentifier = Locale.availableIdentifiers.first(where: {
            let locale = Locale(identifier: $0)
            return locale.stp_currencyCode?.lowercased() == currency?.lowercased()
        })

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: currencyLocaleIdentifier ?? "")

        return currencyFormatter.maximumFractionDigits
    }
}
