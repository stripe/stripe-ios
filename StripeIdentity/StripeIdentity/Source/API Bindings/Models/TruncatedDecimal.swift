//
//  TruncatedDecimal.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/9/22.
//

import Foundation

/**
 Truncates the decimal number to a specific number of decimal places when
 encoding it.
 */
protocol TruncatedDecimal: Codable, Equatable {
    /// The value type this decimal is wrapping (e.g. Float, Double, CGFloat)
    associatedtype ValueType: (FloatingPoint & CVarArg & Codable & LosslessStringConvertible)

    /// The number of decimal digits that should be encoded
    static var numberOfDecimalDigits: UInt { get }

    /// The wrapped value
    var value: ValueType { get }

    init(_ value: ValueType)
}

// MARK: - Codable

extension TruncatedDecimal {
    init(from decoder: Decoder) throws {
        self.init(try ValueType(from: decoder))
    }

    func encode(to encoder: Encoder) throws {
        // Because STPAPIClient always encodes as form data, we can use a
        // string-encoding to format the number to the correct decimal places
        let string = String(format: "%.\(Self.numberOfDecimalDigits)f", value)
        try string.encode(to: encoder)
    }
}

// MARK: - TwoDecimalFloat
/// Truncates a float to 2 decimal places when encoding it
struct TwoDecimalFloat: TruncatedDecimal {
    static let numberOfDecimalDigits: UInt = 2

    let value: Float

    init(_ value: Float) {
        self.value = value
    }
}
