//
//  TextFieldElement+ACSSDebit.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension TextFieldElement {
    enum ACSSDebit {
        struct NumberConfiguration: TextFieldElementConfiguration {
            let label: String
            let defaultValue: String?
            let validLengths: ClosedRange<Int>
            let incompleteErrorDescription: String
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit

            func maxLength(for text: String) -> Int {
                return validLengths.upperBound
            }

            func validate(text: String, isOptional: Bool) -> ValidationState {
                guard !text.isEmpty else {
                    return isOptional
                        ? .valid
                        : .invalid(Error.empty(localizedDescription: incompleteErrorDescription))
                }
                return validLengths.contains(text.count)
                    ? .valid
                    : .invalid(Error.incomplete(localizedDescription: incompleteErrorDescription))
            }

            func keyboardProperties(for text: String) -> KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }
        }

        struct ConfirmAccountNumberConfiguration: TextFieldElementConfiguration {
            let label = STPLocalizedString("Confirm account number", "Label for confirming an ACSS Debit account number")
            let defaultValue: String?
            let accountNumber: () -> String
            let disallowedCharacters: CharacterSet = .stp_invertedAsciiDigit

            func maxLength(for text: String) -> Int {
                return 12
            }

            func validate(text: String, isOptional: Bool) -> ValidationState {
                guard !text.isEmpty else {
                    return .invalid(Error.empty(localizedDescription: STPLocalizedString(
                        "Confirm the account number.",
                        "Error shown when an ACSS Debit account number confirmation is empty"
                    )))
                }
                return text == accountNumber()
                    ? .valid
                    : .invalid(Error.invalid(localizedDescription: STPLocalizedString(
                        "Your account numbers don’t match.",
                        "Error shown when ACSS Debit account numbers do not match"
                    )))
            }

            func keyboardProperties(for text: String) -> KeyboardProperties {
                return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
            }
        }
    }
}
