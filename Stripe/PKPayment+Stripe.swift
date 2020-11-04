//
//  PKPayment+Stripe.swift
//  Stripe
//
//  Created by Ben Guo on 7/2/15.
//

import PassKit

extension PKPayment {
  /// Returns true if the instance is a payment from the simulator.
  @objc func stp_isSimulated() -> Bool {
    return token.transactionIdentifier == "Simulated Identifier"
  }

  /// Returns a fake transaction identifier with the expected ~-separated format.
  @objc class func stp_testTransactionIdentifier() -> String? {
    var uuid = UUID().uuidString
    uuid = uuid.replacingOccurrences(of: "~", with: "")

    // Simulated cards don't have enough info yet. For now, use a fake Visa number
    let number = "4242424242424242"

    // Without the original PKPaymentRequest, we'll need to use fake data here.
    let amount = NSDecimalNumber(string: "0")
    let cents = NSNumber(value: amount.multiplying(byPowerOf10: 2).intValue).stringValue
    let currency = "USD"
    let identifier = ["ApplePayStubs", number, cents, currency, uuid].joined(separator: "~")
    return identifier
  }
}
