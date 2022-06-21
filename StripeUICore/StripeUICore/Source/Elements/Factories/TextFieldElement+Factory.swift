//
//  TextFieldElement+Factory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

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
        public init(type: NameType = .full, defaultValue: String?, label: String? = nil, isOptional: Bool = false) {
            self.type = type
            self.defaultValue = defaultValue
            if let label = label {
                self.label = label
            } else {
                self.label = Self.label(for: type)
            }
            self.isOptional = isOptional
        }

        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .namePhonePad, textContentType: textContentType, autocapitalization: .words)
        }
        
        private static func label(for type: NameType) -> String {
            switch type {
            case .given:
                return String.Localized.given_name
            case .family:
                return String.Localized.family_name
            case .full:
                return String.Localized.name
            case .onAccount:
                return String.Localized.nameOnAccount
            }
        }
    }
    
    static func makeName(label: String? = nil, defaultValue: String?) -> TextFieldElement {
        return TextFieldElement(configuration: NameConfiguration(type: .full, defaultValue: defaultValue, label: label))
    }

    // MARK: - Email
    
    struct EmailConfiguration: TextFieldElementConfiguration {
        public let label = String.Localized.email
        public let defaultValue: String?
        public let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
        let invalidError = Error.invalid(
            localizedDescription: String.Localized.invalid_email
        )

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
    
    static func makeEmail(defaultValue: String?) -> TextFieldElement {
        return TextFieldElement(configuration: EmailConfiguration(defaultValue: defaultValue))
    }
    
    // MARK: - Phone number
    struct PhoneNumberConfiguration: TextFieldElementConfiguration {
        static let incompleteError = Error.incomplete(localizedDescription:
                                                        STPLocalizedString("Incomplete phone number", "Error description for incomplete phone number"))
        static let invalidError = Error.invalid(localizedDescription:
                                                    STPLocalizedString("Unable to parse phone number", "Error string when we can't parse a phone number"))
        
        public let label: String
        public let regionCode: String?
        public let placeholderShouldFloat: Bool = false
        public let isOptional: Bool
        
        public init(regionCode: String?, isOptional: Bool = false) {
            self.regionCode = regionCode
            self.isOptional = isOptional
            self.label = {
                if let regionCode = regionCode,
                   let metadata = PhoneNumber.Metadata.metadata(for: regionCode) {
                    return metadata.sampleFilledPattern
                }
                return String.Localized.phone
            }()
        }
        
        public func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
            if text.isEmpty {
                return isOptional ? .valid : .invalid(Error.empty)
            }
            
            if let phoneNumber = PhoneNumber(number: text, countryCode: regionCode) {
                return phoneNumber.isComplete ? .valid :
                    .invalid(PhoneNumberConfiguration.incompleteError)
            } else {
                // assume user has entered a format or for a region
                // the SDK doesn't know about
                // return valid as long as it's non-empty and let the server
                // decide
                return .valid
            }
        }
        
        public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(type: .phonePad, textContentType: .telephoneNumber, autocapitalization: .none)
        }
        
        public var disallowedCharacters: CharacterSet {
            if regionCode?.isEmpty ?? true {
                return CharacterSet.stp_asciiDigit.union(CharacterSet(charactersIn: "+")).inverted // allow a + for custom country code
            } else {
                return CharacterSet.stp_asciiDigit.inverted
            }
        }
        
        public func makeDisplayText(for text: String) -> NSAttributedString {
            if let phoneNumber = PhoneNumber(number: text, countryCode: regionCode) {
                return NSAttributedString(string: phoneNumber.string(as: .national))
            } else {
                return NSAttributedString(string: text)
            }
        }
    }
    
    // MARK: - Company name
    
    struct CompanyConfiguration: TextFieldElementConfiguration {
        public let label: String = .Localized.company
        public let isOptional: Bool
        public let defaultValue: String?
    }
}
