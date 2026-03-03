//
//  CheckoutCartHelpers.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

import Foundation

func formatCartCurrency(amount: Int, currency: String?) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency?.uppercased() ?? "USD"

    let decimalAmount = Decimal(amount) / 100.0
    return formatter.string(from: NSDecimalNumber(decimal: decimalAmount)) ?? "$\(decimalAmount)"
}
