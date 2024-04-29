//
//  CardExpiryDate.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 4/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Value Object for representing a card expiry date.
///
/// Cards expire at the end of the month written on the card.
struct CardExpiryDate {
    let month: Int
    let year: Int

    /// A string value to be entered into a date text field.
    var displayString: String {
        return String(format: "%02d%02d", month, year % 100)
    }

    /// Creates a `CardExpiryDate` struct from a 4 digit string in `MMyy` format.
    init?(_ string: String?) {
        guard
            let string = string,
            string.count == 4,
            let month = Int(string.prefix(2)),
            let year = Int(string.suffix(2)),
            (1...12).contains(month),
            (0...99).contains(year)
        else {
            return nil
        }

        self.init(month: month, year: year)
    }

    /// Creates a new `CardExpiryDate`
    ///
    /// If a two-digit `year` is provided it will be normalized to four digits.
    ///
    /// - Parameters:
    ///   - month: Month.
    ///   - year: Year.
    init(month: Int, year: Int) {
        self.month = month
        self.year = Self.normalizeYear(year)
    }

    func expired(now: Date = .init()) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // Copied from Android SDK
        let twoDigitCurrentYear = currentYear % 100
        let twoDigitYear = year % 100

        let isExpiredYear = (twoDigitYear - twoDigitCurrentYear) < 0
        let isYearTooLarge = (twoDigitYear - twoDigitCurrentYear) > 50

        return isExpiredYear || isYearTooLarge || (currentYear == year && currentMonth > month)
    }

    /// Normalizes a 2-digit year to 4 digits.
    /// - Note: 2-digit years are assumed to belong to the current century.
    static func normalizeYear(_ year: Int) -> Int {
        guard (0...99).contains(year) else {
            return year
        }

        let calendar = Calendar(identifier: .gregorian)
        return ((calendar.component(.year, from: .init()) / 100) * 100) + year
    }
}

extension CardExpiryDate: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.month == rhs.month &&
            lhs.year == rhs.year
        )
    }
}
