//
//  STPCardValidator.swift
//  StripePayments
//
//  Created by Jack Flintermann on 7/15/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// These fields indicate whether a card field represents a valid value, invalid
/// value, or incomplete value.
@objc @frozen public enum STPCardValidationState: Int {
    /// The field's contents are valid. For example, a valid, 16-digit card number.
    /// Note that valid values may not be complete. For example: a US Zip code can
    /// be 5 or 9 digits. A 5-digit code is Valid, but more text could be entered
    /// to transition to incomplete again. American Express CVC codes can be 3 or
    /// 4 digits and both will be treated as Valid.
    case valid
    /// The field's contents are invalid. For example, an expiration date
    /// of "13/42".
    case invalid
    /// The field's contents are not currently valid, but could be by typing
    /// additional characters. For example, a CVC of "1".
    case incomplete
}

/// This class contains static methods to validate card numbers, expiration dates,
/// and CVCs. For a list of test card numbers to use with this code,
/// see https://stripe.com/docs/testing
@objc(STPCardValidator)
public class STPCardValidator: NSObject {
    /// Returns a copy of the passed string with all non-numeric characters removed.
    @objc(sanitizedNumericStringForString:)
    public class func sanitizedNumericString(
        for string: String
    )
        -> String
    {
        return stringByRemovingCharactersFromSet(string, CharacterSet.stp_invertedAsciiDigit)
    }

    /// Returns a copy of the passed string with all characters removed that do not exist within a postal code.
    @objc(sanitizedPostalStringForString:)
    public class func sanitizedPostalString(
        for string: String
    )
        -> String
    {
        let sanitizedString = stringByRemovingCharactersFromSet(
            string,
            CharacterSet.stp_invertedPostalCode
        )
        let sanitizedStringWithoutPunctuation = stringByRemovingCharactersFromSet(
            sanitizedString,
            CharacterSet(charactersIn: " -")
        )
        if sanitizedStringWithoutPunctuation == "" {
            // No postal codes begin with a space or -. If the user has only entered these characters, it was probably a typo.
            return ""
        }
        return sanitizedString
    }

    /// Whether or not the target string contains only numeric characters.
    @objc(stringIsNumeric:)
    public class func stringIsNumeric(_ string: String) -> Bool {
        return
            (string as NSString).rangeOfCharacter(from: CharacterSet.stp_invertedAsciiDigit)
            .location
            == NSNotFound
    }

    /// Validates a card number, passed as a string. This will return
    /// STPCardValidationStateInvalid for numbers that are too short or long, contain
    /// invalid characters, do not pass Luhn validation, or (optionally) do not match
    /// a number format issued by a major card brand.
    /// - Parameters:
    ///   - cardNumber: The card number to validate. Ex. @"4242424242424242"
    ///   - validatingCardBrand: Whether or not to enforce that the number appears to
    /// be issued by a major card brand (or could be). For example, no issuing card
    /// network currently issues card numbers beginning with the digit 9; if an
    /// otherwise correct-length and luhn-valid card number beginning with 9
    /// (example: 9999999999999995) were passed to this method, it would return
    /// STPCardValidationStateInvalid if this parameter were YES and
    /// STPCardValidationStateValid if this parameter were NO. If unsure, you should
    /// use YES for this value.
    /// - Returns: STPCardValidationStateValid if the number is valid,
    /// STPCardValidationStateInvalid if the number is invalid, or
    /// STPCardValidationStateIncomplete if the number is a substring of a valid
    /// card (e.g. @"4242").
    @objc(validationStateForNumber:validatingCardBrand:)
    public class func validationState(
        forNumber cardNumber: String?,
        validatingCardBrand: Bool
    ) -> STPCardValidationState {
        guard let cardNumber = cardNumber else {
            return .incomplete
        }
        let sanitizedNumber = self.stringByRemovingSpaces(from: cardNumber)
        if sanitizedNumber.count == 0 {
            return .incomplete
        }
        if !self.stringIsNumeric(sanitizedNumber) {
            return .invalid
        }
        let binRange = STPBINController.shared.mostSpecificBINRange(forNumber: sanitizedNumber)
        if binRange.brand == .unknown && validatingCardBrand {
            return .invalid
        }
        if sanitizedNumber.count == binRange.panLength {
            let isValidLuhn = self.stringIsValidLuhn(sanitizedNumber)
            if isValidLuhn {
                if binRange.isHardcoded
                    && STPBINController.shared.isVariableLengthBINPrefix(sanitizedNumber)
                {
                    // log that we didn't get a match in the metadata response so fell back to a hard coded response
                    STPAnalyticsClient.sharedClient.logCardMetadataMissingRange()
                }
                return .valid
            } else {
                return .invalid
            }
        } else if sanitizedNumber.count > binRange.panLength {
            return .invalid
        } else {
            return .incomplete
        }
    }

    /// The card brand for a card number or substring thereof.
    /// - Parameter cardNumber: A card number, or partial card number. For
    /// example, @"4242", @"5555555555554444", or @"123".
    /// - Returns: The brand for that card number. The example parameters would
    /// return STPCardBrandVisa, STPCardBrandMasterCard, and
    /// STPCardBrandUnknown, respectively.
    @objc(brandForNumber:)
    public class func brand(forNumber cardNumber: String) -> STPCardBrand {
        let sanitizedNumber = self.sanitizedNumericString(for: cardNumber)
        let brands = self.possibleBrands(forNumber: sanitizedNumber)
        if brands.count == 1 {
            return brands.first!
        }
        return .unknown
    }

    /// The possible number lengths for cards associated with a card brand. For
    /// example, Discover card numbers contain 16 characters, while American Express
    /// cards contain 15 characters.
    /// - Parameter brand: The brand to return lengths for.
    /// - Returns: The set of possible lengths cards associated with that brand can be.
    @objc(lengthsForCardBrand:)
    public class func lengths(for brand: STPCardBrand) -> Set<UInt> {
        var set: Set<UInt> = []
        let binRanges = STPBINController.shared.binRanges(for: brand)
        for binRange in binRanges {
            _ = set.insert(binRange.panLength)
        }
        return set
    }

    /// The maximum possible length the number of a card associated with the specified
    /// brand could be.
    /// For example, Visa cards could be either 13 or 16 characters, so this method
    /// would return 16 for the that card brand.
    /// - Parameter brand: The brand to return the max length for.
    /// - Returns: The maximum length card numbers associated with that brand could be.
    @objc(maxLengthForCardBrand:)
    public class func maxLength(for brand: STPCardBrand) -> Int {
        var maxLength = -1
        for length in self.lengths(for: brand) {
            if length > maxLength {
                maxLength = Int(length)
            }
        }
        return maxLength
    }

    /// The length of the final grouping of digits to use when formatting a card number
    /// for display.
    /// For example, Visa cards display their final 4 numbers, e.g. "4242", while
    /// American Express cards display their final 5 digits, e.g. "10005".
    /// - Parameter brand: The brand to return the fragment length for.
    /// - Returns: The final fragment length card numbers associated with that brand use.
    @objc(fragmentLengthForCardBrand:)
    public class func fragmentLength(for brand: STPCardBrand) -> Int {
        return Int(self.cardNumberFormat(for: brand).last?.uintValue ?? 0)
    }

    /// Validates an expiration month, passed as an (optionally 0-padded) string.
    /// Example valid values are "3", "12", and "08". Example invalid values are "99",
    /// "a", and "00". Incomplete values include "0" and "1".
    /// - Parameter expirationMonth: A string representing a 2-digit expiration month for a
    /// payment card.
    /// - Returns: STPCardValidationStateValid if the month is valid,
    /// STPCardValidationStateInvalid if the month is invalid, or
    /// STPCardValidationStateIncomplete if the month is a substring of a valid
    /// month (e.g. @"0" or @"1").
    @objc(validationStateForExpirationMonth:)
    public class func validationState(
        forExpirationMonth expirationMonth: String
    )
        -> STPCardValidationState
    {

        let sanitizedExpiration = self.stringByRemovingSpaces(from: expirationMonth)

        if !self.stringIsNumeric(sanitizedExpiration) {
            return .invalid
        }

        switch sanitizedExpiration.count {
        case 0:
            return .incomplete
        case 1:
            return ((sanitizedExpiration == "0") || (sanitizedExpiration == "1"))
                ? .incomplete : .valid
        case 2:
            return (0 < Int(sanitizedExpiration) ?? 0 && Int(sanitizedExpiration) ?? 0 <= 12)
                ? .valid : .invalid
        default:
            return .invalid
        }
    }

    /// Validates an expiration year, passed as a string representing the final
    /// 2 digits of the year.
    /// This considers the period between the current year until 2099 as valid times.
    /// An example valid year value would be "16" (assuming the current year, as
    /// determined by NSDate.date, is 2015).
    /// Will return STPCardValidationStateInvalid for a month/year combination that
    /// is earlier than the current date (i.e. @"15" and @"04" in October 2015).
    /// Example invalid year values are "00", "a", and "13". Any 1-digit year string
    /// will return STPCardValidationStateIncomplete.
    /// - Parameters:
    ///   - expirationYear: A string representing a 2-digit expiration year for a
    /// payment card.
    ///   - expirationMonth: A string representing a valid 2-digit expiration month
    /// for a payment card. If the month is invalid
    /// (see `validationStateForExpirationMonth`), this will
    /// return STPCardValidationStateInvalid.
    /// - Returns: STPCardValidationStateValid if the year is valid,
    /// STPCardValidationStateInvalid if the year is invalid, or
    /// STPCardValidationStateIncomplete if the year is a substring of a valid
    /// year (e.g. @"1" or @"2").
    @objc(validationStateForExpirationYear:inMonth:)
    public class func validationState(
        forExpirationYear expirationYear: String,
        inMonth expirationMonth: String
    ) -> STPCardValidationState {
        return self.validationState(
            forExpirationYear: expirationYear,
            inMonth: expirationMonth,
            inCurrentYear: self.currentYear(),
            currentMonth: self.currentMonth()
        )
    }

    /// The max CVC length for a card brand (for example, American Express CVCs are
    /// 4 digits, while all others are 3).
    /// - Parameter brand: The brand to return the max CVC length for.
    /// - Returns: The maximum length of CVC numbers for cards associated with that brand.
    @objc(maxCVCLengthForCardBrand:)
    public class func maxCVCLength(for brand: STPCardBrand) -> UInt {
        switch brand {
        case .amex, .unknown:
            return 4
        default:
            return 3
        }
    }

    /// Validates a card's CVC, passed as a numeric string, for the given card brand.
    /// - Parameters:
    ///   - cvc:   the CVC to validate
    ///   - brand: the card brand (can be determined from the card's number
    /// using `brandForNumber`)
    /// - Returns: Whether the CVC represents a valid CVC for that card brand. For
    /// example, would return STPCardValidationStateValid for @"123" and
    /// STPCardBrandVisa, STPCardValidationStateValid for @"1234" and
    /// STPCardBrandAmericanExpress, STPCardValidationStateIncomplete for @"12" and
    /// STPCardBrandVisa, and STPCardValidationStateInvalid for @"12345" and any brand.
    @objc(validationStateForCVC:cardBrand:)
    public class func validationState(
        forCVC cvc: String,
        cardBrand brand: STPCardBrand
    )
        -> STPCardValidationState
    {

        if !self.stringIsNumeric(cvc) {
            return .invalid
        }

        let sanitizedCvc = self.sanitizedNumericString(for: cvc)

        let minLength = self.minCVCLength()
        let maxLength = self.maxCVCLength(for: brand)
        if sanitizedCvc.count < minLength {
            return .incomplete
        } else if sanitizedCvc.count > maxLength {
            return .invalid
        } else {
            return .valid
        }
    }

    /// Validates the given card details.
    /// - Parameter card: The card details to validate.
    /// - Returns: STPCardValidationStateValid if all fields are valid,
    /// STPCardValidationStateInvalid if any field is invalid, or
    /// STPCardValidationStateIncomplete if all fields are either incomplete or valid.
    @objc(validationStateForCard:)
    public class func validationState(forCard card: STPCardParams) -> STPCardValidationState {
        return self.validationState(
            forCard: card,
            inCurrentYear: self.currentYear(),
            currentMonth: self.currentMonth()
        )
    }

    class func stringByRemovingSpaces(from string: String) -> String {
        let set = CharacterSet.whitespaces
        return stringByRemovingCharactersFromSet(string, set)
    }

    static func stringByRemovingCharactersFromSet(_ string: String, _ cs: CharacterSet) -> String {
        let filtered = string.unicodeScalars.filter { !cs.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    class func validationState(
        forExpirationYear expirationYear: String,
        inMonth expirationMonth: String,
        inCurrentYear currentYear: Int,
        currentMonth: Int
    ) -> STPCardValidationState {

        let moddedYear = currentYear % 100

        if !self.stringIsNumeric(expirationMonth) || !self.stringIsNumeric(expirationYear) {
            return .invalid
        }

        let sanitizedMonth = self.sanitizedNumericString(for: expirationMonth)
        let sanitizedYear = self.sanitizedNumericString(for: expirationYear)

        switch sanitizedYear.count {
        case 0, 1:
            return .incomplete
        case 2:
            guard let yearInt = Int(sanitizedYear), let monthInt = Int(sanitizedMonth), self.validationState(forExpirationMonth: sanitizedMonth) != .invalid else {
                return .invalid
            }
            if yearInt == moddedYear {
                return monthInt >= currentMonth ? .valid : .invalid
            } else {
                return ((yearInt > moddedYear) && (yearInt - moddedYear <= 50)) ? .valid : .invalid
            }
        default:
            return .invalid
        }
    }

    class func validationState(
        forCard card: STPCardParams,
        inCurrentYear currentYear: Int,
        currentMonth: Int
    ) -> STPCardValidationState {
        let numberValidation = self.validationState(
            forNumber: card.number ?? "",
            validatingCardBrand: true
        )
        let expMonthString = String(format: "%02lu", UInt(card.expMonth))
        let expMonthValidation = self.validationState(forExpirationMonth: expMonthString)
        let expYearString = String(format: "%02lu", UInt(card.expYear) % 100)
        let expYearValidation = self.validationState(
            forExpirationYear: expYearString,
            inMonth: expMonthString,
            inCurrentYear: currentYear,
            currentMonth: currentMonth
        )
        let brand = self.brand(forNumber: card.number ?? "")
        let cvcValidation = self.validationState(forCVC: card.cvc ?? "", cardBrand: brand)

        let states = [
            NSNumber(value: numberValidation.rawValue),
            NSNumber(value: expMonthValidation.rawValue),
            NSNumber(value: expYearValidation.rawValue),
            NSNumber(value: cvcValidation.rawValue),
        ]
        var incomplete = false
        for boxedState in states {
            let state = STPCardValidationState(rawValue: boxedState.intValue)
            if state == .invalid {
                return state!
            } else if state == .incomplete {
                incomplete = true
            }
        }
        return incomplete ? .incomplete : .valid
    }

    @_spi(STP) public class func minCVCLength() -> Int {
        return 3
    }

    class func possibleBrands(forNumber cardNumber: String) -> Set<STPCardBrand> {
        let binRanges = STPBINController.shared.binRanges(forNumber: cardNumber)
        var brands = binRanges.map { $0.brand }
        brands.removeAll { $0 == .unknown }
        return Set(brands)
    }

    // This is a bit of a hack: We want to fetch BIN information for Card Brand Choice, but some
    // of the BIN length information coming from the service is incorrect: We're receiving a maximum
    // length, but we really should receive a min-max range.
    // We don't want to pollute the main STPBINController cache with this bad data.
    //
    // We currently prevent cache pollution with an `isVariableLengthBINPrefix` check in
    // `retrieveBinRanges()`, but we'll bypass that check when using the CBC BIN controller.
    static let cbcBinController = STPBINController()

    /// Returns available brands for the provided card details.
    /// - Parameter card: The card details to validate.
    /// - Parameter completion: Will be called with the set of available STPCardBrands or an error.
    /// - seealso: https://stripe.com/docs/card-brand-choice
    public class func possibleBrands(forCard cardParams: STPPaymentMethodCardParams,
                                     completion: @escaping (Result<Set<STPCardBrand>, Error>) -> Void) {
        guard let cardNumber = cardParams.number else {
            // If the number is nil or empty, any brand is possible.
            completion(.success(Set(STPCardBrand.allCases)))
            return
        }
        possibleBrands(forNumber: cardNumber, completion: completion)
    }

    public class func possibleBrands(forNumber cardNumber: String,
                                     completion: @escaping (Result<Set<STPCardBrand>, Error>) -> Void) {
        // Hardcoded test cards that are in our docs but not supported by the card metadata service
        // https://stripe.com/docs/card-brand-choice#testing
        let testCards: [String: [STPCardBrand]] = ["4000002500001001": [.cartesBancaires, .visa],
                                                   "5555552500001001": [.cartesBancaires, .mastercard], ]

        if let testBrands = testCards[cardNumber] {
            completion(.success(Set<STPCardBrand>(testBrands)))
            return
        }

        cbcBinController.retrieveBINRanges(forPrefix: cardNumber, recordErrorsAsSuccess: false, onlyFetchForVariableLengthBINs: false) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                let binRanges = cbcBinController.binRanges(forNumber: cardNumber)
                let brands = binRanges.map { $0.brand }
                                      .filter { $0 != .unknown }
                completion(.success(Set(brands)))
            }
        }
    }

    class func currentYear() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return (calendar.component(.year, from: Date())) % 100
    }

    class func currentMonth() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.month, from: Date())
    }
}

extension STPCardValidator {
    class func cardNumberFormat(for brand: STPCardBrand) -> [NSNumber] {
        switch brand {
        case .amex:
            return [NSNumber(value: 4), NSNumber(value: 6), NSNumber(value: 5)]
        default:
            return [NSNumber(value: 4), NSNumber(value: 4), NSNumber(value: 4), NSNumber(value: 4)]
        }
    }

    @_spi(STP) public class func cardNumberFormat(forCardNumber cardNumber: String) -> [NSNumber] {
        let binRange = STPBINController.shared.mostSpecificBINRange(forNumber: cardNumber)
        if binRange.brand == .dinersClub && binRange.panLength == 14 {
            return [NSNumber(value: 4), NSNumber(value: 6), NSNumber(value: 4)]
        }

        return self.cardNumberFormat(for: binRange.brand)
    }

    @_spi(STP) public class func stringIsValidLuhn(_ number: String) -> Bool {
        var odd = true
        var sum = 0
        var digits: [String] = []

        for i in 0..<number.count {
            digits.append((number as NSString).substring(with: NSRange(location: i, length: 1)))
        }

        for digitStr in digits.reversed() {
            var digit = Int(digitStr) ?? 0
            odd = !odd
            if odd {
                digit *= 2
            }
            if digit > 9 {
                digit -= 9
            }
            sum += digit
        }

        return sum % 10 == 0
    }
    
    /// Returns the brand (eg VISA) for a card, respecting card brand choice.
    @_spi(STP) public class func brand(for card: STPPaymentMethodCardParams?) -> STPCardBrand {
        guard let card, let number = card.number else {
            return .unknown
        }
        // If there's a preferred card network, just use that
        if let networks = card.networks {
            return STPCard.brand(from: networks.preferred ?? "")
        }
        // Otherwise use the default card network for the card number
        return STPCardValidator.brand(forNumber: number)
    }
}
