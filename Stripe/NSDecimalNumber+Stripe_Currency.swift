//
//  NSDecimalNumber+Stripe_Currency.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSDecimalNumber {
  @objc class func stp_decimalNumber(
    withAmount amount: Int,
    currency: String?
  ) -> NSDecimalNumber? {
    let noDecimalCurrencies = self.stp_currenciesWithNoDecimal()
    let number = self.init(mantissa: UInt64(amount), exponent: 0, isNegative: false)
    if noDecimalCurrencies.contains(currency?.lowercased() ?? "") {
      return number
    }
    return number.multiplying(byPowerOf10: -2)
  }

  @objc func stp_amount(withCurrency currency: String?) -> Int {
    let noDecimalCurrencies = NSDecimalNumber.stp_currenciesWithNoDecimal()

    var ourNumber = self
    if !(noDecimalCurrencies.contains(currency?.lowercased() ?? "")) {
      ourNumber = multiplying(byPowerOf10: 2)
    }
    return Int(ourNumber.doubleValue)
  }

  class func stp_currenciesWithNoDecimal() -> [String] {
    return [
      "bif",
      "clp",
      "djf",
      "gnf",
      "jpy",
      "kmf",
      "krw",
      "mga",
      "pyg",
      "rwf",
      "vnd",
      "vuv",
      "xaf",
      "xof",
      "xpf",
    ]
  }
}
