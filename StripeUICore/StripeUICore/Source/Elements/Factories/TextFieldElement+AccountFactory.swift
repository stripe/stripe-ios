//
//  TextFieldElement+AccountFactory.swift
//  StripeUICore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public extension TextFieldElement {

    enum Account {
        // MARK: - BSB Number
        struct BSBConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription: String.Localized.incompleteBSBEntered)

            let label = STPLocalizedString("BSB number", "Placeholder for AU BECS BSB number")
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
            func maxLength(for text: String) -> Int {
                return 6
            }
            let defaultValue: String?
            func subLabel(text: String) -> String? {
                return BSBNumberProvider.shared.bsbName(for: text)
            }

            public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }

                let bsbNumber = BSBNumber(number: text)
                return bsbNumber.isComplete ? .valid :
                    .invalid(Account.BSBConfiguration.incompleteError)
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }

            public func makeDisplayText(for text: String) -> NSAttributedString {
                let bsbNumber = BSBNumber(number: text)
                return NSAttributedString(string: bsbNumber.formattedNumber())
            }
        }

        public static func makeBSB(defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
            return TextFieldElement(configuration: BSBConfiguration(defaultValue: defaultValue), theme: theme)
        }

        // MARK: - AUBECS Account Number
        struct AUBECSAccountNumberConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription:
                                                            String.Localized.incompleteAccountNumber)
            let label = String.Localized.accountNumber
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
            let minimumNumberOfDigits = 4
            let maximumNumberofDigits = 9

            func maxLength(for text: String) -> Int {
                return maximumNumberofDigits
            }
            let defaultValue: String?

            public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                return text.count >= minimumNumberOfDigits && text.count <= maximumNumberofDigits ? .valid : .invalid(AUBECSAccountNumberConfiguration.incompleteError)
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }
        }

        public static func makeAUBECSAccountNumber(defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
            return TextFieldElement(configuration: AUBECSAccountNumberConfiguration(defaultValue: defaultValue), theme: theme)
        }

        // MARK: - Bacs Sort Code
        struct SortCodeConfiguration: TextFieldElementConfiguration {
            static let invalidError = Error.incomplete(localizedDescription: String.Localized.invalidSortCodeEntered)

            let label = STPLocalizedString("Sort code", "Placeholder for Bacs sort code (a bank routing number used in the UK and Ireland)")
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
            func maxLength(for text: String) -> Int {
                return 6
            }
            let defaultValue: String?

            public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }

                let sortCode = SortCode(number: text)
                return sortCode.isComplete ? .valid :
                    .invalid(Account.SortCodeConfiguration.invalidError)
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }

            public func makeDisplayText(for text: String) -> NSAttributedString {
                let sortCode = SortCode(number: text)
                return NSAttributedString(string: sortCode.formattedNumber())
            }
        }

        public static func makeSortCode(defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
            return TextFieldElement(configuration: SortCodeConfiguration(defaultValue: defaultValue), theme: theme)
        }

        // MARK: - Bacs Account Number
        struct BacsAccountNumberConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription: String.Localized.incompleteAccountNumber)
            let label = String.Localized.accountNumber
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
            let numberOfDigitsRequired = 8

            func maxLength(for text: String) -> Int {
                return numberOfDigitsRequired
            }
            let defaultValue: String?

            public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                return text.count == numberOfDigitsRequired ? .valid : .invalid(BacsAccountNumberConfiguration.incompleteError)
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }
        }

        public static func makeBacsAccountNumber(defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
            return TextFieldElement(configuration: BacsAccountNumberConfiguration(defaultValue: defaultValue), theme: theme)
        }
    }
}
