//
//  TextFieldElement+AddressFactory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public extension TextFieldElement {
    enum Address {

        // MARK: - Line1, Line2

        struct LineConfiguration: TextFieldElementConfiguration {

            enum LineType {
                case line1
                case line2
                // Label is "Address" and shows a clear button
                case autoComplete
                // Same as .line1, but shows a 􀊫 autocomplete button accessory view
                case line1Autocompletable(didTapAutocomplete: () -> Void)
            }
            let lineType: LineType
            var label: String {
                switch lineType {
                case .line1, .line1Autocompletable:
                    return String.Localized.address_line1
                case .line2:
                    return String.Localized.address_line2
                case .autoComplete:
                    return String.Localized.address
                }
            }
            let defaultValue: String?
            var shouldShowClearButton: Bool {
                if case .autoComplete = lineType { return true }
                return false
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                switch lineType {
                case .line1, .line1Autocompletable, .autoComplete:
                    return .init(type: .default, textContentType: .streetAddressLine1, autocapitalization: .words)
                case .line2:
                    return .init(type: .default, textContentType: .streetAddressLine2, autocapitalization: .words)
                }
            }

            var isOptional: Bool {
                if case .line2 = lineType { return true } // Hardcode all line2 as optional
                return false
            }

            func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
                if case .line1Autocompletable(let didTapAutocomplete) = lineType {
                    let autocompleteIconButton = UIButton.make(type: .system, didTap: didTapAutocomplete)
                    let configuration = UIImage.SymbolConfiguration(pointSize: CGFloat(10), weight: .bold)
                    let image = UIImage(systemName: "magnifyingglass", withConfiguration: configuration)?
                        .withTintColor(theme.colors.primary, renderingMode: .alwaysOriginal)
                    autocompleteIconButton.setImage(image, for: .normal)
                    autocompleteIconButton.accessibilityLabel = String.Localized.search
                    autocompleteIconButton.accessibilityIdentifier = "autocomplete_affordance"
                    return autocompleteIconButton
                }
                return nil
            }
        }

        public static func makeLine1(defaultValue: String?, theme: ElementsAppearance) -> TextFieldElement {
            return TextFieldElement(
                configuration: LineConfiguration(lineType: .line1, defaultValue: defaultValue), theme: theme
            )
        }

        static func makeLine2(defaultValue: String?, theme: ElementsAppearance) -> TextFieldElement {
            let line2 = TextFieldElement(
                configuration: LineConfiguration(lineType: .line2, defaultValue: defaultValue), theme: theme
            )
            return line2
        }

        public static func makeAutoCompleteLine(defaultValue: String?, theme: ElementsAppearance) -> TextFieldElement {
            return TextFieldElement(
                configuration: LineConfiguration(lineType: .autoComplete, defaultValue: defaultValue), theme: theme
            )
        }

        // MARK: - City/Locality

        struct CityConfiguration: TextFieldElementConfiguration {
            let label: String
            let defaultValue: String?
            let isOptional: Bool

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressCity, autocapitalization: .words)
            }
        }

        // MARK: - State/Province/Administrative area/etc.

        struct StateConfiguration: TextFieldElementConfiguration {
            let label: String
            let defaultValue: String?
            let isOptional: Bool

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: .default, textContentType: .addressState, autocapitalization: .words)
            }
        }

        // MARK: - Postal code/Zip code

        struct PostalCodeConfiguration: TextFieldElementConfiguration {
            let countryCode: String
            let label: String
            let defaultValue: String?
            let isOptional: Bool
            public var disallowedCharacters: CharacterSet {
                switch countryCode {
                case "US": .decimalDigits.inverted
                case "GB": .alphanumerics.inverted
                default: .newlines
                }
            }
            private var regex: NSRegularExpression? {
                do {
                    return switch countryCode {
                    case "CA": try NSRegularExpression(pattern: "[a-zA-Z]\\d[a-zA-Z][\\s-]?\\d[a-zA-Z]\\d")
                    case "GB": try NSRegularExpression(pattern: "^[A-Za-z][A-Za-z0-9]*(?: [A-Za-z0-9]*)?$")
                    case "US": try NSRegularExpression(pattern: "\\d+")
                    default: try NSRegularExpression(pattern: ".*")
                    }
                } catch {
                    assertionFailure("Invalid regex pattern for postal code: \(error)")
                    return nil
                }
            }
            private var minLength: Int {
                switch countryCode {
                case "CA": 6 // allow for no space or dash in the middle
                case "GB": 5
                case "US": 5
                default: 1
                }
            }
            private var genericError: Error {
                if countryCode == "US" {
                    Error.invalid(localizedDescription: String.Localized.your_zip_is_invalid)
                } else {
                    Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)
                }
            }

            func maxLength(for text: String) -> Int {
                switch countryCode {
                case "CA": 7 // allow for space or dash in the middle
                case "GB": 7
                case "US": 5
                default: .max
                }
            }

            func validate(text: String, isOptional: Bool) -> ValidationState {
                // validate non-empty
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty(localizedDescription: countryCode == "US" ? String.Localized.your_zip_is_incomplete : String.Localized.your_postal_code_is_incomplete))
                }
                // validate long enough
                if text.count < minLength {
                    if countryCode == "US" {
                        return .invalid(Error.incomplete(localizedDescription: String.Localized.your_zip_is_incomplete))
                    } else {
                        return .invalid(Error.incomplete(localizedDescription: String.Localized.your_postal_code_is_incomplete))
                    }
                }
                // validate short enough
                if text.count > maxLength(for: text) {
                    return .invalid(genericError)
                }
                // validate pattern
                if let regex, regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count)).isEmpty {
                    return .invalid(genericError)
                }
                return .valid
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                // CA and GB use alphanmeric. US uses numeric only
                return .init(type: countryCode == "US" ? .numberPad : .default, textContentType: .postalCode, autocapitalization: .allCharacters)
            }

        }
    }
}
