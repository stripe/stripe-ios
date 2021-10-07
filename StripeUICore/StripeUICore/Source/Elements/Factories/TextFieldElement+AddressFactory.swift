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

// TODO(mludowise|IDPROD-2544): Make configurations internal after migrating `AddressSectionElement` to StripeUICore

@_spi(STP) public extension TextFieldElement {
    
    // MARK: - Address
    
    enum Address {
        
        // MARK: - Name
        
        public struct NameConfiguration: TextFieldElementConfiguration {
            public let label = String.Localized.name
            public let defaultValue: String?

            public init(defaultValue: String?) {
                self.defaultValue = defaultValue
            }

            public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .namePhonePad, textContentType: .name, autocapitalization: .words)
            }
        }
        
        public static func makeName(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: NameConfiguration(defaultValue: defaultValue))
        }
        
        // MARK: - Email
        
        public struct EmailConfiguration: TextFieldElementConfiguration {
            public let label = String.Localized.email
            public let defaultValue: String?
            public let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
            let invalidError = Error.invalid(
                localizedDescription: String.Localized.invalid_email
            )

            public init(defaultValue: String?) {
                self.defaultValue = defaultValue
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
        
        public static func makeEmail(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(configuration: EmailConfiguration(defaultValue: defaultValue))
        }
        
        // MARK: - Line1, Line2
        
        public struct LineConfiguration: TextFieldElementConfiguration {
            @frozen public enum LineType {
                case line1
                case line2
            }
            let lineType: LineType
            public var label: String {
                switch lineType {
                case .line1:
                    return String.Localized.address_line1
                case .line2:
                    return String.Localized.address_line2
                }
            }
            public let defaultValue: String?

            public init(lineType: LineType, defaultValue: String?) {
                self.lineType = lineType
                self.defaultValue = defaultValue
            }

        }
        
        public static func makeLine1(defaultValue: String?) -> TextFieldElement {
            return TextFieldElement(
                configuration: LineConfiguration(lineType: .line1, defaultValue: defaultValue)
            )
        }
        
        public static func makeLine2(defaultValue: String?) -> TextFieldElement {
            let line2 = TextFieldElement(
                configuration: LineConfiguration(lineType: .line2, defaultValue: defaultValue)
            )
            line2.isOptional = true // Hardcode all line2 as optional
            return line2
        }
        
        // MARK: - City/Locality
        
        public struct CityConfiguration: TextFieldElementConfiguration {
            public let label: String
            public let defaultValue: String?

            public init(label: String, defaultValue: String?) {
                self.label = label
                self.defaultValue = defaultValue
            }

            public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressCity, autocapitalization: .words)
            }
        }
        
        // MARK: - State/Province/Administrative area/etc.
        
        public struct StateConfiguration: TextFieldElementConfiguration {
            public let label: String
            public let defaultValue: String?

            public init(label: String, defaultValue: String?) {
                self.label = label
                self.defaultValue = defaultValue
            }

            public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressState, autocapitalization: .words)
            }
        }
        
        // MARK: - Postal code/Zip code
        
        public struct PostalCodeConfiguration: TextFieldElementConfiguration {
            let regex: String?
            public let label: String
            public let defaultValue: String?

            public init(regex: String?, label: String, defaultValue: String?) {
                self.regex = regex
                self.label = label
                self.defaultValue = defaultValue
            }

            public func validate(text: String, isOptional: Bool) -> ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if regex != nil {
                   // verify
                }
                return .valid
            }
            
            public func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .postalCode, autocapitalization: .allCharacters)
            }
        }
    }
}
