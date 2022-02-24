//
//  TextFieldElement+AccountFactory.swift
//  StripeUICore
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

@_spi(STP) public extension TextFieldElement {

    // MARK: - Account
    enum Account {
        struct BSBConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription:
                                                            STPLocalizedString("Incomplete phone number", "Error description for incomplete phone number"))

            let label = String.Localized.bsb
            let disallowedCharacters: CharacterSet = .stp_asciiLetters
            var maxLength: Int {
                return 7
            }
            let defaultValue: String?


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

        struct AUBECSAccountNumberConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription:
                                                            STPLocalizedString("The account number you entered is incomplete.", "Error description for incomplete account number"))
            let label = String.Localized.auBECSAccount
            let disallowedCharacters: CharacterSet = .stp_asciiLetters
            let numberOfDigitsRequired = 9
            var maxLength: Int {
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
