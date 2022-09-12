//
//  AccountPickerHeleprs.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

import Foundation

final class AccountPickerHelpers {
    static func rowTitles(forAccount account: FinancialConnectionsPartnerAccount) -> (leadingTitle: String, trailingTitle: String?) {
        let willDisplayBalanceInfoInSubtitle = account.balanceInfo != nil
        if willDisplayBalanceInfoInSubtitle {
            return (account.name, "••••\(account.displayableAccountNumbers ?? "")")
        } else {
            return (account.name, nil)
        }
    }
    
    static func rowSubtitle(forAccount account: FinancialConnectionsPartnerAccount) -> String? {
        if let balanceInfo = account.balanceInfo {
            return currencyString(currency: balanceInfo.currency, balanceAmount: balanceInfo.balanceAmount)
        } else {
            if let displayableAccountNumbers = account.displayableAccountNumbers {
                return "••••••••\(displayableAccountNumbers)"
            } else {
                return nil
            }
        }
    }
    
    static func currencyString(currency: String, balanceAmount: Double) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = currency
        numberFormatter.numberStyle = .currency
        return numberFormatter.string(for: NSDecimalNumber.stp_decimalNumber(withAmount: Int(balanceAmount), currency: currency))
    }
}

// TODO(kgaidis): move this to StripeCore

extension NSDecimalNumber {
    @objc class func stp_decimalNumber(
        withAmount amount: Int,
        currency: String?
    ) -> NSDecimalNumber {
        let isAmountNegative = amount < 0
        let amount = abs(amount)
        
        let noDecimalCurrencies = self.stp_currenciesWithNoDecimal()
        let number = self.init(mantissa: UInt64(amount), exponent: 0, isNegative: isAmountNegative)
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
