//
//  BSBNumber.swift
//  StripeUICore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore

@_spi(STP) public struct BSBNumber {
    private let number: String
    private let pattern: String
    public init(number: String) {
        self.number = number
        self.pattern = "###-###"
    }

    public var isComplete: Bool {
        return formattedNumber().count >= pattern.count
    }

    public func formattedNumber() -> String {
        guard let formatter = TextFieldFormatter(format: pattern) else {
            return number
        }
        let allowedCharacterSet = CharacterSet.stp_asciiDigit

        let result = formatter.applyFormat(
            to: number.stp_stringByRemovingCharacters(from: allowedCharacterSet.inverted),
            shouldAppendRemaining: true
        )
        guard !result.isEmpty else {
            return ""
        }
        return result
    }

    public func bsbNumberText() -> String {
        return number.filter { $0 != "-" }
    }
}
