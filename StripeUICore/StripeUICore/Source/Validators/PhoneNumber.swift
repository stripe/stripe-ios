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
        return metadata.formattedNumber(number, format: format)
    }

    /// The country that matches this phone number, e.g. "US"
    public var countryCode: String {
        return metadata.regionCode
    }

    /// The phone number prefix for the country of this phone number, e.g. "+1"
    public var prefix: String {
        return metadata.prefix
    }

    /// Whether this represents a complete phone number
    public var isComplete: Bool {
        return string(as: .national).count >= metadata.pattern.count
    }

    /// Whether the phone number is empty (it may have a country code, but it has no other digits)
    public var isEmpty: Bool {
        return number.isEmpty
    }

    /// The phone number without the country prefix and containing only digits
    public let number: String
    private let metadata: Metadata

    public init?(number: String, countryCode: String?) {
        guard let countryCode = countryCode,
              let metadata = Metadata.metadata(for: countryCode) else {
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
        let candidates = Metadata.allMetadata.filter({ number.hasPrefix($0.prefix) })
        if candidates.count == 1 {
            return candidates.first.flatMap(makePhoneNumber)
        }

        // This second filter uses the device's locale to pick a winner out of N candidates.
        if let winner = candidates.first(where: { $0.regionCode == locale.stp_regionCode }) {
            return makePhoneNumber(winner)
        }

        // If no winner, we simply return the first candidate. Our metadata is sorted in a way that the
        // main country of a prefix is always first.
        return candidates.first.flatMap(makePhoneNumber)
    }

}

@_spi(STP) public extension PhoneNumber {
    struct Metadata: RegionCodeProvider {

        private static var metadataByCountryCodeCache: [String: Metadata] = [:]

        public static func metadata(for countryCode: String) -> Metadata? {
            if let cached = metadataByCountryCodeCache[countryCode] {
                return cached
            }
            if let metadata = allMetadata.first(where: { $0.regionCode == countryCode }) {
                metadataByCountryCodeCache[countryCode] = metadata
                return metadata
            }
            return nil
        }

        public let prefix: String
        public let regionCode: String
        internal let pattern: String

        public var sampleFilledPattern: String {
            let numDigitsInPattern = pattern.filter({ $0 == "#" }).count
            return formattedNumber(String(repeating: "5", count: numDigitsInPattern), format: .national)
        }

        func formattedNumber(_ number: String, format: Format) -> String {
            guard let formatter = TextFieldFormatter(format: pattern) else {
                return number
            }

            let allowedCharacterSet: CharacterSet = CharacterSet.stp_asciiDigit.union(CharacterSet(charactersIn: String(TextFieldFormatter.redactedNumberCharacter))) // allow '•' for redacted numbers

           let result = formatter.applyFormat(
                to: number.stp_stringByRemovingCharacters(from: allowedCharacterSet.inverted),
                shouldAppendRemaining: true
            )

            guard !result.isEmpty else {
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

        // Note: The patterns here are not complete in some cases, e.g.
        // JP where the first group of numbers will sometimes have 3 digits
        // for mobile but we only expect 2. In these cases the input should
        // allow for entry passed the pattern length
        public static let allMetadata: [Metadata] = [
            // NANP member countries and territories (Zone 1)
            // https://en.wikipedia.org/wiki/North_American_Numbering_Plan#Countries_and_territories
            Metadata(prefix: "+1", regionCode: "US", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "CA", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "AG", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "AS", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "AI", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "BB", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "BM", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "BS", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "DM", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "DO", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "GD", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "GU", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "JM", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "KN", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "KY", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "LC", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "MP", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "MS", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "PR", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "SX", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "TC", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "TT", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "VC", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "VG", pattern: "(###) ###-####"),
            Metadata(prefix: "+1", regionCode: "VI", pattern: "(###) ###-####"),
            // Rest of the world
            Metadata(prefix: "+20", regionCode: "EG", pattern: "### ### ####"),
            Metadata(prefix: "+211", regionCode: "SS", pattern: "### ### ###"),
            Metadata(prefix: "+212", regionCode: "MA", pattern: "###-######"),
            Metadata(prefix: "+212", regionCode: "EH", pattern: "###-######"),
            Metadata(prefix: "+213", regionCode: "DZ", pattern: "### ## ## ##"),
            Metadata(prefix: "+216", regionCode: "TN", pattern: "## ### ###"),
            Metadata(prefix: "+218", regionCode: "LY", pattern: "##-#######"),
            Metadata(prefix: "+220", regionCode: "GM", pattern: "### ####"),
            Metadata(prefix: "+221", regionCode: "SN", pattern: "## ### ## ##"),
            Metadata(prefix: "+222", regionCode: "MR", pattern: "## ## ## ##"),
            Metadata(prefix: "+223", regionCode: "ML", pattern: "## ## ## ##"),
            Metadata(prefix: "+224", regionCode: "GN", pattern: "### ## ## ##"),
            Metadata(prefix: "+225", regionCode: "CI", pattern: "## ## ## ##"),
            Metadata(prefix: "+226", regionCode: "BF", pattern: "## ## ## ##"),
            Metadata(prefix: "+227", regionCode: "NE", pattern: "## ## ## ##"),
            Metadata(prefix: "+228", regionCode: "TG", pattern: "## ## ## ##"),
            Metadata(prefix: "+229", regionCode: "BJ", pattern: "## ## ## ##"),
            Metadata(prefix: "+230", regionCode: "MU", pattern: "#### ####"),
            Metadata(prefix: "+231", regionCode: "LR", pattern: "### ### ###"),
            Metadata(prefix: "+232", regionCode: "SL", pattern: "## ######"),
            Metadata(prefix: "+233", regionCode: "GH", pattern: "## ### ####"),
            Metadata(prefix: "+234", regionCode: "NG", pattern: "### ### ####"),
            Metadata(prefix: "+235", regionCode: "TD", pattern: "## ## ## ##"),
            Metadata(prefix: "+236", regionCode: "CF", pattern: "## ## ## ##"),
            Metadata(prefix: "+237", regionCode: "CM", pattern: "## ## ## ##"),
            Metadata(prefix: "+238", regionCode: "CV", pattern: "### ## ##"),
            Metadata(prefix: "+239", regionCode: "ST", pattern: "### ####"),
            Metadata(prefix: "+240", regionCode: "GQ", pattern: "### ### ###"),
            Metadata(prefix: "+241", regionCode: "GA", pattern: "## ## ## ##"),
            Metadata(prefix: "+242", regionCode: "CG", pattern: "## ### ####"),
            Metadata(prefix: "+243", regionCode: "CD", pattern: "### ### ###"),
            Metadata(prefix: "+244", regionCode: "AO", pattern: "### ### ###"),
            Metadata(prefix: "+245", regionCode: "GW", pattern: "### ####"),
            Metadata(prefix: "+246", regionCode: "IO", pattern: "### ####"),
            Metadata(prefix: "+247", regionCode: "AC", pattern: ""),
            Metadata(prefix: "+248", regionCode: "SC", pattern: "# ### ###"),
            Metadata(prefix: "+250", regionCode: "RW", pattern: "### ### ###"),
            Metadata(prefix: "+251", regionCode: "ET", pattern: "## ### ####"),
            Metadata(prefix: "+252", regionCode: "SO", pattern: "## #######"),
            Metadata(prefix: "+253", regionCode: "DJ", pattern: "## ## ## ##"),
            Metadata(prefix: "+254", regionCode: "KE", pattern: "## #######"),
            Metadata(prefix: "+255", regionCode: "TZ", pattern: "### ### ###"),
            Metadata(prefix: "+256", regionCode: "UG", pattern: "### ######"),
            Metadata(prefix: "+257", regionCode: "BI", pattern: "## ## ## ##"),
            Metadata(prefix: "+258", regionCode: "MZ", pattern: "## ### ####"),
            Metadata(prefix: "+260", regionCode: "ZM", pattern: "## #######"),
            Metadata(prefix: "+261", regionCode: "MG", pattern: "## ## ### ##"),
            Metadata(prefix: "+262", regionCode: "RE", pattern: ""),
            Metadata(prefix: "+262", regionCode: "TF", pattern: ""),
            Metadata(prefix: "+262", regionCode: "YT", pattern: "### ## ## ##"),
            Metadata(prefix: "+263", regionCode: "ZW", pattern: "## ### ####"),
            Metadata(prefix: "+264", regionCode: "NA", pattern: "## ### ####"),
            Metadata(prefix: "+265", regionCode: "MW", pattern: "### ## ## ##"),
            Metadata(prefix: "+266", regionCode: "LS", pattern: "#### ####"),
            Metadata(prefix: "+267", regionCode: "BW", pattern: "## ### ###"),
            Metadata(prefix: "+268", regionCode: "SZ", pattern: "#### ####"),
            Metadata(prefix: "+269", regionCode: "KM", pattern: "### ## ##"),
            Metadata(prefix: "+27", regionCode: "ZA", pattern: "## ### ####"),
            Metadata(prefix: "+290", regionCode: "SH", pattern: ""),
            Metadata(prefix: "+290", regionCode: "TA", pattern: ""),
            Metadata(prefix: "+291", regionCode: "ER", pattern: "# ### ###"),
            Metadata(prefix: "+297", regionCode: "AW", pattern: "### ####"),
            Metadata(prefix: "+298", regionCode: "FO", pattern: "######"),
            Metadata(prefix: "+299", regionCode: "GL", pattern: "## ## ##"),
            Metadata(prefix: "+30", regionCode: "GR", pattern: "### ### ####"),
            Metadata(prefix: "+31", regionCode: "NL", pattern: "# ########"),
            Metadata(prefix: "+32", regionCode: "BE", pattern: "### ## ## ##"),
            Metadata(prefix: "+33", regionCode: "FR", pattern: "# ## ## ## ##"),
            Metadata(prefix: "+34", regionCode: "ES", pattern: "### ## ## ##"),
            Metadata(prefix: "+350", regionCode: "GI", pattern: "### #####"),
            Metadata(prefix: "+351", regionCode: "PT", pattern: "### ### ###"),
            Metadata(prefix: "+352", regionCode: "LU", pattern: "## ## ## ###"),
            Metadata(prefix: "+353", regionCode: "IE", pattern: "## ### ####"),
            Metadata(prefix: "+354", regionCode: "IS", pattern: "### ####"),
            Metadata(prefix: "+355", regionCode: "AL", pattern: "## ### ####"),
            Metadata(prefix: "+356", regionCode: "MT", pattern: "#### ####"),
            Metadata(prefix: "+357", regionCode: "CY", pattern: "## ######"),
            Metadata(prefix: "+358", regionCode: "FI", pattern: "## ### ## ##"),
            Metadata(prefix: "+358", regionCode: "AX", pattern: ""),
            Metadata(prefix: "+359", regionCode: "BG", pattern: "### ### ##"),
            Metadata(prefix: "+36", regionCode: "HU", pattern: "## ### ####"),
            Metadata(prefix: "+370", regionCode: "LT", pattern: "### #####"),
            Metadata(prefix: "+371", regionCode: "LV", pattern: "## ### ###"),
            Metadata(prefix: "+372", regionCode: "EE", pattern: "#### ####"),
            Metadata(prefix: "+373", regionCode: "MD", pattern: "### ## ###"),
            Metadata(prefix: "+374", regionCode: "AM", pattern: "## ######"),
            Metadata(prefix: "+375", regionCode: "BY", pattern: "## ###-##-##"),
            Metadata(prefix: "+376", regionCode: "AD", pattern: "### ###"),
            Metadata(prefix: "+377", regionCode: "MC", pattern: "# ## ## ## ##"),
            Metadata(prefix: "+378", regionCode: "SM", pattern: "## ## ## ##"),
            Metadata(prefix: "+379", regionCode: "VA", pattern: ""),
            Metadata(prefix: "+380", regionCode: "UA", pattern: "## ### ####"),
            Metadata(prefix: "+381", regionCode: "RS", pattern: "## #######"),
            Metadata(prefix: "+382", regionCode: "ME", pattern: "## ### ###"),
            Metadata(prefix: "+383", regionCode: "XK", pattern: "## ### ###"),
            Metadata(prefix: "+385", regionCode: "HR", pattern: "## ### ####"),
            Metadata(prefix: "+386", regionCode: "SI", pattern: "## ### ###"),
            Metadata(prefix: "+387", regionCode: "BA", pattern: "## ###-###"),
            Metadata(prefix: "+389", regionCode: "MK", pattern: "## ### ###"),
            Metadata(prefix: "+39", regionCode: "IT", pattern: "## #### ####"),
            Metadata(prefix: "+40", regionCode: "RO", pattern: "## ### ####"),
            Metadata(prefix: "+41", regionCode: "CH", pattern: "## ### ## ##"),
            Metadata(prefix: "+420", regionCode: "CZ", pattern: "### ### ###"),
            Metadata(prefix: "+421", regionCode: "SK", pattern: "### ### ###"),
            Metadata(prefix: "+423", regionCode: "LI", pattern: "### ### ###"),
            Metadata(prefix: "+43", regionCode: "AT", pattern: "### ######"),
            Metadata(prefix: "+44", regionCode: "GB", pattern: "#### ######"),
            Metadata(prefix: "+44", regionCode: "GG", pattern: "#### ######"),
            Metadata(prefix: "+44", regionCode: "JE", pattern: "#### ######"),
            Metadata(prefix: "+44", regionCode: "IM", pattern: "#### ######"),
            Metadata(prefix: "+45", regionCode: "DK", pattern: "## ## ## ##"),
            Metadata(prefix: "+46", regionCode: "SE", pattern: "##-### ## ##"),
            Metadata(prefix: "+47", regionCode: "NO", pattern: "### ## ###"),
            Metadata(prefix: "+47", regionCode: "BV", pattern: ""),
            Metadata(prefix: "+47", regionCode: "SJ", pattern: "## ## ## ##"),
            Metadata(prefix: "+48", regionCode: "PL", pattern: "## ### ## ##"),
            Metadata(prefix: "+49", regionCode: "DE", pattern: "### #######"),
            Metadata(prefix: "+500", regionCode: "FK", pattern: ""),
            Metadata(prefix: "+500", regionCode: "GS", pattern: ""),
            Metadata(prefix: "+501", regionCode: "BZ", pattern: "###-####"),
            Metadata(prefix: "+502", regionCode: "GT", pattern: "#### ####"),
            Metadata(prefix: "+503", regionCode: "SV", pattern: "#### ####"),
            Metadata(prefix: "+504", regionCode: "HN", pattern: "####-####"),
            Metadata(prefix: "+505", regionCode: "NI", pattern: "#### ####"),
            Metadata(prefix: "+506", regionCode: "CR", pattern: "#### ####"),
            Metadata(prefix: "+507", regionCode: "PA", pattern: "####-####"),
            Metadata(prefix: "+508", regionCode: "PM", pattern: "## ## ##"),
            Metadata(prefix: "+509", regionCode: "HT", pattern: "## ## ####"),
            Metadata(prefix: "+51", regionCode: "PE", pattern: "### ### ###"),
            Metadata(prefix: "+52", regionCode: "MX", pattern: "### ### ####"),
            Metadata(prefix: "+54", regionCode: "AR", pattern: "## ##-####-####"),
            Metadata(prefix: "+55", regionCode: "BR", pattern: "## #####-####"),
            Metadata(prefix: "+56", regionCode: "CL", pattern: "# #### ####"),
            Metadata(prefix: "+57", regionCode: "CO", pattern: "### #######"),
            Metadata(prefix: "+58", regionCode: "VE", pattern: "###-#######"),
            Metadata(prefix: "+590", regionCode: "BL", pattern: "### ## ## ##"),
            Metadata(prefix: "+590", regionCode: "MF", pattern: ""),
            Metadata(prefix: "+590", regionCode: "GP", pattern: "### ## ## ##"),
            Metadata(prefix: "+591", regionCode: "BO", pattern: "########"),
            Metadata(prefix: "+592", regionCode: "GY", pattern: "### ####"),
            Metadata(prefix: "+593", regionCode: "EC", pattern: "## ### ####"),
            Metadata(prefix: "+594", regionCode: "GF", pattern: "### ## ## ##"),
            Metadata(prefix: "+595", regionCode: "PY", pattern: "## #######"),
            Metadata(prefix: "+596", regionCode: "MQ", pattern: "### ## ## ##"),
            Metadata(prefix: "+597", regionCode: "SR", pattern: "###-####"),
            Metadata(prefix: "+598", regionCode: "UY", pattern: "#### ####"),
            Metadata(prefix: "+599", regionCode: "CW", pattern: "# ### ####"),
            Metadata(prefix: "+599", regionCode: "BQ", pattern: "### ####"),
            Metadata(prefix: "+60", regionCode: "MY", pattern: "##-### ####"),
            Metadata(prefix: "+61", regionCode: "AU", pattern: "### ### ###"),
            Metadata(prefix: "+62", regionCode: "ID", pattern: "###-###-###"),
            Metadata(prefix: "+63", regionCode: "PH", pattern: "#### ######"),
            Metadata(prefix: "+64", regionCode: "NZ", pattern: "## ### ####"),
            Metadata(prefix: "+65", regionCode: "SG", pattern: "#### ####"),
            Metadata(prefix: "+66", regionCode: "TH", pattern: "## ### ####"),
            Metadata(prefix: "+670", regionCode: "TL", pattern: "#### ####"),
            Metadata(prefix: "+672", regionCode: "AQ", pattern: "## ####"),
            Metadata(prefix: "+673", regionCode: "BN", pattern: "### ####"),
            Metadata(prefix: "+674", regionCode: "NR", pattern: "### ####"),
            Metadata(prefix: "+675", regionCode: "PG", pattern: "### ####"),
            Metadata(prefix: "+676", regionCode: "TO", pattern: "### ####"),
            Metadata(prefix: "+677", regionCode: "SB", pattern: "### ####"),
            Metadata(prefix: "+678", regionCode: "VU", pattern: "### ####"),
            Metadata(prefix: "+679", regionCode: "FJ", pattern: "### ####"),
            Metadata(prefix: "+681", regionCode: "WF", pattern: "## ## ##"),
            Metadata(prefix: "+682", regionCode: "CK", pattern: "## ###"),
            Metadata(prefix: "+683", regionCode: "NU", pattern: ""),
            Metadata(prefix: "+685", regionCode: "WS", pattern: ""),
            Metadata(prefix: "+686", regionCode: "KI", pattern: ""),
            Metadata(prefix: "+687", regionCode: "NC", pattern: "########"),
            Metadata(prefix: "+688", regionCode: "TV", pattern: ""),
            Metadata(prefix: "+689", regionCode: "PF", pattern: "## ## ##"),
            Metadata(prefix: "+690", regionCode: "TK", pattern: ""),
            Metadata(prefix: "+7", regionCode: "RU", pattern: "### ###-##-##"),
            Metadata(prefix: "+7", regionCode: "KZ", pattern: ""),
            Metadata(prefix: "+81", regionCode: "JP", pattern: "##-####-####"),
            Metadata(prefix: "+82", regionCode: "KR", pattern: "##-####-####"),
            Metadata(prefix: "+84", regionCode: "VN", pattern: "## ### ## ##"),
            Metadata(prefix: "+852", regionCode: "HK", pattern: "#### ####"),
            Metadata(prefix: "+853", regionCode: "MO", pattern: "#### ####"),
            Metadata(prefix: "+855", regionCode: "KH", pattern: "## ### ###"),
            Metadata(prefix: "+856", regionCode: "LA", pattern: "## ## ### ###"),
            Metadata(prefix: "+86", regionCode: "CN", pattern: "### #### ####"),
            Metadata(prefix: "+872", regionCode: "PN", pattern: ""),
            Metadata(prefix: "+880", regionCode: "BD", pattern: "####-######"),
            Metadata(prefix: "+886", regionCode: "TW", pattern: "### ### ###"),
            Metadata(prefix: "+90", regionCode: "TR", pattern: "### ### ####"),
            Metadata(prefix: "+91", regionCode: "IN", pattern: "## ## ######"),
            Metadata(prefix: "+92", regionCode: "PK", pattern: "### #######"),
            Metadata(prefix: "+93", regionCode: "AF", pattern: "## ### ####"),
            Metadata(prefix: "+94", regionCode: "LK", pattern: "## # ######"),
            Metadata(prefix: "+95", regionCode: "MM", pattern: "# ### ####"),
            Metadata(prefix: "+960", regionCode: "MV", pattern: "###-####"),
            Metadata(prefix: "+961", regionCode: "LB", pattern: "## ### ###"),
            Metadata(prefix: "+962", regionCode: "JO", pattern: "# #### ####"),
            Metadata(prefix: "+964", regionCode: "IQ", pattern: "### ### ####"),
            Metadata(prefix: "+965", regionCode: "KW", pattern: "### #####"),
            Metadata(prefix: "+966", regionCode: "SA", pattern: "## ### ####"),
            Metadata(prefix: "+967", regionCode: "YE", pattern: "### ### ###"),
            Metadata(prefix: "+968", regionCode: "OM", pattern: "#### ####"),
            Metadata(prefix: "+970", regionCode: "PS", pattern: "### ### ###"),
            Metadata(prefix: "+971", regionCode: "AE", pattern: "## ### ####"),
            Metadata(prefix: "+972", regionCode: "IL", pattern: "##-###-####"),
            Metadata(prefix: "+973", regionCode: "BH", pattern: "#### ####"),
            Metadata(prefix: "+974", regionCode: "QA", pattern: "#### ####"),
            Metadata(prefix: "+975", regionCode: "BT", pattern: "## ## ## ##"),
            Metadata(prefix: "+976", regionCode: "MN", pattern: "#### ####"),
            Metadata(prefix: "+977", regionCode: "NP", pattern: "###-#######"),
            Metadata(prefix: "+992", regionCode: "TJ", pattern: "### ## ####"),
            Metadata(prefix: "+993", regionCode: "TM", pattern: "## ##-##-##"),
            Metadata(prefix: "+994", regionCode: "AZ", pattern: "## ### ## ##"),
            Metadata(prefix: "+995", regionCode: "GE", pattern: "### ## ## ##"),
            Metadata(prefix: "+996", regionCode: "KG", pattern: "### ### ###"),
            Metadata(prefix: "+998", regionCode: "UZ", pattern: "## ### ## ##"),
        ]
    }
}

// MARK: - Equatable

extension PhoneNumber: Equatable {
    public static func == (lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        return lhs.string(as: .e164) == rhs.string(as: .e164)
    }
}
