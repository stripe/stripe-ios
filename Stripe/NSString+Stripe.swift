//
//  NSString+Stripe.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

extension String {
    /// Returns a substring up to the specified index.
    ///
    /// This method clamps out-of-bound indexes and always returns a valid (non-nil) string.
    ///
    /// - Parameter index: Index of last character to include in the substring.
    /// - Returns: Substring.
    func stp_safeSubstring(to index: Int) -> String {
        let maxLength = max(min(index, count), 0)
        return String(prefix(maxLength))
    }

    /// Returns the substring starting from the specified index.
    ///
    /// This method clamps out-of-bound indexes and always returns a valid (non-nil) string.
    ///
    /// - Parameter index: Index of starting point of substring.
    /// - Returns: Substring.
    func stp_safeSubstring(from index: Int) -> String {
        let maxLength = max(min(count - index, count), 0)
        return String(suffix(maxLength))
    }

    func stp_string(byRemovingSuffix suffix: String?) -> String {
        if let suffix = suffix, self.hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        } else {
            return self
        }
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
