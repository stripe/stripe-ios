//
//  TextFieldElement+AddressFactory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

@_spi(STP) public extension TextFieldElement {

    // MARK: - Address
    
    enum Address {
        
        // MARK: - Name
        
        public struct NameConfiguration: TextFieldElementConfiguration {
            @frozen public enum NameType {
                case given, family, full, onAccount
            }

            let type: NameType
            public let defaultValue: String?

            public var label: String {
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

            public init(type: NameType, defaultValue: String?) {
                 self.type = type
                 self.defaultValue = defaultValue
             }

            public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .namePhonePad, textContentType: textContentType, autocapitalization: .words)
            }
        }
        
        public static func makeFullName(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: NameConfiguration(type: .full, defaultValue: defaultValue))
        }

        public static func makeNameOnAccount(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: NameConfiguration(type: .onAccount, defaultValue: defaultValue))
        }
        // MARK: - Email
        
        struct EmailConfiguration: TextFieldElementConfiguration {
            let label = String.Localized.email
            let defaultValue: String?
            let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
            let invalidError = Error.invalid(
                localizedDescription: String.Localized.invalid_email
            )

            func validate(text: String, isOptional: Bool) -> ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if STPEmailAddressValidator.stringIsValidEmailAddress(text) {
                    return .valid
                } else {
                    return .invalid(invalidError)
                }
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .emailAddress, textContentType: .emailAddress, autocapitalization: .none)
            }
        }
        
        public static func makeEmail(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: EmailConfiguration(defaultValue: defaultValue))
        }
        
        // MARK: - Line1, Line2
        
        struct LineConfiguration: TextFieldElementConfiguration {
            enum LineType {
                case line1
                case line2
            }
            let lineType: LineType
            var label: String {
                switch lineType {
                case .line1:
                    return String.Localized.address_line1
                case .line2:
                    return String.Localized.address_line2
                }
            }
            let defaultValue: String?
        }
        
        static func makeLine1(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(
                configuration: LineConfiguration(lineType: .line1, defaultValue: defaultValue)
            )
        }
        
        static func makeLine2(defaultValue: String?) -> TextFieldElement {
            let line2 = TextFieldElement(
                configuration: LineConfiguration(lineType: .line2, defaultValue: defaultValue)
            )
            line2.isOptional = true // Hardcode all line2 as optional
            return line2
        }
        
        // MARK: - City/Locality
        
        struct CityConfiguration: TextFieldElementConfiguration {
            let label: String
            let defaultValue: String?

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressCity, autocapitalization: .words)
            }
        }
        
        // MARK: - State/Province/Administrative area/etc.
        
        struct StateConfiguration: TextFieldElementConfiguration {
            let label: String
            let defaultValue: String?

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressState, autocapitalization: .words)
            }
        }
        
        // MARK: - Postal code/Zip code
        
        struct PostalCodeConfiguration: TextFieldElementConfiguration {
            let regex: String?
            let label: String
            let defaultValue: String?

            func validate(text: String, isOptional: Bool) -> ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if regex != nil {
                   // verify
                }
                return .valid
            }
            
            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .postalCode, autocapitalization: .allCharacters)
            }
        }
        
        // MARK: - Phone number
        public struct PhoneNumberConfiguration: TextFieldElementConfiguration {
            static let incompleteError = Error.incomplete(localizedDescription:
                                                            STPLocalizedString("Incomplete phone number", "Error description for incomplete phone number"))
            static let invalidError = Error.invalid(localizedDescription:
                                                        STPLocalizedString("Unable to parse phone number", "Error string when we can't parse a phone number"))
            
            public let label: String
            public let regionCode: String?
            public let placeholderShouldFloat: Bool = false
            
            public init(regionCode: String?) {
                self.regionCode = regionCode
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
    }
}
