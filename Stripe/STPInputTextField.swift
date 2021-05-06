//
//  STPInputTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPInputTextField: STPFloatingPlaceholderTextField, STPFormInputValidationObserver {
    let formatter: STPInputTextFieldFormatter

    let validator: STPInputTextFieldValidator

    weak var formContainer: STPFormContainer? = nil

    var wantsAutoFocus: Bool {
        return true
    }

    let accessoryImageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 6
        return stackView
    }()
    let errorStateImageView: UIImageView = {
        let imageView = UIImageView(image: STPImageLibrary.safeImageNamed("form_error_icon"))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        return imageView
    }()

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {
        self.formatter = formatter
        self.validator = validator
        super.init(frame: .zero)
        delegate = formatter
        validator.textField = self
        validator.addObserver(self)
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    override func setupSubviews() {
        super.setupSubviews()
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        font = fontMetrics.scaledFont(for: UIFont.systemFont(ofSize: 14))
        placeholderLabel.font = font
        defaultPlaceholderColor = CompatibleColor.secondaryLabel
        floatingPlaceholderColor = CompatibleColor.secondaryLabel
        rightView = accessoryImageStackView
        rightViewMode = .always
        errorStateImageView.alpha = 0
        accessoryImageStackView.addArrangedSubview(errorStateImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var text: String? {
        didSet {
            textDidChange()
        }
    }

    internal func addAccessoryImageViews(_ accessoryImageViews: [UIImageView]) {
        for imageView in accessoryImageViews {
            accessoryImageStackView.addArrangedSubview(imageView)
        }
    }

    internal func removeAccessoryImageViews(_ accessoryImageViews: [UIImageView]) {
        for imageView in accessoryImageViews {
            accessoryImageStackView.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
        }
    }

    @objc
    func textDidChange() {
        let text = self.text ?? ""
        let formatted = formatter.formattedText(from: text, with: defaultTextAttributes)
        if formatted != attributedText {
            var updatedCursorPosition: UITextPosition? = nil
            if let selection = selectedTextRange {
                let cursorPosition = offset(from: beginningOfDocument, to: selection.start)
                updatedCursorPosition = position(
                    from: beginningOfDocument,
                    offset: cursorPosition - (text.count - formatted.length))

            }
            attributedText = formatted
            sendActions(for: .valueChanged)
            if let updatedCursorPosition = updatedCursorPosition {
                selectedTextRange = textRange(
                    from: updatedCursorPosition, to: updatedCursorPosition)
            }
        }
        validator.inputValue = formatted.string
    }

    @objc
    override public func becomeFirstResponder() -> Bool {
        self.formContainer?.inputTextFieldWillBecomeFirstResponder(self)
        let ret = super.becomeFirstResponder()
        updateTextColor()
        return ret
    }

    @objc
    override public func resignFirstResponder() -> Bool {
        let ret = super.resignFirstResponder()
        if ret {
            self.formContainer?.inputTextFieldDidResignFirstResponder(self)
        }
        updateTextColor()
        return ret
    }

    var isValid: Bool {
        switch validator.validationState {
        case .unknown, .valid, .processing:
            return true
        case .incomplete:
            if isEditing {
                return true
            } else {
                return false
            }
        case .invalid:
            return false
        }
    }

    @objc
    override public var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                updateTextColor()
                defaultPlaceholderColor = CompatibleColor.secondaryLabel
                floatingPlaceholderColor = CompatibleColor.secondaryLabel
            } else {
                textColor = STPInputFormColors.disabledTextColor
                defaultPlaceholderColor = STPInputFormColors.disabledTextColor
                floatingPlaceholderColor = STPInputFormColors.disabledTextColor
            }
        }
    }

    func updateTextColor() {
        switch validator.validationState {

        case .unknown:
            textColor = STPInputFormColors.textColor
            errorStateImageView.alpha = 0
        case .incomplete:
            if isEditing || (validator.inputValue?.isEmpty ?? true) {
                textColor = STPInputFormColors.textColor
                errorStateImageView.alpha = 0
            } else {
                textColor = STPInputFormColors.errorColor
                errorStateImageView.alpha = 1
            }
        case .invalid:
            textColor = STPInputFormColors.errorColor
            errorStateImageView.alpha = 1
        case .valid:
            textColor = STPInputFormColors.textColor
            errorStateImageView.alpha = 0
        case .processing:
            textColor = STPInputFormColors.textColor
            errorStateImageView.alpha = 0
        }
    }

    @objc public override var accessibilityAttributedValue: NSAttributedString? {
        get {
            guard let text = text else {
                return nil
            }
            let attributedString = NSMutableAttributedString(string: text)
            if #available(iOS 13.0, *) {
                attributedString.addAttribute(
                    .accessibilitySpeechSpellOut, value: NSNumber(value: true),
                    range: NSRange(location: 0, length: attributedString.length))
            }
            return attributedString
        }
        set {
            // do nothing
        }
    }

    @objc public override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            guard let accessibilityLabel = accessibilityLabel else {
                return nil
            }
            let attributedString = NSMutableAttributedString(string: accessibilityLabel)
            if !isValid {
                let invalidData = STPLocalizedString(
                    "Invalid data.",
                    "Spoken during VoiceOver when a form field has failed validation.")
                let failedString = NSMutableAttributedString(
                    string: invalidData,
                    attributes: [
                        NSAttributedString.Key.accessibilitySpeechPitch: NSNumber(value: 0.6)
                    ])
                attributedString.append(NSAttributedString(string: " "))
                attributedString.append(failedString)
            }
            return attributedString
        }
        set {
            // do nothing
        }
    }

    @objc
    public override func deleteBackward() {
        let deletingOnEmpty = (text?.count ?? 0) == 0
        super.deleteBackward()
        if deletingOnEmpty {
            formContainer?.inputTextFieldDidBackspaceOnEmpty(self)
        }
    }

    // Fixes a weird issue related to our custom override of deleteBackwards. This only affects the simulator and iPads with custom keyboards.
    // copied from STPFormTextField
    @objc
    public override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(
                input: "\u{08}", modifierFlags: .command, action: #selector(commandDeleteBackwards))
        ]
    }

    @objc
    func commandDeleteBackwards() {
        text = ""
    }

    // MARK: - STPInputTextFieldValidationObserver
    func validationDidUpdate(
        to state: STPValidatedInputState, from previousState: STPValidatedInputState,
        for unformattedInput: String?, in input: STPFormInput
    ) {

        guard input == self,
            unformattedInput == text
        else {
            return
        }
        updateTextColor()
    }
}

/// :nodoc:
extension STPInputTextField: STPFormInput {

    var validationState: STPValidatedInputState {
        return validator.validationState
    }

    var inputValue: String? {
        return validator.inputValue
    }

    func addObserver(_ validationObserver: STPFormInputValidationObserver) {
        validator.addObserver(validationObserver)
    }

    func removeObserver(_ validationObserver: STPFormInputValidationObserver) {
        validator.removeObserver(validationObserver)
    }

}
