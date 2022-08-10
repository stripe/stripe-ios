//
//  PhoneNumber.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore

@_spi(STP) public struct PhoneNumber {
    typealias Metadata = PhoneMetadataProvider.Metadata

    public enum Format {
        /// Formatted according to e164 standard, e.g. +15555555555
        case e164
        /// Formatted for display as non-international number, e.g. (555) 555-555
        case national
        /// Formatted for display an an international number with country code, e.g. +1 (555) 555-5555
        case international
        
        static let e164FormatMaxDigits = 15
    }
    
    public func string(as format: Format) -> String {
        return formattedNumber(number, format: format)
    }

    /// The phone number without the country prefix and containing only digits
    public let number: String
    private let metadata: Metadata
    
    /// The country that matches this phone number, e.g. "US"
    public var countryCode: String {
        return metadata.region
    }
    
    /// The phone number prefix for the country of this phone number, e.g. "+1"
    public var prefix: String {
        return metadata.prefix
    }
    
    /// Whether this represents a complete phone number
    public var isComplete: Bool {
        return metadata.validLengths.contains(number.count)
    }
    
    public init?(number: String, countryCode: String?) {
        guard let countryCode = countryCode,
              let metadata = PhoneMetadataProvider.shared.metadata(for: countryCode) else {
            return nil
        }
              
        self.number = number
        self.metadata = metadata
    }

    init(number: String, metadata: Metadata) {
        self.number = number
        self.metadata = metadata
    }

    /// Parses phone numbers in (*globalized*) E.164 format.
    ///
    /// - Note: Our metadata lacks of national destination code (area code)  ranges, because of this we fallback to
    ///         the device's locale to disambiguate when a number can possibly belong to multiple regions.
    ///
    /// - Parameters:
    ///   - number: Phone number to parse.
    ///   - locale: User's locale.
    /// - Returns: `PhoneNumber`, or `nil` if the number is not parsable.
    public static func fromE164(_ number: String, locale: Locale = .current) -> PhoneNumber? {
        let characters: [Character] = .init(number)

        // Matching regex: ^\+[1-9]\d{2,14}$
        guard
            characters.count > 4,
            characters.count <= Format.e164FormatMaxDigits + 1,
            characters[0] == "+",
            characters[1] != "0",
            characters[1...].allSatisfy({
                $0.unicodeScalars.allSatisfy(CharacterSet.stp_asciiDigit.contains(_:))
            })
        else {
            return nil
        }

        let makePhoneNumber: (Metadata) -> PhoneNumber = { metadata in
            return PhoneNumber(
                number: String(characters[metadata.prefix.count...]),
                metadata: metadata
            )
        }

        // This filter should narrow down the metadata list to just 1 candidate in most cases,
        // as very few countries share country calling codes. Country calling codes are also
        // *Prefix codes*, which means that two codes will never overlap.
        let candidates = PhoneMetadataProvider.shared.allMetadata.filter({ number.hasPrefix($0.prefix) })
        if candidates.count == 1 {
            return candidates.first.flatMap(makePhoneNumber)
        }

        // This second filter uses the device's locale to pick a winner out of N candidates.
        if let winner = candidates.first(where: { $0.region == locale.regionCode }) {
            return makePhoneNumber(winner)
        }

        // If no winner, we simply return the first candidate. Our metadata is sorted in a way that the
        // main country of a prefix is always first.
        return candidates.first.flatMap(makePhoneNumber)
    }

}

private extension PhoneNumber {

    func formattedNumber(_ number: String, format: Format) -> String {
        let allowedCharacterSet: CharacterSet = .stp_asciiDigit

        let sanitized = number.stp_stringByRemovingCharacters(from: allowedCharacterSet.inverted)

        guard let pattern = metadata.bestFormat(for: sanitized),
              let formatter = TextFieldFormatter(format: pattern) else {
            return sanitized
        }

        let result = formatter.applyFormat(to: sanitized, shouldAppendRemaining: true)
        guard result.count > 0 else {
            return ""
        }

        switch format {
        case .e164:
            var resultDigits = result.stp_stringByRemovingCharacters(from: allowedCharacterSet.inverted)
            // e164 drops leading 0s
            if resultDigits.hasPrefix("0") {
                resultDigits = String(resultDigits.suffix(resultDigits.count - 1))
            }

            resultDigits = prefix.stp_stringByRemovingCharacters(from: allowedCharacterSet.inverted) + resultDigits
            // e164 doesn't accept more than 15 digits
            if resultDigits.count > Format.e164FormatMaxDigits {
                resultDigits = String(resultDigits.prefix(Format.e164FormatMaxDigits))
            }

            return "+" + resultDigits
        case .national:
            return result
        case .international:
            return prefix + " " + result
        }
    }

}

// MARK: - Equatable

extension PhoneNumber: Equatable {
    public static func == (lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        return lhs.number == rhs.number
    }
}
