//
//  TextFieldElement+Factory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public extension TextFieldElement {

    // MARK: - Name
    struct NameConfiguration: TextFieldElementConfiguration {
        @frozen public enum NameType {
            case given, family, full, onAccount
        }

        let type: NameType
        public let defaultValue: String?
        public let label: String
        public let isOptional: Bool
        public let editConfiguration: EditConfiguration
        private var textContentType: UITextContentType {
            switch type {
            case .given:
                return .givenName
            case .family:
                return .familyName
            case .full, .onAccount:
                return .name
            }
        }

        /// - Parameter label: If `nil`, defaults to a string on the `type` e.g. "Name"
        public init(type: NameType = .full, defaultValue: String?, label: String? = nil, isOptional: Bool = false, editConfiguration: EditConfiguration = .editable) {
            self.type = type
            self.defaultValue = defaultValue
            if let label = label {
                self.label = label
            } else {
                self.label = Self.label(for: type)
            }
            self.isOptional = isOptional
            self.editConfiguration = editConfiguration
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .default, textContentType: textContentType, autocapitalization: .words)
        }

        private static func label(for type: NameType) -> String {
            switch type {
            case .given:
                return String.Localized.given_name
            case .family:
                return String.Localized.family_name
            case .full:
                return String.Localized.full_name
            case .onAccount:
                return String.Localized.nameOnAccount
            }
        }
    }

    static func makeName(label: String? = nil, defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
        return TextFieldElement(configuration: NameConfiguration(type: .full, defaultValue: defaultValue, label: label), theme: theme)
    }

    // MARK: - Email

    struct EmailConfiguration: TextFieldElementConfiguration {
        public let label = String.Localized.email
        public let defaultValue: String?
        public let isOptional: Bool
        public let editConfiguration: EditConfiguration
        public let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
        let invalidError = Error.invalid(
            localizedDescription: String.Localized.invalid_email
        )

        public init(defaultValue: String? = nil, isOptional: Bool = false, editConfiguration: EditConfiguration = .editable) {
            self.defaultValue = defaultValue
            self.isOptional = isOptional
            self.editConfiguration = editConfiguration
        }

        public func validate(text: String, isOptional: Bool) -> ValidationState {
            if text.isEmpty {
                return isOptional ? .valid : .invalid(Error.empty)
            }
            if STPEmailAddressValidator.stringIsValidEmailAddress(text) {
                return .valid
            } else {
                return .invalid(invalidError)
            }
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .emailAddress, textContentType: .emailAddress, autocapitalization: .none)
        }
    }

    static func makeEmail(defaultValue: String?, isOptional: Bool = false, theme: ElementsAppearance = .default) -> TextFieldElement {
        return TextFieldElement(configuration: EmailConfiguration(defaultValue: defaultValue,
                                                                  isOptional: isOptional), theme: theme)
    }

    // MARK: VPA

    struct VPAConfiguration: TextFieldElementConfiguration {
        public let label = String.Localized.upi_id
        public let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
        let invalidError = Error.invalid(
            localizedDescription: .Localized.invalid_upi_id
        )

        public func validate(text: String, isOptional: Bool) -> ValidationState {
            guard !text.isEmpty else {
                return isOptional ? .valid : .invalid(Error.empty)
            }

            return STPVPANumberValidator.stringIsValidVPANumber(text) ? .valid : .invalid(invalidError)
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .emailAddress, textContentType: .emailAddress, autocapitalization: .none)
        }

    }

    static func makeVPA(theme: ElementsAppearance = .default) -> TextFieldElement {
        return TextFieldElement(configuration: VPAConfiguration(), theme: theme)
    }

    // MARK: - Blik code
    struct BlikCodeConfiguration: TextFieldElementConfiguration {
        public let label = String.Localized.blik_code
        public let disallowedCharacters: CharacterSet = .decimalDigits.inverted
        public let defaultValue: String?
        let invalidError = Error.invalid(
            localizedDescription: .Localized.invalid_blik_code
        )

        public func validate(text: String, isOptional: Bool) -> ValidationState {
            guard !text.isEmpty else {
                return isOptional ? .valid : .invalid(Error.empty)
            }
            return STPBlikCodeValidator.stringIsValidBlikCode(text) ?.valid: .invalid(invalidError)
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .numberPad, textContentType: .none, autocapitalization: .none)
        }

        public func maxLength(for text: String) -> Int {
            return 6
        }
    }

    static func makeBlikCode(defaultValue: String?, theme: ElementsAppearance) -> TextFieldElement {
        return TextFieldElement(configuration: BlikCodeConfiguration(defaultValue: defaultValue), theme: theme)
    }

    // MARK: - Konbini confirmation/phone number

    /// An optional 10 to 11 digit numeric-only string determining the confirmation code at applicable convenience stores. This is typically a phone number, so we label it as such.
    struct KonbiniPhoneNumberConfiguration: TextFieldElementConfiguration {
        public let label = String.Localized.phoneNumber
        public let disallowedCharacters: CharacterSet = .decimalDigits.inverted
        public let isOptional: Bool = true
        let incompleteError = Error.incomplete(localizedDescription: .Localized.incomplete_phone_number)

        public func validate(text: String, isOptional: Bool) -> ValidationState {
            guard !text.isEmpty else {
                return isOptional ? .valid : .invalid(Error.empty)
            }
            guard text.count > 9 else {
                return .invalid(incompleteError)
            }
            return .valid
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .numberPad, textContentType: .telephoneNumber, autocapitalization: .none)
        }

        public func maxLength(for text: String) -> Int {
            return 11
        }
    }

    static func makeKonbini(theme: ElementsAppearance) -> TextFieldElement {
        return TextFieldElement(configuration: KonbiniPhoneNumberConfiguration(), theme: theme)
    }

    // MARK: - Phone number
    struct PhoneNumberConfiguration: TextFieldElementConfiguration {
        static let incompleteError = Error.incomplete(localizedDescription: .Localized.incomplete_phone_number)
        static let invalidError = Error.invalid(localizedDescription: .Localized.invalid_phone_number)
        public let label: String = .Localized.phoneNumber
        /// - Note: Country code helps us format the phone number
        public let countryCodeProvider: () -> String
        public let defaultValue: String?
        public let isOptional: Bool

        public init(defaultValue: String? = nil, isOptional: Bool = false, countryCodeProvider: @escaping () -> String) {
            self.countryCodeProvider = countryCodeProvider
            self.defaultValue = defaultValue
            self.isOptional = isOptional
        }

        public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
            if text.isEmpty {
                return isOptional ? .valid : .invalid(Error.empty)
            }

            if let phoneNumber = PhoneNumber(number: text, countryCode: countryCodeProvider()) {
                return phoneNumber.isComplete ? .valid :
                    .invalid(PhoneNumberConfiguration.incompleteError)
            } else {
                // Assume user has entered a format or for a region the SDK doesn't know about.
                // Return valid as long as it's non-empty and let the server decide.
                return .valid
            }
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .phonePad, textContentType: .telephoneNumber, autocapitalization: .none)
        }

        public var disallowedCharacters: CharacterSet {
            return .stp_asciiDigit.inverted
        }

        public func makeDisplayText(for text: String) -> NSAttributedString {
            if let phoneNumber = PhoneNumber(number: text, countryCode: countryCodeProvider()) {
                return NSAttributedString(string: phoneNumber.string(as: .national))
            } else {
                return NSAttributedString(string: text)
            }
        }
    }

}
