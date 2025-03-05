//
//  TextFieldElementConfiguration.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/**
 Contains the business logic for a TextField.
 
 - Seealso: `TextFieldElement+Factory.swift`
 */
@_spi(STP) public protocol TextFieldElementConfiguration {
    var label: String { get }

    /**
     Defaults to `label`
     */
    var accessibilityLabel: String { get }
    var shouldShowClearButton: Bool { get }
    var disallowedCharacters: CharacterSet { get }
    /**
     If `true`, adds " (optional)" to the field's label . Defaults to `false`.
     - Note: This value is passed to the `validate(text:isOptional:)` method.
     */
    var isOptional: Bool { get }

    /**
      - Note: The text field gets a sanitized version of this (i.e. after stripping disallowed characters, applying max length, etc.)
     */
    var defaultValue: String? { get }

    /**
      - Configuration for whether or not the field is editable
     */
    var editConfiguration: EditConfiguration { get }

    /**
     Validate the text.
     
     - Parameter isOptional: Whether or not the text field's value is optional.
     */
    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState

    /**
     A string to display under the field
     */
    func subLabel(text: String) -> String?

    /**
     - Parameter text: The user's sanitized input (i.e., removing `disallowedCharacters` and clipping to `maxLength(for:)`)
     - Returns: A string as it should be displayed to the user. e.g., Apply kerning between every 4th and 5th number for PANs.
     */
    func makeDisplayText(for text: String) -> NSAttributedString

    /**
     - Returns: An assortment of properties to apply to the keyboard for the text field.
     */
    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties

    /**
     The maximum length of text allowed in the text field.
     - Note: Text beyond this length is removed before its displayed in the UI or passed to other `TextFieldElementConfiguration` methods.
     - Note: Return `Int.max` to indicate there is no maximum
     */
    func maxLength(for text: String) -> Int

    /**
     An optional accessory view displayed on the trailing side of the text field.
     This could be the logo of a network, a bank, etc.
     - Returns: a view.
     */
    func accessoryView(for text: String, theme: ElementsAppearance) -> UIView?

    /**
     Convenience method that creates a TextFieldElement using this Configuration
    */
    func makeElement(theme: ElementsAppearance) -> TextFieldElement
}

// MARK: - Default implementation

public extension TextFieldElementConfiguration {
    var accessibilityLabel: String {
        return label
    }

    var disallowedCharacters: CharacterSet {
        return .newlines
    }

    var isOptional: Bool {
        return false
    }

    var defaultValue: String? {
        return nil
    }

    // Hide clear button by default
    var shouldShowClearButton: Bool {
        return false
    }

    var editConfiguration: EditConfiguration {
        return .editable
    }

    func makeDisplayText(for text: String) -> NSAttributedString {
        return NSAttributedString(string: text)
    }

    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
        return .init(type: .default, textContentType: nil, autocapitalization: .words)
    }

    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
        if text.stp_stringByRemovingCharacters(from: .whitespacesAndNewlines).isEmpty {
            return isOptional ? .valid : .invalid(TextFieldElement.Error.empty)
        }
        return .valid
    }

    func subLabel(text: String) -> String? {
        return nil
    }

    func maxLength(for text: String) -> Int {
        return .max
    }

    func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
        return nil
    }

    func makeElement(theme: ElementsAppearance) -> TextFieldElement {
        return TextFieldElement(configuration: self, theme: theme)
    }
}

@_spi(STP) public enum EditConfiguration {
    // Text can be modified
    case editable

    // Text can not be modified, with disabled appearance
    case readOnly

    // Text can not be modified, without disabled appearance
    case readOnlyWithoutDisabledAppearance

    @_spi(STP) public var isEditable: Bool {
        return self == .editable
    }
}
