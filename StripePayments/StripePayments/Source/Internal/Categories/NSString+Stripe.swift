//
//  NSString+Stripe.swift
//  StripePayments
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

extension String {

    /// A Boolean value indicating whether the string contains only whitespace.
    @_spi(STP) public var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }

    /// Returns a substring up to the specified index.
    ///
    /// This method clamps out-of-bound indexes and always returns a valid (non-nil) string.
    ///
    /// - Parameter index: Index of last character to include in the substring.
    /// - Returns: Substring.
    @_spi(STP) public func stp_safeSubstring(to index: Int) -> String {
        let maxLength = max(min(index, count), 0)
        return String(prefix(maxLength))
    }

    /// Returns the substring starting from the specified index.
    ///
    /// This method clamps out-of-bound indexes and always returns a valid (non-nil) string.
    ///
    /// - Parameter index: Index of starting point of substring.
    /// - Returns: Substring.
    @_spi(STP) public func stp_safeSubstring(from index: Int) -> String {
        let maxLength = max(min(count - index, count), 0)
        return String(suffix(maxLength))
    }

    @_spi(STP) public func stp_string(byRemovingSuffix suffix: String?) -> String {
        if let suffix = suffix, self.hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        } else {
            return self
        }
    }

    // e.g. localizedAmountDisplayString(for: 1099, "USD") -> "$10.99" in en_US, "10,99 $" in fr_FR
    @_spi(STP) public static func localizedAmountDisplayString(
        for amount: Int,
        currency: String,
        locale: Locale = NSLocale.autoupdatingCurrent
    ) -> String {
        let decimalizedAmount = NSDecimalNumber.stp_decimalNumber(
            withAmount: amount,
            currency: currency
        )
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.locale = locale
        formatter.currencyCode = currency
        let failsafeString = "\(formatter.currencySymbol ?? "")\(decimalizedAmount)"
        return formatter.string(from: decimalizedAmount) ?? failsafeString
    }

    /// Function to determine if this string is the country code of the United State
    /// @param caseSensitive - Whether this string should only be considered the US country code if it matches the expected capitalization
    @_spi(STP) public func isUSCountryCode(_ caseSensitive: Bool = false) -> Bool {
        return caseSensitive ? self == "US" : self.caseInsensitiveCompare("US") == .orderedSame
    }

}
