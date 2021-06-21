//
//  STPMultiFormTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

/// STPMultiFormFieldDelegate provides methods for a delegate to respond to editing and text changes.
@objc protocol STPMultiFormFieldDelegate: NSObjectProtocol {
    /// Called when the text field becomes the first responder.
    func formTextFieldDidStartEditing(
        _ formTextField: STPFormTextField,
        inMultiForm multiFormField: STPMultiFormTextField
    )
    /// Called when the text field resigns from being the first responder.
    func formTextFieldDidEndEditing(
        _ formTextField: STPFormTextField,
        inMultiForm multiFormField: STPMultiFormTextField
    )
    /// Called when the text within the form text field changes.
    func formTextFieldTextDidChange(
        _ formTextField: STPFormTextField,
        inMultiForm multiFormField: STPMultiFormTextField
    )
    /// Called to get any additional formatting from the delegate for the string input to the form text field.
    func modifiedIncomingTextChange(
        _ input: NSAttributedString,
        for formTextField: STPFormTextField,
        inMultiForm multiFormField: STPMultiFormTextField
    ) -> NSAttributedString
    /// Delegates should implement this method so that STPMultiFormTextField when the contents of the form text field renders it complete.
    func isFormFieldComplete(
        _ formTextField: STPFormTextField,
        inMultiForm multiFormField: STPMultiFormTextField
    ) -> Bool
}

/// STPMultiFormTextField is a lightweight UIView that wraps a collection of STPFormTextFields and can automatically move to the next form field when one is completed.
public class STPMultiFormTextField: UIView, STPFormTextFieldContainer, UITextFieldDelegate,
    STPFormTextFieldDelegate
{
    /// :nodoc:
    @objc
    public func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let textField = textField as? STPFormTextField,
            let delegateProxy = textField.delegateProxy
        {
            return delegateProxy.textField(
                textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        return true
    }

    /// The collection of STPFormTextFields that this instance manages.

    private var _formTextFields: [STPFormTextField]?
    var formTextFields: [STPFormTextField]? {
        get {
            _formTextFields
        }
        set(formTextFields) {
            _formTextFields = formTextFields
            for field in formTextFields ?? [] {
                field.formDelegate = self
            }
        }
    }
    /// The STPMultiFormTextField's delegate.
    @objc weak var multiFormFieldDelegate: STPMultiFormFieldDelegate?

    /// Calling this method will make the next incomplete STPFormTextField in `formTextFields` become the first responder.
    /// If all of the form text fields are already complete, then the last field in `formTextFields` will become the first responder.
    @objc public func focusNextForm() {
        let nextField = _nextFirstResponderField()
        if nextField == _currentFirstResponderField() {
            // If this doesn't actually advance us, resign first responder
            nextField?.resignFirstResponder()
        } else {
            nextField?.becomeFirstResponder()
        }
    }

    // MARK: - UIResponder
    /// :nodoc:
    @objc public override var canResignFirstResponder: Bool {
        if _currentFirstResponderField() != nil {
            return _currentFirstResponderField()?.canResignFirstResponder ?? false
        } else {
            return true
        }
    }

    /// :nodoc:
    @objc
    public override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        if _currentFirstResponderField() != nil {
            return _currentFirstResponderField()?.resignFirstResponder() ?? false
        } else {
            return true
        }
    }

    /// :nodoc:
    @objc public override var isFirstResponder: Bool {
        return super.isFirstResponder || _currentFirstResponderField()?.isFirstResponder ?? false
    }

    /// :nodoc:
    @objc public override var canBecomeFirstResponder: Bool {
        return (formTextFields?.count ?? 0) > 0
    }

    /// :nodoc:
    @objc
    public override func becomeFirstResponder() -> Bool {
        // grab the next first responder before calling super (which will cause any current first responder to resign)
        var firstResponder: STPFormTextField?
        if _currentFirstResponderField() != nil {
            // we are already first responder, move to next field sequentially
            firstResponder = _nextInSequenceFirstResponderField() ?? formTextFields?.first
        } else {
            // Default to the first invalid subfield when becoming first responder
            firstResponder = _firstInvalidSubField()
        }

        super.becomeFirstResponder()
        return firstResponder?.becomeFirstResponder() ?? false
    }

    // MARK: - UITextFieldDelegate
    /// :nodoc:
    @objc
    public func textFieldDidEndEditing(_ textField: UITextField) {
        let formTextField = (textField is STPFormTextField) ? textField as? STPFormTextField : nil
        textField.layoutIfNeeded()

        if let formTextField = formTextField {
            multiFormFieldDelegate?.formTextFieldDidEndEditing(formTextField, inMultiForm: self)
        }
    }

    /// :nodoc:
    @objc
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        let formTextField = (textField is STPFormTextField) ? textField as? STPFormTextField : nil
        if let formTextField = formTextField {
            multiFormFieldDelegate?.formTextFieldDidStartEditing(formTextField, inMultiForm: self)
        }
    }

    /// :nodoc:
    @objc
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextInSequence = _nextInSequenceFirstResponderField()
        if let nextInSequence = nextInSequence {
            nextInSequence.becomeFirstResponder()
            return false
        } else {
            textField.resignFirstResponder()
            return true
        }
    }

    // MARK: - STPFormTextFieldDelegate
    @objc func formTextFieldDidBackspace(onEmpty formTextField: STPFormTextField) {
        let previous = _previousField()
        previous?.becomeFirstResponder()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        if previous?.hasText ?? false {
            previous?.deleteBackward()
        }
    }

    @objc func formTextField(
        _ formTextField: STPFormTextField,
        modifyIncomingTextChange input: NSAttributedString
    ) -> NSAttributedString {
        return
            (multiFormFieldDelegate?.modifiedIncomingTextChange(
                input,
                for: formTextField,
                inMultiForm: self))!
    }

    @objc func formTextFieldTextDidChange(_ formTextField: STPFormTextField) {
        multiFormFieldDelegate?.formTextFieldTextDidChange(
            formTextField,
            inMultiForm: self)
    }

    // MARK: - Helpers
    func _currentFirstResponderField() -> STPFormTextField? {
        for textField in formTextFields ?? [] {
            if textField.isFirstResponder {
                return textField
            }
        }
        return nil
    }

    func _previousField() -> STPFormTextField? {
        let currentSubResponder = _currentFirstResponderField()
        if let currentSubResponder = currentSubResponder {
            let index = formTextFields?.firstIndex(of: currentSubResponder) ?? NSNotFound
            if index != NSNotFound && index > 0 {
                return formTextFields?[index - 1]
            }
        }
        return nil
    }

    func _nextFirstResponderField() -> STPFormTextField? {
        let nextField = _nextInSequenceFirstResponderField()
        if let nextField = nextField {
            return nextField
        } else {
            if _currentFirstResponderField() == nil {
                // if we don't currently have a first responder, consider the first invalid field the next one
                return _firstInvalidSubField()
            } else {
                return _lastSubField()
            }
        }
    }

    func _nextInSequenceFirstResponderField() -> STPFormTextField? {
        let currentFirstResponder = _currentFirstResponderField()
        if let currentFirstResponder = currentFirstResponder {
            let index = formTextFields?.firstIndex(of: currentFirstResponder) ?? NSNotFound
            if index != NSNotFound {
                let nextField =
                    formTextFields!.stp_boundSafeObject(at: index + 1) as? STPFormTextField
                if let nextField = nextField {
                    return nextField
                }
            }
        }

        return nil
    }

    func _firstInvalidSubField() -> STPFormTextField? {
        for textField in formTextFields ?? [] {
            if !(multiFormFieldDelegate?.isFormFieldComplete(textField, inMultiForm: self) ?? false)
            {
                return textField
            }
        }
        return nil
    }

    func _lastSubField() -> STPFormTextField {
        return (formTextFields?.last)!
    }

    // MARK: - STPFormTextFieldContainer
    @objc public var formFont: UIFont = UIFont.preferredFont(forTextStyle: .body) {
        didSet {
            if formFont != oldValue {
                for textField in formTextFields ?? [] {
                    textField.font = formFont
                }
            }
        }
    }

    @objc public var formTextColor: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            // Fallback on earlier versions
            return UIColor.darkText
        }
    }()
    {
        didSet {
            if oldValue != formTextColor {
                for textField in formTextFields ?? [] {
                    textField.defaultColor = formTextColor
                }
            }
        }
    }

    @objc public var formTextErrorColor: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.systemRed
        } else {
            // Fallback on earlier versions
            return UIColor.red
        }
    }()
    {
        didSet {
            if oldValue != formTextErrorColor {
                for textField in formTextFields ?? [] {
                    textField.errorColor = formTextErrorColor
                }
            }
        }
    }

    @objc public var formPlaceholderColor: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.placeholderText
        } else {
            // Fallback on earlier versions
            return UIColor.lightGray
        }
    }()
    {
        didSet {
            if oldValue != formPlaceholderColor {
                for textField in formTextFields ?? [] {
                    textField.placeholderColor = formPlaceholderColor
                }
            }
        }
    }

    @objc public var formCursorColor: UIColor {
        get {
            self.tintColor
        }
        set {
            if newValue != tintColor {
                tintColor = newValue
                for textField in formTextFields ?? [] {
                    textField.tintColor = tintColor
                }
            }
        }
    }

    @objc public var formKeyboardAppearance: UIKeyboardAppearance = .default {
        didSet {
            if oldValue != formKeyboardAppearance {
                for textField in formTextFields ?? [] {
                    textField.keyboardAppearance = formKeyboardAppearance
                }
            }
        }
    }
}
