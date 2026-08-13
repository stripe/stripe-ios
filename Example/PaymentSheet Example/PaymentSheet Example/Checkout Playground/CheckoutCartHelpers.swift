//
//  CheckoutCartHelpers.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

import Foundation

func formatCartCurrency(
    minorUnitsAmount: Double,
    currency: String?,
    minorUnitsAmountDivisor: Int?
) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency?.uppercased() ?? "USD"
    formatter.maximumFractionDigits += 12

    let divisor = minorUnitsAmountDivisor ?? 100
    let decimalAmount = Decimal(minorUnitsAmount) / Decimal(divisor)
    return formatter.string(from: NSDecimalNumber(decimal: decimalAmount)) ?? "$\(decimalAmount)"
}
