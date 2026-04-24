//
//  ParsedEnum.swift
//  StripeCore
//
//  Created by Jeremy Kelleher on 3/24/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A wrapper that pairs a parsed enum value with the raw API string.
///
/// Known values: `value` is non-nil, `rawValue` matches the enum's raw value.
/// Unknown values: `value` is nil, `rawValue` contains the unrecognized API string.
/// :nodoc:
@_spi(STP) public struct ParsedEnum<E: SafeParsedEnumCodable>: Hashable {
    /// The parsed enum value, or nil if the API string was unrecognized.
    public let value: E?
    /// The raw API string, always preserved.
    public let rawValue: String

    /// Initialize from a known enum value.
    public init(_ value: E) {
        self.value = value
        self.rawValue = value.rawValue
    }

    /// Initialize from a raw API string, attempting to parse the enum.
    public init(rawValue: String) {
        self.rawValue = rawValue
        self.value = E(rawValue: rawValue)
    }

    /// True if the value was not recognized by the SDK.
    public var isUnparsed: Bool { value == nil }

    // MARK: - Hashable / Equatable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: - Codable

extension ParsedEnum: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(rawValue: raw)
    }
}

extension ParsedEnum: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ParsedEnum {
    public static func == (lhs: Self, rhs: E) -> Bool {
        lhs.value == rhs
    }
}

extension Set {
    @_spi(STP) public func contains<E: SafeParsedEnumCodable>(_ enumValue: E) -> Bool
        where Element == ParsedEnum<E>
    {
        contains(ParsedEnum(enumValue))
    }

    @_spi(STP) @discardableResult
    public mutating func insert<E: SafeParsedEnumCodable>(_ enumValue: E) -> (inserted: Bool, memberAfterInsert: ParsedEnum<E>)
        where Element == ParsedEnum<E>
    {
        insert(ParsedEnum(enumValue))
    }
}
