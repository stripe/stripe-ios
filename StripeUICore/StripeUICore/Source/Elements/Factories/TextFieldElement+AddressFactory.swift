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
                return countryCode == "US" ? .decimalDigits.inverted : .newlines
            }

            func maxLength(for text: String) -> Int {
                return countryCode == "US" ? 5 : .max
            }

            func validate(text: String, isOptional: Bool) -> ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if countryCode == "US", text.count < maxLength(for: text) {
                    return .invalid(Error.incomplete(localizedDescription: String.Localized.your_zip_is_incomplete))
                }
                return .valid
            }

            func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
                return .init(type: countryCode == "US" ? .numberPad : .default, textContentType: .postalCode, autocapitalization: .allCharacters)
            }
        }
    }
}
