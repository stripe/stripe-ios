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
    /// The number of decimal digits that should be encoded
    static var numberOfDecimalDigits: UInt { get }

    var decimal: Decimal { get }

    init(decimal: Decimal)
}

struct TruncatedDecimalEncodingError: Error { }

// MARK: - Codable

extension TruncatedDecimal {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(decimal: try container.decode(Decimal.self))
    }

    func encode(to encoder: Encoder) throws {
        var mutableDecimal = decimal
        var roundedDecimal = decimal
        NSDecimalRound(&roundedDecimal, &mutableDecimal, Int(Self.numberOfDecimalDigits), .plain)

        var container = encoder.singleValueContainer()
        try container.encode(roundedDecimal)
    }
}

// MARK: - TwoDigitDecimal

/// Truncates a float to 2 decimal places when encoding it
struct TwoDigitDecimal: TruncatedDecimal {
    static let numberOfDecimalDigits: UInt = 2
    let decimal: Decimal
}

extension TwoDigitDecimal {
    init(float: Float) {
        self.init(decimal: NSDecimalNumber(value: float) as Decimal)
    }
}
