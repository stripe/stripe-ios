//
//  TextFieldElement+AccountFactory.swift
//  StripeUICore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

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
        
        public static func makeBSB(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: BSBConfiguration(defaultValue: defaultValue))
        }

        // MARK: - AUBECS Account Number
        struct AUBECSAccountNumberConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription:
                                                            STPLocalizedString("The account number you entered is incomplete.", "Error description for incomplete account number"))
            let label = String.Localized.accountNumber
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit
            let numberOfDigitsRequired = 9
            func maxLength(for text: String) -> Int {
                return numberOfDigitsRequired
            }
            let defaultValue: String?

            public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                return text.count == numberOfDigitsRequired ? .valid : .invalid(AUBECSAccountNumberConfiguration.incompleteError)
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }
        }

        public static func makeAUBECSAccountNumber(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: AUBECSAccountNumberConfiguration(defaultValue: defaultValue))
        }
    }
}
