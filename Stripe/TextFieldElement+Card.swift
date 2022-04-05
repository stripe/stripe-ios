//
//  TextFieldElement+Card.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

// MARK: - PAN Configuration
extension TextFieldElement {
    struct PANConfiguration: TextFieldElementConfiguration {
        var label: String = String.Localized.card_number
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        func keyboardProperties(for text: String) -> KeyboardProperties {
            return .init(type: .asciiCapableNumberPad, textContentType: .creditCardNumber, autocapitalization: .none)
        }
        
        func maxLength(for text: String) -> Int {
            if STPBINRange.hasBINRanges(forPrefix: text) {
                return Int(STPBINRange.mostSpecificBINRange(forNumber: text).length)
            } else {
                return STPBINRange.maxCardNumberLength()
            }
        }
        
        enum Error: TextFieldValidationError {
            case empty
            case incomplete
            case invalidBrand
            case invalidLuhn
            
            func shouldDisplay(isUserEditing: Bool) -> Bool {
                switch self {
                case .empty:
                    return false
                case .incomplete:
                    return !isUserEditing
                case .invalidBrand:
                    return true
                case .invalidLuhn:
                    // Note: text that fails a Luhn check but is shorter than the correct PAN length is considered incomplete, not invalid.
                    return !isUserEditing
                }
            }
            
            var localizedDescription: String {
                switch self {
                case .empty:
                    return ""
                case .incomplete:
                    return String.Localized.your_card_number_is_incomplete
                case .invalidBrand, .invalidLuhn:
                    return String.Localized.your_card_number_is_invalid
                }
            }
        }
        
        func validate(text: String, isOptional: Bool) -> ValidationState {
            // Is it empty?
            if text.isEmpty {
                return .invalid(Error.empty)
            }
            
            // Is the card brand valid?
            // We assume our hardcoded mapping of BIN to brand is correct, so if we don't know the brand, the number must be invalid.
            let binRange = STPBINRange.mostSpecificBINRange(forNumber: text)
            if binRange.brand == .unknown {
                return .invalid(Error.invalidBrand)
            }
            
            // Is the PAN the correct length?
            // First, get the minimum valid length
            let minimumValidLength: Int = {
                let isCorrectPANLengthKnownYet = STPBINRange.hasBINRanges(forPrefix: text)
                if !isCorrectPANLengthKnownYet {
                    // If `hasBINRanges` returns false, we need to call `retrieveBINRanges` to fetch the correct card length from the card metadata service. See go/card-metadata-edge.
                    STPBINRange.retrieveBINRanges(forPrefix: text) { _, _ in }
                    // If we don't know the correct length, return the shortest possible length for the brand
                    return STPBINRange.minCardNumberLength(for: binRange.brand)
                } else {
                    return Int(binRange.length)
                }
            }()
            if text.count < minimumValidLength {
                return .invalid(Error.incomplete)
            }
            
            // Does it fail a luhn check?
            if !STPCardValidator.stringIsValidLuhn(text) {
                return .invalid(Error.invalidLuhn)
            }
            
            return .valid
        }
        
        func makeDisplayText(for text: String) -> NSAttributedString {
            // Add kerning in between groups of digits
            let indicesToKern = STPCardValidator.cardNumberFormat(forCardNumber: text)
                .map { $0.intValue }
                // Transform e.g., [4, 4, 4, 4] into [4, 8, 12, 16]
                .reduce([]) { indicesToKern, length in
                    indicesToKern + [(indicesToKern.last ?? 0) + length]
                }
            let attributed = NSMutableAttributedString(string: text)
            for index in indicesToKern {
                if index < text.count {
                    attributed.addAttribute(.kern, value: 5, range: NSRange(location: index - 1, length: 1))
                }
            }
            return attributed
        }
    }
}

// MARK: - CVC Configuration
extension TextFieldElement {
    struct CVCConfiguration: TextFieldElementConfiguration {
        let cardBrandProvider: () -> (STPCardBrand)
        var label: String {
            if cardBrandProvider() == .amex {
                return String.Localized.cvv
            } else {
                return String.Localized.cvc
            }
        }
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        func keyboardProperties(for text: String) -> KeyboardProperties {
            return .init(type: .asciiCapableNumberPad, textContentType: nil, autocapitalization: .none)
        }
        func maxLength(for text: String) -> Int {
            return Int(STPCardValidator.maxCVCLength(for: cardBrandProvider()))
        }
        func validate(text: String, isOptional: Bool) -> ValidationState {
            if text.isEmpty {
                return isOptional ? .valid : .invalid(TextFieldElement.Error.empty)
            }
            
            if text.count < STPCardValidator.minCVCLength() {
                return .invalid(TextFieldElement.Error.incomplete(localizedDescription: String.Localized.your_cards_security_code_is_incomplete))
            }
            
            return .valid
        }
    }
}

// MARK: - Expiry Date Configuration
extension TextFieldElement {
    // TODO: Pre-fill billing details
    struct ExpiryDateConfiguration: TextFieldElementConfiguration {
        let label: String = String.Localized.mm_yy
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        func keyboardProperties(for text: String) -> KeyboardProperties {
            return .init(type: .asciiCapableNumberPad, textContentType: nil, autocapitalization: .none)
        }
        func maxLength(for text: String) -> Int {
            return 4
        }
        
        enum Error: TextFieldValidationError {
            case empty
            case incomplete
            case invalidMonth
            case invalid
            
            public func shouldDisplay(isUserEditing: Bool) -> Bool {
                switch self {
                case .empty:                    return false
                case .incomplete:               return !isUserEditing
                case .invalidMonth, .invalid:   return true
                }
            }
            
            public var localizedDescription: String {
                switch self {
                case .empty:
                    return ""
                case .incomplete:
                    return String.Localized.your_cards_expiration_date_is_incomplete
                case .invalidMonth:
                    return String.Localized.your_cards_expiration_month_is_invalid
                case .invalid:
                    return String.Localized.your_cards_expiration_date_is_invalid
                }
            }
        }
        
        func validate(text: String, isOptional: Bool) -> ValidationState {
            // Validate the month here so we can reuse the result later
            let validMonths = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
            let textHasValidMonth = validMonths.contains { text.hasPrefix($0) }
            
            switch text.count {
            case 0:
                return isOptional ? .valid : .invalid(TextFieldElement.Error.empty)
            case 1:
                // Is this the start of a valid date?
                return ["0", "1"].contains(text) ? .invalid(Error.incomplete) : .invalid(Error.invalidMonth)
            case 2, 3:
                return textHasValidMonth ? .invalid(Error.incomplete) : .invalid(Error.invalidMonth)
            case 4:
                guard textHasValidMonth else {
                    return .invalid(Error.invalidMonth)
                }
                // Is the date expired?
                let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MMYY"
                guard let date = dateFormatter.date(from: text), date >= Date() else {
                    return .invalid(Error.invalid)
                }
                return .valid
            default:
                return .invalid(Error.invalid)
            }
        }
        func makeDisplayText(for text: String) -> NSAttributedString {
            var text = text
            // A MM/YY starting with 2-9 must be a single digit month; prepend a 0
            if let firstDigit = text.first?.wholeNumberValue, (2...9).contains(firstDigit) {
                text = "0" + text
            }
            
            // Insert a "/" after two digits
            if text.count > 2 {
                text.insert("/", at: text.index(text.startIndex, offsetBy: 2))
            }
            return NSAttributedString(string: text)
        }
    }
}
