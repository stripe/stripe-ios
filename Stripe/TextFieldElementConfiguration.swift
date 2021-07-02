//
//  TextFieldElementConfiguration.swift
//  StripeiOS
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
protocol TextFieldElementConfiguration {
    var placeholder: String { get }
    var disallowedCharacters: CharacterSet { get }
    var maxLength: Int { get }
    
    /**
     Validate the text.
     
     - Parameter isOptional: Whether or not the text field's value is optional
     */
    func validate(text: String, isOptional: Bool) -> ElementValidationState
    
    /**
     - Returns: A string as it should be displayed to the user. e.g., Apply kerning between every 4th and 5th number for PANs.
     */
    func makeDisplayText(for text: String) -> NSAttributedString
    
    /**
     - Returns: An assortment of properties to apply to the keyboard for the text field.
     */
    func makeKeyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties
    
    /**
     - Returns: The passed in `params` object mutated according to the text field's text. You can assume the text is valid.
     */
    func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams?
}

// MARK: - Default implementation

extension TextFieldElementConfiguration {
    func makeDisplayText(for text: String) -> NSAttributedString {
        return NSAttributedString(string: text)
    }
    
    func makeKeyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
        return .init(type: .default, autocapitalization: .words)
    }
    
    var disallowedCharacters: CharacterSet {
        return .newlines
    }
    
    var maxLength: Int {
        return Int.max // i.e., there is no maximum length
    }
}
