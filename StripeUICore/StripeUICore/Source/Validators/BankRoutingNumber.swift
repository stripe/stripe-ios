//
//  BankRoutingNumber.swift
//  StripeUICore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore

@_spi(STP) public protocol BankRoutingNumber {
    var number: String { get }
    var pattern: String { get }
}

@_spi(STP) public extension BankRoutingNumber {
    var isComplete: Bool {
        return formattedNumber().count >= pattern.count
    }

    func formattedNumber() -> String {
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

    func bsbNumberText() -> String {
        return number.filter { $0 != "-" }
    }
}

@_spi(STP) public struct BSBNumber: BankRoutingNumber {
    public var number: String
    
    public init(number: String) {
        self.number = number
    }
    
    public let pattern: String = "###-###"
}

@_spi(STP) public struct SortCode: BankRoutingNumber {
    public var number: String
    
    public init(number: String) {
        self.number = number
    }
    
    public let pattern: String = "##-##-##"
}
