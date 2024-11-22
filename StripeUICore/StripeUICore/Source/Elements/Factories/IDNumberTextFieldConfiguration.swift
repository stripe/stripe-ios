//
//  IDNumberTextFieldConfiguration.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public struct IDNumberTextFieldConfiguration: TextFieldElementConfiguration {

    // TODO(mludowise|IDPROD-2596): Check if these are the formats needed to support IDV.
    // When finalized, change enum to String type so we can configure allowed formats from our backend response.
    public enum IDNumberType {
        case BR_CPF
        case BR_CPF_CNPJ
        case SG_NRIC_OR_FIN
        case US_SSN_LAST4
    }

    let type: IDNumberType?
    public let label: String
    public let defaultValue: String?

    /**
     - Parameters:
       - type: The type of ID number that should be validated in this input field. If the ID type is unknown, passing `nil` will produce a configuration with no restrictions on the input.
       - label: The label of the field
     */
    public init(type: IDNumberType?, label: String, defaultValue: String?) {
        self.type = type
        self.label = label
        self.defaultValue = defaultValue
    }

    public var disallowedCharacters: CharacterSet {
        switch type {
        case .BR_CPF,
            .BR_CPF_CNPJ,
            .US_SSN_LAST4:
            return CharacterSet.stp_asciiDigit.inverted
        case .SG_NRIC_OR_FIN,
            .none:
            return .newlines
        }
    }

    public func maxLength(for text: String) -> Int {
        switch type {
        case .BR_CPF:
            return 11
        case .BR_CPF_CNPJ:
            return 14
        case .US_SSN_LAST4:
            return 4
        case .SG_NRIC_OR_FIN,
            .none:
            return .max
        }
    }

    /**
     - Parameters:
     - text: The text that will be formatted with this formatter

     - Returns: The format consisting of a string using pound signs `#` for numeric placeholders,  and `*` for  letters.
     */
    func format(text: String) -> String? {
        switch type {
        case .BR_CPF,
            .BR_CPF_CNPJ where text.count <= 11:
            return "###.###.###-##"
        case .BR_CPF_CNPJ:
            return "##.###.###/####-##"
        case .US_SSN_LAST4:
            return "••• - •• - ####"
        case .none:
            return nil
        case .some(.SG_NRIC_OR_FIN):
            return nil
        }
    }

    public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
        guard !text.isEmpty else {
            return isOptional ? .valid : .invalid(TextFieldElement.Error.empty)
        }

        switch type {
        // CPF is 11 digits but CNPJ is 14 (maxLength), so we will allow 11 here
        case .BR_CPF_CNPJ where text.count == 11,
            .none:
            return .valid
        case .SG_NRIC_OR_FIN:
            return .valid
        default:
            return maxLength(for: text) == text.count
                ? .valid
                : .invalid(
                    TextFieldElement.Error.incomplete(
                        localizedDescription: STPLocalizedString(
                            "The ID number you entered is incomplete.",
                            "An error message."
                        )
                    )
                )
        }
    }

    public func makeDisplayText(for text: String) -> NSAttributedString {
        guard let format = format(text: text),
            let formatter = TextFieldFormatter(format: format)
        else {
            return NSAttributedString(string: text)
        }

        let formattedString = formatter.applyFormat(
            to: text
        )

        return NSAttributedString(string: formattedString)
    }

    public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
        switch type {
        case .BR_CPF,
            .BR_CPF_CNPJ,
            .US_SSN_LAST4:
            return .init(
                type: .asciiCapableNumberPad,
                textContentType: nil,
                autocapitalization: .none
            )
        default:
            return .init(
                type: .default,
                textContentType: nil,
                autocapitalization: .allCharacters
            )
        }
    }
}
