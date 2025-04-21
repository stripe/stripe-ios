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
        let cardBrand: STPCardBrand?
        let cardBrandDropDown: DropdownFieldElement?
        let cardFilter: CardBrandFilter

        init(defaultValue: String? = nil, cardBrand: STPCardBrand? = nil, cardBrandDropDown: DropdownFieldElement? = nil, cardFilter: CardBrandFilter = .default) {
            self.defaultValue = defaultValue
            self.cardBrand = cardBrand
            self.cardBrandDropDown = cardBrandDropDown
            self.cardFilter = cardFilter
        }

        private func cardBrand(for text: String) -> STPCardBrand {
            // Try to read the brands from the CBC dropdown
            guard let cardBrandDropDown = cardBrandDropDown,
                  let firstBrandString = cardBrandDropDown.nonPlacerholderItems.first?.rawData else {
                return STPCardValidator.brand(forNumber: text)
            }

            let cardBrandFromDropDown = STPCard.brand(from: firstBrandString)
            let cardBrandFromBin = STPCardValidator.brand(forNumber: text)
            return cardBrandFromDropDown == .unknown ? cardBrandFromBin : cardBrandFromDropDown
        }

        func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
            // If CBC is enabled and the PAN is not empty...
            if let cardBrandDropDown = cardBrandDropDown, !text.isEmpty {
                // Show unknown card brand if we have under 9 pan digits and no card brands
                if 9 > text.count && cardBrandDropDown.nonPlacerholderItems.isEmpty {
                    return DynamicImageView.makeUnknownCardImageView(theme: theme)
                } else if text.count >= 8 && cardBrandDropDown.nonPlacerholderItems.count > 1 {
                    // Show the dropdown if we have 8 or more digits and at least 2 brands, otherwise fall through and show brand as normal
                    return cardBrandDropDown.view
                }
            }

            // If this is coming from the LastFourConfiguration, cardBrand(for: text) will retrieve a card brand from •••• •••• •••• last4, which may be incorrect, so we pass in the card brand for that case
            if let cardBrand = cardBrand,
               cardBrandDropDown == nil {
                rotatingCardBrandsView.cardBrands = [cardBrand]
                return rotatingCardBrandsView
            }

            let cardBrand = cardBrand(for: text)
            if cardBrand == .unknown {
                if case .invalid(Error.invalidBrand) = validate(text: text, isOptional: false) {
                    return DynamicImageView.makeUnknownCardImageView(theme: theme)
                } else {
                    // display all available card brands
                    rotatingCardBrandsView.cardBrands =
                    RotatingCardBrandsView.orderedCardBrands(from: STPCardBrand.allCases.filter { cardFilter.isAccepted(cardBrand: $0) })
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
            case disallowedBrand(brand: STPCardBrand)

            func shouldDisplay(isUserEditing: Bool) -> Bool {
                switch self {
                case .empty:
                    return false
                case .incomplete, .invalidLuhn:
                    return !isUserEditing
                case .invalidBrand, .disallowedBrand:
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
                case .disallowedBrand(let brand):
                    if let cardBrandDisplayName = STPCardBrandUtilities.stringFrom(brand), brand != .unknown {
                        return .localizedStringWithFormat(.Localized.brand_not_allowed, cardBrandDisplayName)
                    }

                    return .Localized.generic_brand_not_allowed
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

            let cardBrand = cardBrand(for: text)
            // If the merchant is CBC eligible, don't show the disallowed error until we have time to hit the card metadata service to determine brands (at 8 digits)
            let shouldShowDisallowedError = cardBrandDropDown == nil || text.count > 8
            if !cardFilter.isAccepted(cardBrand: cardBrand) && shouldShowDisallowedError {
                return .invalid(Error.disallowedBrand(brand: cardBrand))
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
        var label = String.Localized.cvc
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
        func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
            return DynamicImageView(
                dynamicImage: STPImageLibrary.cvcImage(for: cardBrandProvider()),
                pairedColor: theme.colors.componentBackground
            )
        }
    }
}

// MARK: - Censored CVC Configuration
extension TextFieldElement {
    struct CensoredCVCConfiguration: TextFieldElementConfiguration {
        init(brand: STPCardBrand) {
            let maxLength = Int(STPCardValidator.maxCVCLength(for: brand))
            self.defaultValue = String(repeating: "•", count: maxLength)
            self.brand = brand
        }

        let defaultValue: String?
        let brand: STPCardBrand
        var label = String.Localized.cvc
        let editConfiguration: EditConfiguration = .readOnly
        let disallowedCharacters: CharacterSet = CharacterSet(charactersIn: "•").inverted
        func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
            return DynamicImageView(
                dynamicImage: STPImageLibrary.cvcImage(for: brand),
                pairedColor: theme.colors.componentBackground
            )
        }
    }
}

// MARK: - Expiry Date Configuration
extension TextFieldElement {
    struct ExpiryDateConfiguration: TextFieldElementConfiguration {
        init(defaultValue: String? = nil, editConfiguration: EditConfiguration = .editable) {
            self.defaultValue = defaultValue
            self.editConfiguration = editConfiguration
        }

        let label: String = String.Localized.mm_yy
        let accessibilityLabel: String = String.Localized.expiration_date_accessibility_label
        let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
        let defaultValue: String?
        let editConfiguration: EditConfiguration
        func keyboardProperties(for text: String) -> KeyboardProperties {
            return .init(type: .asciiCapableNumberPad, textContentType: nil, autocapitalization: .none)
        }
        func maxLength(for text: String) -> Int {
            return 4
        }

        enum Error: TextFieldValidationError {
            case empty
            case incomplete
            case expired
            case invalidMonth
            case invalid

            public func shouldDisplay(isUserEditing: Bool) -> Bool {
                switch self {
                case .empty:                    return false
                case .incomplete:               return !isUserEditing
                case .expired, .invalidMonth, .invalid:   return true
                }
            }

            public var localizedDescription: String {
                switch self {
                case .empty:
                    return ""
                case .incomplete:
                    return String.Localized.your_cards_expiration_date_is_incomplete
                case .expired:
                    return String.Localized.your_card_has_expired
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
                guard let expiryDate = CardExpiryDate(text) else {
                   return .invalid(Error.invalid)
                }
                // Is the date expired?
                guard !expiryDate.expired() else {
                   return .invalid(Error.expired)
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

// MARK: Last four configuration
extension TextFieldElement {
    struct LastFourConfiguration: TextFieldElementConfiguration {
        let label = String.Localized.card_number
        let lastFour: String
        let editConfiguration: EditConfiguration
        let cardBrand: STPCardBrand?
        let cardBrandDropDown: DropdownFieldElement?

        private var lastFourFormatted: String {
            "•••• •••• •••• \(lastFour)"
        }

        init(lastFour: String, editConfiguration: EditConfiguration, cardBrand: STPCardBrand?, cardBrandDropDown: DropdownFieldElement?) {
            self.lastFour = lastFour
            self.cardBrandDropDown = cardBrandDropDown
            self.cardBrand = cardBrand
            self.editConfiguration = editConfiguration
        }

        func makeDisplayText(for text: String) -> NSAttributedString {
            return NSAttributedString(string: lastFourFormatted)
        }

        func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
            // Re-use same logic from PANConfiguration for accessory view
            return TextFieldElement.PANConfiguration(cardBrand: cardBrand, cardBrandDropDown: cardBrandDropDown).accessoryView(for: lastFourFormatted, theme: theme)
        }

        func validate(text: String, isOptional: Bool) -> ValidationState {
            stpAssert(!editConfiguration.isEditable, "Validation assumes that the field is read-only")
            return !lastFour.isEmpty ? .valid : .invalid(Error.empty)
        }
    }
}
