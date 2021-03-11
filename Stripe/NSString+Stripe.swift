//
//  NSString+Stripe.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

extension String {
    func stp_safeSubstring(to index: Int) -> String {
        return String(prefix(min(index, count)))
    }

    func stp_safeSubstring(from index: Int) -> String {
        if index > count {
            return ""
        }
        return String(suffix(count - index))
    }

    func stp_string(byRemovingSuffix suffix: String?) -> String {
        if let suffix = suffix, self.hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        } else {
            return self
        }
    }

    func stp_stringByRemovingCharacters(from characterSet: CharacterSet) -> String {
        return String(unicodeScalars.filter { !characterSet.contains($0) })
    }

    // e.g. localizedAmountDisplayString(for: 1099, "USD") -> "$10.99" in en_US, "10,99 $" in fr_FR
    static func localizedAmountDisplayString(
        for amount: Int,
        currency: String,
        locale: Locale = NSLocale.autoupdatingCurrent
    ) -> String {
        let decimalizedAmount = NSDecimalNumber.stp_decimalNumber(
            withAmount: amount, currency: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.locale = locale
        formatter.currencyCode = currency
        let failsafeString = "\(formatter.currencySymbol ?? "")\(decimalizedAmount)"
        return formatter.string(from: decimalizedAmount) ?? failsafeString
    }
}
