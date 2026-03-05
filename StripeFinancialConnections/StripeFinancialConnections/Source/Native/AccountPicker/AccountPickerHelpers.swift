//
//  AccountPickerHeleprs.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

import UIKit

final class AccountPickerHelpers {

    static func rowInfo(
        forAccount account: FinancialConnectionsPartnerAccount
    ) -> (
        accountName: String,
        accountNumbers: String?,
        balanceString: String?
    ) {
        return (
            accountName: account.name,
            accountNumbers: {
                if let displayableAccountNumbers = account.displayableAccountNumbers {
                   return "••••\(displayableAccountNumbers)"
                } else {
                    return nil
                }
            }(),
            balanceString: {
                if let balanceInfo = account.balanceInfo {
                    return currencyString(currency: balanceInfo.currency, balanceAmount: balanceInfo.balanceAmount)
                } else {
                    return nil
                }
            }()
        )
    }

    // exposed for testing purposes
    static func currencyString(
        currency: String,
        balanceAmount: Int,
        locale: Locale = .current
    ) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = currency
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        return numberFormatter.string(
            for: NSDecimalNumber.stp_fn_decimalNumber(withAmount: balanceAmount, currency: currency)
        )
    }
}

// TODO(kgaidis): move this to StripeCore

extension NSDecimalNumber {
    @objc class func stp_fn_decimalNumber(
        withAmount amount: Int,
        currency: String?
    ) -> NSDecimalNumber {
        let isAmountNegative = amount < 0
        let amount = abs(amount)

        let noDecimalCurrencies = self.stp_fn_currenciesWithNoDecimal()
        let number = self.init(mantissa: UInt64(amount), exponent: 0, isNegative: isAmountNegative)
        if noDecimalCurrencies.contains(currency?.lowercased() ?? "") {
            return number
        }
        return number.multiplying(byPowerOf10: -2)
    }

    class func stp_fn_currenciesWithNoDecimal() -> [String] {
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
