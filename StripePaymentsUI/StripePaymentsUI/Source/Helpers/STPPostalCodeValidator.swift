//
//  STPPostalCodeValidator.swift
//  StripePaymentsUI
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@objc enum STPPostalCodeIntendedUsage: Int {
    case billingAddress
    case shippingAddress
    case cardField
}

@objc @_spi(STP) public enum STPPostalCodeRequirement: Int {
    case standard
    case upe
}

@_spi(STP) public class STPPostalCodeValidator: NSObject {
    @_spi(STP) public class func postalCodeIsRequired(forCountryCode countryCode: String?) -> Bool {
        if countryCode == nil {
            return true
        } else {
            return
                !(self.countriesWithNoPostalCodes()?.contains(countryCode?.uppercased() ?? "")
                ?? false)
        }
    }

    class func postalCodeIsRequiredForUPE(forCountryCode countryCode: String?) -> Bool {
        guard let countryCode = countryCode else { return false }
        return self.countriesWithPostalRequiredForUPE().contains(countryCode.uppercased())
    }

    class func postalCodeIsRequired(
        forCountryCode countryCode: String?,
        with postalRequirement: STPPostalCodeRequirement
    ) -> Bool {
        switch postalRequirement {
        case .standard:
            return postalCodeIsRequired(forCountryCode: countryCode)
        case .upe:
            return postalCodeIsRequiredForUPE(forCountryCode: countryCode)
        }
    }

    @_spi(STP) public class func validationState(
        forPostalCode postalCode: String?,
        countryCode: String?,
        with postalRequirement: STPPostalCodeRequirement = .standard
    ) -> STPCardValidationState {
        let sanitizedCountryCode = countryCode?.uppercased()
        if self.postalCodeIsRequired(forCountryCode: countryCode, with: postalRequirement) {
            if sanitizedCountryCode == STPCountryCodeUnitedStates {
                return self.validationState(forUSPostalCode: postalCode)
            } else {
                if (postalCode?.count ?? 0) > 0 {
                    return .valid
                } else {
                    return .incomplete
                }
            }
        } else {
            return .valid
        }
    }

    @objc(formattedSanitizedPostalCodeFromString:countryCode:usage:)
    class func formattedSanitizedPostalCode(
        from postalCode: String?,
        countryCode: String?,
        usage: STPPostalCodeIntendedUsage
    ) -> String? {
        let sanitizedCountryCode = countryCode?.uppercased()
        if usage != .cardField && (sanitizedCountryCode == STPCountryCodeUnitedStates) {
            return self.formattedSanitizedUSZipCode(
                from: postalCode,
                usage: usage
            )
        } else {
            return self.formattedSanitizedPostalCode(from: postalCode)
        }

    }

    class func countOfCharactersFromSetInString(_ string: String, _ cs: CharacterSet) -> Int {
        var range = (string as NSString).rangeOfCharacter(from: cs)
        var count = 0
        if range.location != NSNotFound {
            var lastPosition = NSMaxRange(range)
            count += range.length
            while lastPosition < string.count {
                range = (string as NSString).rangeOfCharacter(
                    from: cs,
                    options: [],
                    range: NSRange(location: lastPosition, length: string.count - lastPosition)
                )
                if range.location == NSNotFound {
                    break
                } else {
                    count += range.length
                    lastPosition = NSMaxRange(range)
                }
            }
        }

        return count
    }

    class func validationState(forUSPostalCode postalCode: String?) -> STPCardValidationState {
        let firstFive = postalCode?.stp_safeSubstring(to: 5)
        let firstFiveLength = firstFive?.count ?? 0
        let totalLength = postalCode?.count ?? 0

        let firstFiveIsNumeric = STPCardValidator.stringIsNumeric(firstFive ?? "")
        if !firstFiveIsNumeric {
            // Non-numbers included in first five characters
            return .invalid
        } else if firstFiveLength < 5 {
            // Incomplete ZIP with only numbers
            return .incomplete
        } else if totalLength == 5 {
            // Valid 5 digit zip
            return .valid
        } else {
            // ZIP+4 territory
            let numberOfDigits = countOfCharactersFromSetInString(
                postalCode ?? "",
                CharacterSet.stp_asciiDigit
            )

            if numberOfDigits > 9 {
                // Too many digits
                return .invalid
            } else if numberOfDigits == totalLength {
                // All numeric postal code entered
                if numberOfDigits == 9 {
                    return .valid
                } else {
                    return .incomplete
                }
            } else if (numberOfDigits + 1) == totalLength {
                // Possibly has a separator character for ZIP+4, check to see if
                // its in the right place

                let separatorCharacter = (postalCode as NSString?)?.substring(
                    with: NSRange(location: 5, length: 1)
                )
                if countOfCharactersFromSetInString(
                    separatorCharacter ?? "",
                    CharacterSet.stp_asciiDigit
                )
                    == 0
                {
                    // Non-digit is in right position to be separator
                    if numberOfDigits == 9 {
                        return .valid
                    } else {
                        return .incomplete
                    }
                } else {
                    // Non-digit is in wrong position to be separator
                    return .invalid
                }
            } else {
                // Not a valid zip code (too many non-numeric characters)
                return .invalid
            }
        }
    }

    class func formattedSanitizedPostalCode(from zipCode: String?) -> String? {
        let formattedString = STPCardValidator.sanitizedPostalString(for: zipCode ?? "")
        return formattedString.uppercased()
    }

    class func formattedSanitizedUSZipCode(
        from zipCode: String?,
        usage: STPPostalCodeIntendedUsage
    ) -> String? {
        guard let zipCode = zipCode else {
            return nil
        }
        var maxLength = 0
        switch usage {
        case .billingAddress, .cardField:
            maxLength = 5
        case .shippingAddress:
            maxLength = 9
        }

        var formattedString = STPCardValidator.sanitizedNumericString(for: zipCode)
            .stp_safeSubstring(
                to: maxLength
            )

        //     If the string is >5 numbers or == 5 and the last char of the unformatted
        //     string was already a hyphen, insert a hyphen at position 6 for ZIP+4
        if formattedString.count > 5
            || formattedString.count == 5
                && (zipCode as NSString).substring(from: zipCode.count - 1) == "-"
        {
            formattedString.insert(
                contentsOf: "-",
                at: formattedString.index(formattedString.startIndex, offsetBy: 5)
            )
        }

        return formattedString
    }

    class func countriesWithPostalRequiredForUPE() -> [AnyHashable] {
        return ["CA", "GB", "US"]
    }

    class func countriesWithNoPostalCodes() -> [AnyHashable]? {
        return [
            "AE",
            "AG",
            "AN",
            "AO",
            "AW",
            "BF",
            "BI",
            "BJ",
            "BO",
            "BS",
            "BW",
            "BZ",
            "CD",
            "CF",
            "CG",
            "CI",
            "CK",
            "CM",
            "DJ",
            "DM",
            "ER",
            "FJ",
            "GD",
            "GH",
            "GM",
            "GN",
            "GQ",
            "GY",
            "HK",
            "IE",
            "JM",
            "JP",
            "KE",
            "KI",
            "KM",
            "KN",
            "KP",
            "LC",
            "ML",
            "MO",
            "MR",
            "MS",
            "MU",
            "MW",
            "NR",
            "NU",
            "PA",
            "QA",
            "RW",
            "SB",
            "SC",
            "SL",
            "SO",
            "SR",
            "ST",
            "SY",
            "TF",
            "TK",
            "TL",
            "TO",
            "TT",
            "TV",
            "TZ",
            "UG",
            "VU",
            "YE",
            "ZA",
            "ZW",
        ]
    }
}

private let STPCountryCodeUnitedStates = "US"
