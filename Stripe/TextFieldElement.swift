//
//  TextFieldElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A generic text field whose logic is extracted into `TextFieldElementConfiguration`.
 
 - Seealso: `TextFieldElementConfiguration`
 */
final class TextFieldElement {
    
    // MARK: - Properties
    
    weak var delegate: ElementDelegate?
    var isOptional: Bool = false {
        didSet {
            textFieldView.updateUI(with: viewModel)
            delegate?.didUpdate(element: self)
        }
    }
    lazy var textFieldView: TextFieldView = {
        return TextFieldView(viewModel: viewModel, delegate: self)
    }()
    let configuration: TextFieldElementConfiguration
    private(set) var text: String = ""
    var isEditing: Bool = false
    
    // MARK: - ViewModel

    struct ViewModel {
        struct KeyboardProperties {
            let type: UIKeyboardType
            let autocapitalization: UITextAutocapitalizationType
        }
        
        var placeholder: String
        var text: String
        var attributedText: NSAttributedString
        var keyboardProperties: KeyboardProperties
        var validationState: ElementValidationState
        var isOptional: Bool
    }
    
    var viewModel: ViewModel {
        return ViewModel(
            placeholder: configuration.placeholder,
            text: text,
            attributedText: configuration.makeDisplayText(for: text),
            keyboardProperties: configuration.makeKeyboardProperties(for: text),
            validationState: validationState,
            isOptional: isOptional
        )
    }

    // MARK: - Initializer
    
    required init(
        configuration: TextFieldElementConfiguration
    ) {
        self.configuration = configuration
    }
}

// MARK: - Element

extension TextFieldElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard !view.isHidden else {
            return params
        }
        return configuration.updateParams(for: text, params: params)
    }
    
    var view: UIView {
        return textFieldView
    }
    
    var validationState: ElementValidationState {
        return configuration.validate(text: text, isOptional: isOptional)
    }
}

// MARK: - TextFieldViewDelegate

extension TextFieldElement: TextFieldViewDelegate {
    func didUpdate(view: TextFieldView) {
        // Update our state
        text = String(
            view.text.stp_stringByRemovingCharacters(from: configuration.disallowedCharacters)
            .prefix(configuration.maxLength)
        )
        isEditing = view.isEditing
        
        // Glue: Update the view and our delegate
        view.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }
}
