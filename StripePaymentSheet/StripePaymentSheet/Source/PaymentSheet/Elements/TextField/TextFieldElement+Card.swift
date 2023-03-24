//
//  TextFieldElement+Card.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

// MARK: - PAN Configuration
extension TextFieldElement {
    struct PANConfiguration: TextFieldElementConfiguration {
        var label: String = String.Localized.card_number
        var binController = STPBINController.shared
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        let rotatingCardBrandsView = RotatingCardBrandsView()
        let defaultValue: String?

        init(defaultValue: String? = nil) {
            self.defaultValue = defaultValue
        }

        func accessoryView(for text: String, theme: ElementsUITheme) -> UIView? {
            let cardBrand = STPCardValidator.brand(forNumber: text)

            if cardBrand == .unknown {
                if case .invalid(Error.invalidBrand) = validate(text: text, isOptional: false) {
                    return DynamicImageView(
                        lightImage: STPImageLibrary.safeImageNamed(
                            "card_unknown_updated_icon",
                            darkMode: true
                        ),
                        darkImage: STPImageLibrary.safeImageNamed(
                            "card_unknown_updated_icon",
                            darkMode: false
                        ),
                        pairedColor: theme.colors.textFieldText
                    )
                } else {
                    // display all available card brands
                    rotatingCardBrandsView.cardBrands =
                        RotatingCardBrandsView.orderedCardBrands(from: STPCardBrand.allCases)
                    return rotatingCardBrandsView
                }
            } else {
                rotatingCardBrandsView.cardBrands = [cardBrand]
                return rotatingCardBrandsView
            }
        }

        func keyboardProperties(for text: String) -> KeyboardProperties {
            return .init(type: .asciiCapableNumberPad, textContentType: .creditCardNumber, autocapitalization: .none)
        }

        func maxLength(for text: String) -> Int {
            if binController.hasBINRanges(forPrefix: text) {
                return Int(binController.mostSpecificBINRange(forNumber: text).panLength)
            } else {
                return binController.maxCardNumberLength()
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
                case .incomplete, .invalidLuhn:
                    return !isUserEditing
                case .invalidBrand:
                    return true
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
            let binRange = binController.mostSpecificBINRange(forNumber: text)
            if binRange.brand == .unknown {
                return .invalid(Error.invalidBrand)
            }

            // Is the PAN the correct length?
            // First, get the minimum valid length
            let minimumValidLength: Int = {
                let isCorrectPANLengthKnownYet = binController.hasBINRanges(forPrefix: text)
                if !isCorrectPANLengthKnownYet {
                    // If `hasBINRanges` returns false, we need to call `retrieveBINRanges` to fetch the correct card length from the card metadata service. See go/card-metadata-edge.
                    binController.retrieveBINRanges(forPrefix: text, recordErrorsAsSuccess: false) { _ in }
                    // If we don't know the correct length, return the shortest possible length for the brand
                    return binController.minCardNumberLength(for: binRange.brand)
                } else {
                    return Int(binRange.panLength)
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
            let kerningValue = 5
            // Add kerning in between groups of digits
            let indicesToKern = STPCardValidator.cardNumberFormat(forCardNumber: text)
                .map { $0.intValue }
                // Transform e.g., [4, 4, 4, 4] into [4, 8, 12, 16]
                .reduce([]) { indicesToKern, length in
                    indicesToKern + [(indicesToKern.last ?? 0) + length]
                }
            let attributed = NSMutableAttributedString(string: text)
            // Set the kerning to 0 - this avoids a strange bug where all characters have kerning
            attributed.addAttribute(.kern, value: 0, range: NSRange(location: 0, length: text.count))
            for index in indicesToKern {
                if index < text.count {
                    attributed.addAttribute(.kern, value: kerningValue, range: NSRange(location: index - 1, length: 1))
                }
            }
            return attributed
        }
    }
}

// MARK: - CVC Configuration
extension TextFieldElement {
    struct CVCConfiguration: TextFieldElementConfiguration {
        init(defaultValue: String? = nil, cardBrandProvider: @escaping () -> (STPCardBrand)) {
            self.defaultValue = defaultValue
            self.cardBrandProvider = cardBrandProvider
        }

        let defaultValue: String?
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
        func accessoryView(for text: String, theme: ElementsUITheme) -> UIView? {
            let logoName = cardBrandProvider() == .amex
                ? "card_cvc_amex_updated_icon"
                : "card_cvc_updated_icon"
            return DynamicImageView(
                lightImage: STPImageLibrary.safeImageNamed(
                    logoName,
                    darkMode: true
                ),
                darkImage: STPImageLibrary.safeImageNamed(
                    logoName,
                    darkMode: false
                ),
                pairedColor: theme.colors.textFieldText
            )
        }
    }
}

// MARK: - Expiry Date Configuration
extension TextFieldElement {
    struct ExpiryDateConfiguration: TextFieldElementConfiguration {
        init(defaultValue: String? = nil) {
            self.defaultValue = defaultValue
        }

        let label: String = String.Localized.mm_yy
        let accessibilityLabel: String = String.Localized.expiration_date_accessibility_label
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        let defaultValue: String?
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
                return .invalid(Error.incomplete)
            case 2, 3:
                return textHasValidMonth ? .invalid(Error.incomplete) : .invalid(Error.invalidMonth)
            case 4:
                guard textHasValidMonth else {
                    return .invalid(Error.invalidMonth)
                }
                // Is the date expired?
                guard let expiryDate = CardExpiryDate(text), !expiryDate.expired() else {
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
