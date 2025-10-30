//
//  TextFieldElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/**
 A generic text field whose logic is extracted into `TextFieldElementConfiguration`.
 
 - Seealso: `TextFieldElementConfiguration`
 */
@_spi(STP) public final class TextFieldElement {

    // MARK: - Properties
    weak public var delegate: ElementDelegate?
    lazy var textFieldView: TextFieldView = {
        return TextFieldView(viewModel: viewModel, delegate: self)
    }()
    var configuration: TextFieldElementConfiguration {
        didSet {
            setText("")
        }
    }
    public private(set) lazy var text: String = {
        sanitize(text: configuration.defaultValue ?? "")
    }()
    public private(set) var isEditing: Bool = false {
        didSet {
            delegate?.didUpdate(element: self)
        }
    }
    private(set) var didReceiveAutofill: Bool = false
    /// When true, indicates the user tapped confirm button requesting validation feedback
    var displayEmptyFields: Bool = false
    public var validationState: ElementValidationState {
        return .init(
            from: configuration.validate(text: text, isOptional: configuration.isOptional),
            isUserEditing: isEditing,
            displayEmptyFields: displayEmptyFields
        )
    }

    private let theme: ElementsAppearance

#if !os(visionOS)
    public var inputAccessoryView: UIView? {
        get {
            return textFieldView.textField.inputAccessoryView
        }

        set {
            textFieldView.textField.inputAccessoryView = newValue
        }
    }
#endif

    // MARK: - ViewModel
    public struct KeyboardProperties {
        public init(type: UIKeyboardType, textContentType: UITextContentType?, autocapitalization: UITextAutocapitalizationType) {
            self.type = type
            self.textContentType = textContentType
            self.autocapitalization = autocapitalization
        }

        let type: UIKeyboardType
        let textContentType: UITextContentType?
        let autocapitalization: UITextAutocapitalizationType
    }

    struct ViewModel {
        let placeholder: String
        let accessibilityLabel: String
        let attributedText: NSAttributedString
        let keyboardProperties: KeyboardProperties
        let validationState: ValidationState
        let accessoryView: UIView?
        let shouldShowClearButton: Bool
        let editConfiguration: EditConfiguration
        let theme: ElementsAppearance
        let displayEmptyFields: Bool
    }

    var viewModel: ViewModel {
        let placeholder: String = {
            if !configuration.isOptional {
                return configuration.label
            } else {
                let localized = String.Localized.optional_field
                return String(format: localized, configuration.label)
            }
        }()
        return ViewModel(
            placeholder: placeholder,
            accessibilityLabel: configuration.accessibilityLabel,
            attributedText: configuration.makeDisplayText(for: text),
            keyboardProperties: configuration.keyboardProperties(for: text),
            validationState: configuration.validate(text: text, isOptional: configuration.isOptional),
            accessoryView: configuration.accessoryView(for: text, theme: theme),
            shouldShowClearButton: configuration.shouldShowClearButton,
            editConfiguration: configuration.editConfiguration,
            theme: theme,
            displayEmptyFields: displayEmptyFields
        )
    }

    // MARK: - Initializer

    public required init(configuration: TextFieldElementConfiguration, theme: ElementsAppearance = .default) {
        self.configuration = configuration
        self.theme = theme
    }

    /// Call this to manually set the text of the text field.
    public func setText(_ text: String) {
        self.text = sanitize(text: text)

        // Since we're setting the text manually, disable any previous autofill
        didReceiveAutofill = false

        // Glue: Update the view and our delegate
        textFieldView.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }

    // MARK: - Helpers

    func sanitize(text: String) -> String {
        let sanitizedText = text
            .stp_stringByRemovingCharacters(from: configuration.disallowedCharacters)
            .stp_stringByRemovingEmoji()
        return String(sanitizedText.prefix(configuration.maxLength(for: sanitizedText)))
    }
}

// MARK: - Element

extension TextFieldElement: Element {
    public var collectsUserInput: Bool { true }
    public var view: UIView {
        return textFieldView
    }

    @discardableResult
    public func beginEditing() -> Bool {
        return textFieldView.textField.becomeFirstResponder()
    }

    /// Forces validation errors to be displayed, even if the user is currently editing
    public func showValidationErrors() {
        displayEmptyFields = true
        textFieldView.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }

    @discardableResult
    public func endEditing(_ force: Bool = false, continueToNextField: Bool = true) -> Bool {
        let didResign = textFieldView.endEditing(force)
        isEditing = textFieldView.isEditing
        if continueToNextField {
            delegate?.continueToNextField(element: self)
        }
        return didResign
    }

    public var subLabelText: String? {
        return configuration.subLabel(text: text)
    }
}

// MARK: - TextFieldViewDelegate

extension TextFieldElement: TextFieldViewDelegate {
    func textFieldViewDidUpdate(view: TextFieldView) {
        // Update our state
        let newText = sanitize(text: view.text)
        if text != newText {
            text = newText
            // Advance to the next field if text is maximum length and valid
            if text.count == configuration.maxLength(for: text), case .valid = validationState {
                delegate?.continueToNextField(element: self)
                view.resignFirstResponder()
            }
        }
        isEditing = view.isEditing
        didReceiveAutofill = view.didReceiveAutofill

        // Glue: Update the view and our delegate
        view.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }

    func textFieldViewContinueToNextField(view: TextFieldView) {
        isEditing = view.isEditing
        delegate?.continueToNextField(element: self)
    }
}

// MARK: - DebugDescription
extension TextFieldElement {
    public var debugDescription: String {
        return "<TextFieldElement: \(Unmanaged.passUnretained(self).toOpaque())>; label = \(configuration.label); text = \(text); validationState = \(validationState)"
    }
}
