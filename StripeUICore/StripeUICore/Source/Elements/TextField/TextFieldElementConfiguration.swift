//
//  TextFieldElementConfiguration.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 Contains the business logic for a TextField.
 
 - Seealso: `TextFieldElement+Factory.swift`
 */
@_spi(STP) public protocol TextFieldElementConfiguration {
    var label: String { get }
    var disallowedCharacters: CharacterSet { get }
    var maxLength: Int { get }
    
    /**
      - Note: The text field gets a sanitized version of this (i.e. after stripping disallowed characters, applying max length, etc.)
     */
    var defaultValue: String? { get }
    
    /**
     Validate the text.
     
     - Parameter isOptional: Whether or not the text field's value is optional
     */
    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState
    
    /**
     - Returns: A string as it should be displayed to the user. e.g., Apply kerning between every 4th and 5th number for PANs.
     */
    func makeDisplayText(for text: String) -> NSAttributedString
    
    /**
     - Returns: An assortment of properties to apply to the keyboard for the text field.
     */
    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties
}

// MARK: - Default implementation

public extension TextFieldElementConfiguration {
    func makeDisplayText(for text: String) -> NSAttributedString {
        return NSAttributedString(string: text)
    }
    
    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
        return .init(type: .default, textContentType: nil, autocapitalization: .words)
    }
    
    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
        if text.isEmpty {
            return isOptional ? .valid : .invalid(TextFieldElement.Error.empty)
        }
        return .valid
    }
    
    var disallowedCharacters: CharacterSet {
        return .newlines
    }
    
    var maxLength: Int {
        return Int.max // i.e., there is no maximum length
    }
    
    var defaultValue: String? {
        return nil
    }
}
