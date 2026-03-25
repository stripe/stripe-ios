//
//  KeyedEncodingContainer+Extensions.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-10-29.
//

import Foundation

@_spi(STP) public extension KeyedEncodingContainer {
    mutating func encodeIfNotEmpty(_ value: String?, forKey key: K) throws {
        guard let value, !value.isEmpty else { return }
        try encode(value, forKey: key)
    }
}
